local skynet = require "skynet"
local orm = require "orm"

COL = {
	USER_INFO = "user_info_col",
	USER_HERO = "user_hero_col",
	USER_BUILD = "user_build_col",
	USER_ITEM = "user_item_col",
	QUEUE = "queue_col",
	USER_TROOP = "user_troop_col",
	GAME_SID = "game_sid_col",
	MAIL = "mail_col",
	USER_MAIL = "user_mail_col",
	SVR_MAIL = "svr_mail_col",
}

local flush_cb = nil
local flush_cd = 5
local all_cmd_tbl = {}
local flush_scheduled = false
local flushing = false

local function enqueue(col, cmd)
	if not all_cmd_tbl[col] then
		all_cmd_tbl[col] = {}
	end
	table.insert(all_cmd_tbl[col], cmd)
end

local function schedule_flush()
	if flush_scheduled or flushing then
		return
	end
	flush_scheduled = true
	skynet.timeout(0, function()
		flush_scheduled = false
		flush()
	end)
end

orm.on_dirty = schedule_flush

function flush()
	if flushing then
		return
	end
	flushing = true
	local dirty = orm.drain_dirty()
	for _, item in ipairs(dirty) do
		enqueue(item.col, {
			key = item.key,
			op_type = "$set",
			field_str = "dat",
			value = orm.dump(item.obj),
		})
	end
	local sending = all_cmd_tbl
	all_cmd_tbl = {}
	flushing = false
	if next(sending) then
		skynet.send(".mongodb", "lua", "save_data", sending)
	end
	if orm.has_dirty() then
		schedule_flush()
	end
end

local function push_cmd(col, cmd)
	enqueue(col, cmd)
	schedule_flush()
end

function common_load_single(col, key)
	assert(key)
	local ret = skynet.call(".mongodb", "lua", "find_one", {
		database = GAME.get_data_base(),
		collection = col,
		query = {_id = key},
		selector = {dat = 1},
	})
	if ret and ret.dat then
		return ret.dat
	end
	return nil
end

function common_load_tbl(col)
	local list = skynet.call(".mongodb", "lua", "find_all", {
		database = GAME.get_data_base(),
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

function common_load_many(col, key_list)
	local ret = {}
	for _, key in pairs(key_list) do
		local dat = common_load_single(col, key)
		if dat then
			ret[key] = dat
		end
	end
	return ret
end

-- 整包覆盖 dat（map 的 number key 由 ORM.dump 转成字符串）
function save_doc(col, key, dumped)
	assert(col)
	assert(key)
	assert(type(dumped) == "table")
	push_cmd(col, {
		key = key,
		op_type = "$set",
		field_str = "dat",
		value = dumped,
	})
end

-- 子树字段更新：field 必须是非纯数字的 string 字段名
function save_doc_field(col, key, field, value)
	assert(col)
	assert(key)
	assert(type(field) == "string", "saveDocField field must be string")
	assert(not tonumber(field), "saveDocField field must not be numeric string")
	push_cmd(col, {
		key = key,
		op_type = "$set",
		field_str = "dat." .. field,
		value = value,
	})
end

function del_doc(col, key)
	assert(col)
	assert(key)
	push_cmd(col, {
		key = key,
		op_type = "del_doc",
		field_str = nil,
		value = "",
	})
end

function common_save_many(col, tbl)
	for key, dat in pairs(tbl) do
		if type(dat) == "table" then
			save_doc(col, key, dat)
		end
	end
end

function common_del_many(col, key_tbl)
	for key in pairs(key_tbl) do
		del_doc(col, key)
	end
end

function system_startup()
	if not flush_cb then
		flush_cb = CALL_OUT.call_fre("MONGO_SLAVE", "flush", flush_cd)
	end
end
