local orm = require "orm"
local typedef = require "orm.typedef"

local SCHEMA_DIR = "orm/schema"

local function load_all_schemas()
	local type_list = {}
	local p = io.popen("ls " .. SCHEMA_DIR)
	for file in p:lines() do
		if file:match("%.td$") then
			for _, item in ipairs(typedef.parse(file, SCHEMA_DIR)) do
				type_list[#type_list + 1] = item
			end
		end
	end
	p:close()
	orm.init(type_list)
end

load_all_schemas()
orm.drain()

local COL = "unit_user"
local key_seq = 0

local function new_user(data)
	key_seq = key_seq + 1
	local obj = orm.new("user_data", data or {_user_id = key_seq})
	orm.bind(obj, COL, key_seq)
	return obj, key_seq
end

local function find(list, key)
	for _, v in ipairs(list) do
		if v.key == key then
			return v
		end
	end
end

local T = {}

function T.all_schemas_parse()
	load_all_schemas()
	orm.drain()
end

function T.default_values()
	local u = orm.new("user_data", {})
	assert(u._name == "")
	assert(u._level == 0)
	assert(u._res_tbl ~= nil, "map field should be created")
end

function T.change_marks_dirty_once()
	local u, key = new_user()
	orm.drain()
	u._name = "a"
	u._level = 3
	local list = orm.drain()
	assert(#list == 1, "same doc changed twice should appear once")
	assert(list[1].col == COL and list[1].key == key)
	assert(list[1].dat._name == "a" and list[1].dat._level == 3)
	assert(#orm.drain() == 0)
end

function T.same_value_not_dirty()
	local u = new_user({_name = "x"})
	orm.drain()
	u._name = "x"
	assert(#orm.drain() == 0)
end

function T.nested_change_marks_root()
	local u, key = new_user()
	orm.drain()
	u._res_tbl[1] = 10
	local doc = find(orm.drain(), key)
	assert(doc, "root should be dirty after nested change")
	assert(doc.dat._res_tbl["1"] == 10, "number map key should dump as string")
end

function T.string_key_loads_as_number()
	local u = orm.new("user_data", {_res_tbl = {["1001"] = 5}})
	assert(u._res_tbl[1001] == 5)
end

function T.wrong_type_rejected()
	local u = orm.new("user_data", {})
	assert(not pcall(function() u._level = "abc" end))
	assert(not pcall(function() u._no_such_field = 1 end))
end

function T.unbound_change_not_dirty()
	orm.drain()
	local u = orm.new("user_data", {})
	u._name = "free"
	assert(#orm.drain() == 0)
end

function T.unbind()
	local _, key = new_user()
	assert(orm.get(COL, key))
	orm.unbind(COL, key)
	assert(orm.get(COL, key) == nil)
end

function T.new_returns_same_object()
	local u = orm.new("user_data", {})
	assert(orm.new("user_data", u) == u)
end

function T.removing_child_by_nil()
	local u, key = new_user()
	u._res_tbl[2] = 1
	orm.drain()
	u._res_tbl[2] = nil
	local doc = find(orm.drain(), key)
	assert(doc and doc.dat._res_tbl["2"] == nil)
end

function T.report_nested_roundtrip()
	local doc = orm.new("user_report_doc", {})
	orm.bind(doc, "unit_report", 1)
	orm.drain()
	doc._reports[1] = {
		_report_id = 1,
		_is_read = false,
		_atk_side = {_name = "a", _units = {{_pos = 1, _before_count = 100, _after_count = 80, _after_hurt = 20}}},
		_actions = {{_round = 1, _effects = {{_target_side = 2, _value = 40}}}},
	}
	local dumped = find(orm.drain(), 1).dat
	local back = orm.new("user_report_doc", dumped)
	local r = back._reports[1]
	assert(r._atk_side._units[1]._after_count == 80 and r._atk_side._units[1]._after_hurt == 20)
	assert(r._actions[1]._effects[1]._value == 40)
	assert(r._def_side._name == "", "missing struct field gets default")
	assert(r._is_read == false)
end

return T
