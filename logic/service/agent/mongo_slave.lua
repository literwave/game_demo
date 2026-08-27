local skynet = require "skynet"

localEnvDoFile("../logic/service/agent/save_col.lua")

cmdCnt = 0
flushCB = nil
maxCmdCnt = 500
local flushCd = 5

allCmdTbl = {}

local function flushCmds(colCmdMap)
	if next(colCmdMap) then
		skynet.send(".mongodb", "lua", "saveData", colCmdMap)
	end
end

function flush()
	flushCmds(allCmdTbl)
	allCmdTbl = {}
	cmdCnt = 0
end

local function pushCmd(col, cmd)
	if not allCmdTbl[col] then
		allCmdTbl[col] = {}
	end
	table.insert(allCmdTbl[col], cmd)
	cmdCnt = cmdCnt + 1
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

-- 整包覆盖 dat（map 的 number key 由 ORM.dump 转成字符串）
function saveDoc(col, key, dumped)
	assert(col)
	assert(key)
	assert(type(dumped) == "table")
	pushCmd(col, {
		key = key,
		opType = "$set",
		fieldStr = "dat",
		value = dumped,
	})
end

-- 子树字段更新：field 必须是非纯数字的 string 字段名
function saveDocField(col, key, field, value)
	assert(col)
	assert(key)
	assert(type(field) == "string", "saveDocField field must be string")
	assert(not tonumber(field), "saveDocField field must not be numeric string")
	pushCmd(col, {
		key = key,
		opType = "$set",
		fieldStr = "dat." .. field,
		value = value,
	})
end

function delDoc(col, key)
	assert(col)
	assert(key)
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
	initAgentMongo()
end

function loadSingleUserInfo(userId)
	return commonLoadSingle(USER_INFO_COL, userId)
end

function loadSingleUserHero(userId)
	return commonLoadSingle(USER_HERO_COL, userId)
end

function loadSingleUserBuild(userId)
	return commonLoadSingle(USER_BUILD_COL, userId)
end

function loadSingleUserItem(userId)
	return commonLoadSingle(USER_ITEM_COL, userId)
end
