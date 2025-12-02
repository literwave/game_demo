local skynet = require "skynet"

localEnvDoFile("../logic/service/logind/save_col.lua")

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
	-- if cmdCnt >= maxCmdCnt or isMass then
	-- 	flush()
	-- end
	if true then
		flush()
	end
end

function saveMassData(col, tbl)
	LMDB.updateDocByTbl(col, tbl)
end

function flush()
	if next(allCmdTbl) then
		skynet.send(".mongodb", "lua", "saveData", allCmdTbl)
	end
end

function systemStartUp()
	if not flushCB then
		flushCB = CALL_OUT.callFre("MONGO_SLAVE", "flush", flushCd)
	end
	initLogindMongo()
end

function commonLoadSingle(col, key)
	assert(key)
end

function commonLoadSingle(col, key)
	assert(key)
	local ret = LMDB.commonLoadSingle(col, key)
	if ret and ret.dat then
		return ret.dat
	else
		return nil
	end
end

function commonLoadTbl(col)
	return LMDB.commonLoadTbl(col)
end

function loadAllAccountInfo()
	return commonLoadTbl(ACCOUNT_INFO_COL)
end

function saveAccountInfo(col, tbl)
	saveMassData(col, tbl)
end