local skynet = require "skynet"

localEnvDoFile("../logic/service/agent/save_col.lua")

cmdCnt = 0
flushCB = nil
maxCmdCnt = 500
local flushCd = 5


allCmdTbl = {
	--[[
	[col] = {
		[1] = {
			key = *,
			opType = *,
			fieldStr = *,
			value = *,
		},
	},
	--]]
}
cacheList = {
	--[[
	[1] = allCmdTbl,
	[2] = allCmdTbl,
	--]]
}

-- allCmdTbl设计思路，col刚好是枚举的idx，这样相同集合就能插入进数组
-- 这样设计是为了防止如果出现操作统一集合，可能设置nil or value的时候，保证最后更新的肯定是数据的最后形式

local function insertClearColCmd(colCmdList, value)
	if type(value) ~= "table" then
		assert(false)
		return
	end
	if (next(value)) then
		assert(false)
		return
	end
	table.insert(colCmdList, {})
end

function opMongoValue(flist, value, isMass)
	local col = flist[1]
	assert(col)
	local colCmdList = allCmdTbl[col]
	if not allCmdTbl[col] then
		allCmdTbl[col] = {} 
	end
	colCmdList = allCmdTbl[col]
	local key = flist[2]
	if not key then
		-- 这里如果是空table的，为什么不直接返回了，而是table.insert{}
		insertClearColCmd(colCmdList, value)
		return
	end

	local mongoFList = {"dat", }
	local len = #flist
	if (len >= 3) then
		for idx = 3, len do
			local field = flist[idx]
			if type(field) == "number" then
				table.insert(mongoFList, string.format("@%s", field))
			else
				table.insert(mongoFList, field)
			end
		end
	end

	if (value == nil) then
		if #mongoFList <= 1 then
			local cmd = {
				key = key,
				opType = "delDoc",
				fieldStr = nil,
				value = "",
			}
			table.insert(colCmdList, cmd)
		else
			local cmd = {
				key = key,
				opType = "$unset",
				fieldStr = table.concat(mongoFList, "."),
				value = "",
			}
			table.insert(colCmdList, cmd)
		end
	else
		local cmd = {
			key = key,
			opType = "$set",
			fieldStr = table.concat(mongoFList, "."),
			value = value,
		}
		table.insert(colCmdList, cmd)
	end
	cmdCnt = cmdCnt + 1
	if isMass then
		flush()
	end
end

function saveMassData()
	skynet.send(".mongodb", "lua", "save", allCmdTbl)
end

function flush()
	if next(allCmdTbl) or next(cacheList) then
		table.insert(cacheList, allCmdTbl)
		local saveList = cacheList
		cmdCnt = 0
		allCmdTbl = {}
		cacheList = {}
		skynet.send(".mongodb", "lua", "saveAgentData", saveList)
	end
end

function systemStartup()
	if not flushCB then
		flushCB = CALL_OUT.callFre("MONGO_SL", "flush", flushCd)
	end
end

function loadSingleUserInfo(userId)
	local ret = skynet.call(".mongodb", "lua", "findOne", {
		database = GAME.getDataBase(),
		collection = "userCol",
		doc = {_id = userId}
	})
	return ret
end

function update(info)
	local col = "userCol"
	local key = info._userId
	local opType = "$set"
	local fieldStr = nil
	local value = info
	opMongoValue({col, key, opType, fieldStr}, value)
end