local skynet = require "skynet"

localEnvDoFile("../logic/service/mail/save_col.lua")

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

function commonLoadTbl(col)
	local list = skynet.call(".mongodb", "lua", "findAll", {
		database = GAME.getDataBase(),
		collection = col,
	}) or {}
	local tbl = {}
	for _, doc in ipairs(list) do
		if doc and doc._id ~= nil and doc.dat ~= nil then
			tbl[doc._id] = doc.dat
		end
	end
	return tbl
end

function commonLoadMany(col, keyList)
	local ret = {}
	for _, key in pairs(keyList) do
		local dat = commonLoadSingle(col, key)
		if dat then
			ret[key] = dat
		end
	end
	return ret
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
	assert(not tonumber(field), "saveDocField field must not be numeric string")
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

function commonSaveTbl(col, tbl)
	for key, dat in pairs(tbl) do
		if type(dat) == "table" then
			saveDoc(col, key, dat)
		end
	end
end

function commonSaveMany(col, tbl)
	commonSaveTbl(col, tbl)
end

function commonDelMany(col, keyTbl)
	for key in pairs(keyTbl) do
		delDoc(col, key)
	end
end

function systemStartup()
	if not flushCB then
		flushCB = CALL_OUT.callFre("MONGO_SLAVE", "flush", flushCd)
	end
	initMailMongo()
end
