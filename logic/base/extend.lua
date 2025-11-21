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