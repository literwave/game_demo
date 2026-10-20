local skynet = require "skynet"
local orm = require "orm"

COL = {
	USER_INFO = "userInfoCol",
	USER_HERO = "userHeroCol",
	USER_BUILD = "userBuildCol",
	USER_ITEM = "userItemCol",
	QUEUE = "queueCol",
	GAME_SID = "gameSidCol",
	MAIL = "mailCol",
	USER_MAIL = "userMailCol",
	SVR_MAIL = "svrMailCol",
}

local flushCB = nil
local flushCd = 5
local allCmdTbl = {}
local flushScheduled = false
local flushing = false

local function enqueue(col, cmd)
	if not allCmdTbl[col] then
		allCmdTbl[col] = {}
	end
	table.insert(allCmdTbl[col], cmd)
end

local function scheduleFlush()
	if flushScheduled or flushing then
		return
	end
	flushScheduled = true
	skynet.timeout(0, function()
		flushScheduled = false
		flush()
	end)
end

orm.on_dirty = scheduleFlush

function flush()
	if flushing then
		return
	end
	flushing = true
	local dirty = orm.drain_dirty()
	for _, item in ipairs(dirty) do
		enqueue(item.col, {
			key = item.key,
			opType = "$set",
			fieldStr = "dat",
			value = orm.dump(item.obj),
		})
	end
	local sending = allCmdTbl
	allCmdTbl = {}
	flushing = false
	if next(sending) then
		skynet.send(".mongodb", "lua", "saveData", sending)
	end
	if orm.has_dirty() then
		scheduleFlush()
	end
end

local function pushCmd(col, cmd)
	enqueue(col, cmd)
	scheduleFlush()
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

function commonSaveMany(col, tbl)
	for key, dat in pairs(tbl) do
		if type(dat) == "table" then
			saveDoc(col, key, dat)
		end
	end
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
end
