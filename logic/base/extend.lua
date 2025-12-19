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

function table.isEmpty(luaTable)
	if not luaTable then
		return
	end
	for _ in pairs(luaTable) do
		return false
	end
	return true
end

if not table.maxn then
	table.maxn = function (array)
		local curMax
		for idx in ipairs(array) do
			if not curMax then
				curMax = idx
			else
				curMax = math.max(idx, curMax)
			end
		end
		return curMax
	end
end

local function keyToNumber(fixTbl, preString)
	for k, v in pairs(fixTbl) do
		if type(k) == "string" then
			if k:sub(1, 2) == '@' then
				fixTbl[k:sub(2, #k)] = v
			end
		end
		if type(v) == "table" then
			keyToNumber(v, preString)
		end
	end
	return fixTbl
end

function table.removePreString(fixTbl, preString)
	if not fixTbl then
		return fixTbl
	end
	return keyToNumber(fixTbl, preString)
end

function table.addNumberKeyPreString(fixTbl, preString)
	for key, value in pairs(fixTbl) do
		local newKey = numberKeyAddPreString(key, preString)
		if type(value) == "table" then
			table.addNumberKeyPreString(value, preString)
		end
		fixTbl[newKey] = value
	end
end

function table.hasElement(tbl)
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
	local tblLen = 0
	for _ in pairs(tbl) do
		tblLen = tblLen + 1
	end
	return tblLen
end

function numberKeyAddPreString(key, preString)
	if type(key) == "number" then
		return string.format("%s%d", preString, key)
	else
		return key
	end
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

function makeCommonPtoTbl(k, v)
	return { k = k, v = v}
end

EMPTY_TABLE = {}