#!/usr/bin/env python
# -*- encoding:utf8 -*-

from genericpath import exists
import sys, os, re
from tracemalloc import start
import slpp
import json

START_PTO_BASE_ID = 256
MAX_PTO_ID = 65535
ID_TO_NAME = {}

PREFIX = "table = "
def _NewLine(count):
    return '\n' + '    ' * count

def _ToLua(out, obj, indent=1):
    if isinstance(obj, int) or isinstance(obj, float):
       out.append(json.dumps(obj, ensure_ascii = False))
    elif(isinstance(obj, str)):
        if obj.find(PREFIX) == 0:
            out.append(obj[len(PREFIX):])
        else:
            out.append(json.dumps(obj, ensure_ascii = False))
    else:
        isList = isinstance(obj, list)
        out.append('{')
        isFirst = True
        for i in obj:
            if isFirst:
                isFirst = False
            else:
                out.append(',')
            out.append(_NewLine(indent))
            if not isList:
                # obj[i] 
                k = i
                i = obj[k]
                # out.append('[')
                if isinstance(k, int) or isinstance(k, float):
                    out.append(str(k))
                else:
                #     out.append('"')
                    out.append(str(k))
                #     out.append('"')
                # out.append(']')
                out.append(' = ')
            _ToLua(out, i, indent + 1)
        out.append(_NewLine(indent - 1))
        out.append('}')

def execute_lua_str():
    return '''\
\nID_TO_PACK_NAME = {}
PTONAME_TO_ID = {}
ID_TO_PTONAME = {} -- 这里需要优化，其实就只有客户端发给后端才需要这个数据
for_maker = {}
for_caller = {}
	
local function initPto()
	for mod, packTbl in pairs(define) do
		for ptoName, id in pairs(packTbl) do
			local packName = mod .. "." .. ptoName
			ID_TO_PACK_NAME[id] = packName
			PTONAME_TO_ID[ptoName] = id
		end
	end
end

initPto()
'''

class parseFile():

	def __init__(self, dir):
		self._idToMod = {}
		self._nameToId = {}
		self._dumpNameId = {}
		self._dir = dir
		self._startId = START_PTO_BASE_ID
		self._reWrite = False
		self._reMessage = re.compile("message\s\w+")
		self._rePack = re.compile("(package)(\s\w+)")
		self._namePreFix = {"c2s", "s2c"}
		self.startParse()
		self.dumpFile()
		
	def isPtoFile(self, fileName):
		filetype = fileName[-6:]
		return (filetype == ".proto")
	
	def startParse(self):
		# 这里用json做中间逻辑其实是为了方法好调用
		# 需要支持全部重新导出
		if exists("netPb.json"):
			with open("netPb.json", "r+", encoding = "utf8") as f:
				ptoBuf = f.read()
				pto = json.loads(ptoBuf)
				difine = pto.get("define")
				if difine:
					for k, v in difine.items():
						for kk, vv in v.items():
							self._nameToId[kk] = vv
							self._startId = max(int(vv), self._startId)
							self._idToMod[vv] = k
		print(os.listdir(self._dir))
		for fileName in os.listdir(self._dir):
			if self.isPtoFile(fileName):
				with open(self._dir + fileName, encoding = "utf8") as f:
					ptoBuf = f.read()
					modName = self._rePack.findall(ptoBuf)
					ptoModName = modName[0][1].strip()
					ptoNameList = self._reMessage.findall(ptoBuf)
					print(ptoNameList)
					for ptotoName in ptoNameList:
						ptoName = ptotoName.replace("message", "").strip()
						if not ptoName[0:3] in self._namePreFix:
							print(f"error,ptoName: {ptoName}")
							raise ValueError
						
						# 看是否在旧的协议中
						if ptoName in self._nameToId:
							continue
						
						self._startId
						if self._startId >= MAX_PTO_ID:
							print(f"error, _startId: {self._startId}, please extend")
						print(self._startId, ptoModName, ptoName)
						self._nameToId.update({ptoName: self._startId})
						self._idToMod.update({self._startId: ptoModName})
						self._startId += 1
						self._reWrite = True
	def dumpFile(self):
		# 构建 define 字典，即使没有新协议也要生成文件
		define = self._dumpNameId.get("define")
		if not define:
			define = self._dumpNameId["define"] = {}
		for ptotoName, ptoId in self._nameToId.items():
			ptoModName = self._idToMod[ptoId]
			if not define.get(ptoModName):
				define[ptoModName] = {}
			define[ptoModName][ptotoName] = ptoId
		
		# 如果有新协议，更新 JSON 文件
		if self._reWrite:
			print(self._dumpNameId)
			tem = json.dumps(self._dumpNameId, indent=True)
			# wirte json
			with open("netPb.json", "w", encoding = "utf8") as f:
				f.write(tem)
		
		# 总是生成 lua 文件（即使没有新协议）
		luaDataTbl = []
		_ToLua(luaDataTbl, define)
		luaStr = "local define = "
		luaStr = luaStr + "".join(luaDataTbl) + execute_lua_str()
		with open("netPb.lua", "w", encoding = "utf8") as f:
			f.write(luaStr)

if __name__ == "__main__":
	dir = "./" if len(sys.argv)<=1  else sys.argv[1]
	parseFile = parseFile(dir)