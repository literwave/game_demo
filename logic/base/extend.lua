if not setfenv then -- Lua 5.2 or 5.3
	-- based on http://lua-users.org/lists/lua-l/2010-06/msg00314.html
	-- this assumes f is a function
	local function findenv(f)
		local level = 1
		repeat
			local name, value = debug.getupvalue(f, level)
			if name == '_ENV' then return level, value end
			level = level + 1
		until name == nil
		return nil
	end
	getfenv = function (f)
		if type(f) == "number" then
			f = debug.getinfo(f + 1, 'f').func
		end
		if f then
			return select(2, findenv(f))
		else
			return _G
		end
	end
	setfenv = function (f, t)
		local level = findenv(f)
		if level then debug.setupvalue(f, level, t) end
		return f
	end
end

function table.is_empty(lua_table)
	if not lua_table then
		return
	end
	for _ in pairs(lua_table) do
		return false
	end
	return true
end

if not table.maxn then
	table.maxn = function (array)
		local cur_max
		for idx in ipairs(array) do
			if not cur_max then
				cur_max = idx
			else
				cur_max = math.max(idx, cur_max)
			end
		end
		return cur_max
	end
end




function table.has_element(tbl)
	if not tbl then
		return
	end
	for _ in pairs(tbl) do
		return true
	end
end

function table.deepcopy(t, d)
	local deep = d or 0
	assert(deep <= 20)
	local copy = {}
	for k, v in pairs(t) do 
		if type(v) ~= "table" then 
			copy[k] = v
		else 
			copy[k] = table.deepcopy(v, deep + 1) 
		end  
	end  
	return copy 
end

function table.size(tbl)
	local tbl_len = 0
	for _ in pairs(tbl) do
		tbl_len = tbl_len + 1
	end
	return tbl_len
end

function table.val_to_number(tbl)
	for key, val in pairs(tbl) do
		tbl[key] = tostring(val)
	end
	return tbl
end


function string.split(input, delimiter)
	input = tostring(input)
	delimiter = tostring(delimiter)
	if (delimiter=='') then return false end
	local pos,arr = 0, {}
	for st,sp in function() return string.find(input, delimiter, pos, true) end do
		table.insert(arr, string.sub(input, pos, st - 1))
		pos = sp + 1
	end
	table.insert(arr, string.sub(input, pos))
	return arr
end

function table2str(obj, indent)
	indent = indent or 0 
	local str = ""
	local indent_str = string.rep("\t", indent) 
	if type(obj) ~= "table" then
		return tostring(obj)
	end
	str = str .. "{\n"
	for k, v in pairs(obj) do
		str = str .. indent_str .. "\t[" .. tostring(k) .. "] = "
		if type(v) == "table" then
			str = str .. table2str(v, indent + 1) .. ",\n"
		else
			str = str .. tostring(v) .. ",\n"
		end
	end
	str = str .. indent_str .. "}"
	
	return str
end

function make_common_pto_tbl(k, v)
	return { k = k, v = v}
end

function rand_item_by_weight(tbl)
	local sum = 0
	for _, v in pairs(tbl) do
		sum = sum + v[2]
	end
	if sum <= 0 then
		return
	end
	local rand = math.random(sum)
	local cur_sum = 0
	for _, v in pairs(tbl) do
		cur_sum = cur_sum + v[2]
		if cur_sum >= rand then
			return v[1]
		end
	end
end

local id = 0
local OPEN_DATE = 1704067200
function get_id_by_user_id_and_timestamp(user_id)
	id = id + 1
	local sec = os.time() - OPEN_DATE
	return string.format("%06d%08d%03d", user_id, sec, id)
end

local srv_auto_id = 0
function get_id_by_srv_id_and_timestamp()
	srv_auto_id = srv_auto_id + 1
	local sec = os.time() - OPEN_DATE
	return string.format("%06d%08d%03d", GAME.get_server_id(), sec, srv_auto_id)
end

EMPTY_TABLE = {}