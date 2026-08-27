local skynet = require "skynet"

localEnvDoFile("../logic/service/gameserver/save_col.lua")

flushCB = nil
local flushCd = 5
allCmdTbl = {}

function flush()
	if next(allCmdTbl) then
		skynet.send(".mongodb", "lua", "saveData", allCmdTbl)
	end
	allCmdTbl = {}
end

local function pushCmd(col, cmd)
	if not allCmdTbl[col] then
		allCmdTbl[col] = {}
	end
	table.insert(allCmdTbl[col], cmd)
	flush()
end

function commonLoadSingle(col, key)
	assert(key)
	local ret = skynet.call(".mongodb", "lua", "findOne", {
		database = GAME.getDataBase(),
		collection = col,
		query = {_id = key},
		selector = {dat = 1},
	})
	if ret and ret.dat then
		return ret.dat
	end
	return nil
end

function saveDoc(col, key, dumped)
	assert(col and key and type(dumped) == "table")
	pushCmd(col, {
		key = key,
		opType = "$set",
		fieldStr = "dat",
		value = dumped,
	})
end

function saveDocField(col, key, field, value)
	assert(type(field) == "string")
	assert(not tonumber(field))
	pushCmd(col, {
		key = key,
		opType = "$set",
		fieldStr = "dat." .. field,
		value = value,
	})
end

function delDoc(col, key)
	pushCmd(col, {
		key = key,
		opType = "delDoc",
		fieldStr = nil,
		value = "",
	})
end

function systemStartup()
	if not flushCB then
		flushCB = CALL_OUT.callFre("MONGO_SLAVE", "flush", flushCd)
	end
	initGameserverMongo()
end
