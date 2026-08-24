-- lua-orm core (trimmed): schema object + dump for mongo
-- no __oldindex patch required (skynet stock lua)

local M = {}

M.KEYWORD_MAP = {
	boolean = true,
	number = true,
	string = true,
	struct = true,
	list = true,
	map = true,
}

M.CONTAINER_DATA_TYPES = {
	struct = true,
	list = true,
	map = true,
}

M.KEY_ATTRS = {
	["__cls"] = true,
}

M.cls_ref_map = {}
local cls_map = {}

function M.check_ref(node_id, parent_id)
	if parent_id == nil then
		return
	end
	if parent_id == node_id then
		error(string.format("type<%s> ref recursion define", node_id))
	end

	local p_map = M.cls_ref_map[node_id]
	if not p_map then
		p_map = {}
		M.cls_ref_map[node_id] = p_map
	end
	p_map[parent_id] = true

	local pp_map = M.cls_ref_map[parent_id]
	if not pp_map then
		pp_map = {}
		M.cls_ref_map[parent_id] = pp_map
	end
	for pp_id, _ in pairs(pp_map) do
		M.check_ref(node_id, pp_id)
	end
end

function M.get_default(cls)
	local cls_type = cls.type
	if not cls.is_atom then
		error(string.format("cls<%s> type<%s> no default", cls.name, cls_type))
	end
	if cls_type == "boolean" then
		return cls.default or false
	elseif cls_type == "number" then
		return cls.default or 0
	elseif cls_type == "string" then
		return cls.default or ""
	end
end

local function _cls_parse_error(cls, data, msg)
	error(string.format("cls<%s> data<%s> %s", cls.name, tostring(data), msg))
end

function M.parse_boolean(cls, s)
	return s == true
end

function M.parse_string(cls, s)
	return tostring(s)
end

function M.parse_number(cls, s)
	local value = tonumber(s)
	if value == nil then
		_cls_parse_error(cls, s, "is not number")
	end
	return value
end

function M.parse_struct(cls, data)
	if data == nil then
		return cls:new()
	end
	if type(data) ~= "table" then
		_cls_parse_error(cls, data, "is not table")
	end
	local ret = {}
	for attr_name, attr_cls in pairs(cls.attrs) do
		local attr_data = data[attr_name]
		if not (attr_data == nil and attr_cls.is_atom) then
			ret[attr_name] = attr_cls:parse(attr_data)
		end
	end
	return cls:new(ret)
end

function M.parse_list(cls, data)
	if data == nil then
		return cls:new()
	end
	if type(data) ~= "table" then
		_cls_parse_error(cls, data, "is not table")
	end
	local ret = {}
	local item_cls = cls.item
	for _, _data in ipairs(data) do
		table.insert(ret, item_cls:parse(_data))
	end
	return cls:new(ret)
end

function M.parse_map(cls, data)
	if data == nil then
		return cls:new()
	end
	if type(data) ~= "table" then
		_cls_parse_error(cls, data, "is not table")
	end
	local k_cls = cls.key
	local v_cls = cls.value
	local ret = {}
	for k_data, v_data in pairs(data) do
		ret[k_cls:parse(k_data)] = v_cls:parse(v_data)
	end
	return cls:new(ret)
end

local data_parsers = {
	boolean = M.parse_boolean,
	number = M.parse_number,
	string = M.parse_string,
	struct = M.parse_struct,
	list = M.parse_list,
	map = M.parse_map,
}

function M.load_cls_define(cls, parent_name)
	assert(cls, "no cls define")
	if parent_name ~= nil then
		cls.name = parent_name .. "." .. cls.name
	end
	local cls_name = cls.name

	if M.KEYWORD_MAP[cls_name] then
		error(string.format("cls name<%s> is keyword", cls_name))
	end

	local data_type = cls.type
	if not data_type then
		error(string.format("init cls<%s> no data type", cls_name))
	end

	if not M.KEYWORD_MAP[data_type] then
		local ref_cls = cls_map[data_type]
		if ref_cls == nil then
			error(string.format("init cls<%s|%s>, ref illegal ", cls.name, data_type))
		end
		M.check_ref(ref_cls.name, parent_name)
		for k, v in pairs(ref_cls) do
			cls[k] = v
		end
		if not ref_cls.id then
			cls.id = ref_cls
		end
		cls.name = cls_name
		return cls
	end

	cls.id = cls
	local parser = data_parsers[data_type]
	if not parser then
		error(string.format("data type<%s> no parser", data_type))
	end
	cls.parse = parser
	M.check_ref(cls_name, parent_name)
	cls_map[cls_name] = cls
	cls.is_atom = (M.CONTAINER_DATA_TYPES[data_type] == nil)
	if cls.is_atom then
		return cls
	end

	if data_type == "struct" then
		cls.new = M.create_struct
		local mt_index = {__cls = cls}
		cls.mt = {
			__index = mt_index,
			__newindex = M.struct_setfield,
		}
		assert(cls.attrs, "not attrs")
		local attrs = {}
		for k, v in pairs(cls.attrs) do
			if M.KEY_ATTRS[k] then
				error(string.format("class<%s> define key attr<%s>", cls_name, k))
			end
			v.name = k
			local v_cls = M.load_cls_define(v, cls_name)
			if v_cls.is_atom then
				mt_index[k] = M.get_default(v_cls)
			end
			attrs[k] = v_cls
		end
		cls.attrs = attrs
		return cls
	end

	if data_type == "list" then
		cls.new = M.create_list
		cls.mt = {
			__index = {__cls = cls},
			__newindex = M.list_setfield,
		}
		cls.item.name = "item"
		cls.item = M.load_cls_define(cls.item, cls_name)
		return cls
	end

	if data_type == "map" then
		cls.new = M.create_map
		cls.mt = {
			__index = {__cls = cls},
			__newindex = M.map_setfield,
		}
		cls.key.name = "key"
		cls.key = M.load_cls_define(cls.key, cls_name)
		cls.value.name = "value"
		cls.value = M.load_cls_define(cls.value, cls_name)
		return cls
	end

	error(string.format("unsupport data type<%s>", data_type))
end

function M.init(type_list)
	cls_map = {}
	M.cls_ref_map = {}
	for _, item in ipairs(type_list) do
		assert(item.name, "not cls name")
		M.load_cls_define(item, nil)
	end
	M.cls_map = cls_map
end

function M.struct_setfield(obj, k, v)
	local cls = obj.__cls
	if not cls then
		error("struct no cls info")
	end
	local v_cls = cls.attrs[k]
	if not v_cls then
		error(string.format("cls<%s> has no attr<%s>", cls.name, k))
	end
	if type(v) == "table" and v.__cls ~= nil then
		if v_cls.id == v.__cls.id then
			rawset(obj, k, v)
			return
		end
		error(string.format(
			"obj<%s.%s> value type not match, need<%s>, give<%s>",
			cls.name, k, v_cls.id.name, v.__cls.name
		))
	end
	if v == nil and v_cls.is_atom then
		rawset(obj, k, nil)
		return
	end
	rawset(obj, k, v_cls:parse(v))
end

function M.list_setfield(obj, k, v)
	local cls = obj.__cls
	if not cls then
		error("list no cls info")
	end
	if k ~= math.tointeger(k) then
		error(string.format("cls<%s> key<%s> is not integer index", cls.name, tostring(k)))
	end
	if v == nil then
		rawset(obj, k, nil)
		return
	end
	local v_cls = cls.item
	if type(v) == "table" and v.__cls ~= nil then
		if v_cls.id == v.__cls.id then
			rawset(obj, k, v)
			return
		end
		error(string.format(
			"cls<%s.%s> value type not match, need<%s>, give<%s>",
			cls.name, k, v_cls.id.name, v.__cls.name
		))
	end
	rawset(obj, k, v_cls:parse(v))
end

function M.map_setfield(obj, k, v)
	local cls = obj.__cls
	if not cls then
		error("map no cls info")
	end
	local k_data = cls.key:parse(k)
	if v == nil then
		rawset(obj, k_data, nil)
		return
	end
	local v_cls = cls.value
	if type(v) == "table" and v.__cls ~= nil then
		if v_cls.id == v.__cls.id then
			rawset(obj, k_data, v)
			return
		end
		error(string.format(
			"obj<%s.%s> value type not match, need<%s>, give<%s>",
			cls.name, tostring(k_data), v_cls.id.name, v.__cls.name
		))
	end
	rawset(obj, k_data, v_cls:parse(v))
end

function M.create_struct(cls, data)
	local obj = {}
	setmetatable(obj, cls.mt)
	if data == nil then
		for k, v in pairs(cls.attrs) do
			if not v.is_atom then
				obj[k] = nil
			end
		end
	else
		for k, v in pairs(cls.attrs) do
			local k_data = data[k]
			if not (k_data == nil and v.is_atom) then
				obj[k] = k_data
			end
		end
	end
	return obj
end

function M.create_list(cls, data)
	local obj = {}
	setmetatable(obj, cls.mt)
	if data == nil then
		return obj
	end
	for idx, item in ipairs(data) do
		obj[idx] = item
	end
	return obj
end

function M.create_map(cls, data)
	local obj = {}
	setmetatable(obj, cls.mt)
	if data == nil then
		return obj
	end
	for k, v in pairs(data) do
		obj[k] = v
	end
	return obj
end

function M.create(cls_name, data)
	local cls = cls_map[cls_name]
	if not cls then
		error(string.format("create obj, illgeal cls<%s>", cls_name))
	end
	return cls:new(data)
end

local function dump_key(key_cls, k)
	if key_cls.type == "number" then
		return tostring(k)
	end
	return k
end

local function dump_by_cls(cls, value)
	if value == nil then
		return nil
	end
	if cls.is_atom then
		return value
	end
	return M.dump(value)
end

-- 纯 table，无 __cls；number-key map 的 key 转为 string，供 mongo 落库
function M.dump(obj)
	if type(obj) ~= "table" then
		return obj
	end
	local cls = obj.__cls
	if not cls then
		error("orm.dump: object has no __cls")
	end
	local data_type = cls.type
	if data_type == "struct" then
		local ret = {}
		for k, attr_cls in pairs(cls.attrs) do
			local v = obj[k]
			if v ~= nil then
				ret[k] = dump_by_cls(attr_cls, v)
			end
		end
		return ret
	end
	if data_type == "list" then
		local ret = {}
		for i, v in ipairs(obj) do
			ret[i] = dump_by_cls(cls.item, v)
		end
		return ret
	end
	if data_type == "map" then
		local ret = {}
		for k, v in pairs(obj) do
			ret[dump_key(cls.key, k)] = dump_by_cls(cls.value, v)
		end
		return ret
	end
	error(string.format("orm.dump unsupported type<%s>", tostring(data_type)))
end

function M.dump_field(obj, field)
	local cls = obj.__cls
	if not cls or cls.type ~= "struct" then
		error("orm.dump_field: obj must be struct")
	end
	local attr_cls = cls.attrs[field]
	if not attr_cls then
		error(string.format("orm.dump_field: cls<%s> no field<%s>", cls.name, field))
	end
	return dump_by_cls(attr_cls, obj[field])
end

function M.is_cls(obj, cls_name)
	return type(obj) == "table" and obj.__cls ~= nil and obj.__cls.name == cls_name
end

return M
