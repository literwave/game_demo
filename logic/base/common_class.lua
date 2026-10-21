
function __iml_inter_face_with_copy(self, iml_class)
	for k, v in pairs(iml_class) do
		assert(not self[k])
		if not self[k] then
			self[k]=v
		end
	end
end

function __remove_inter_face(self, iml_class)
	for k, v in pairs(iml_class) do
		assert(self[k])
		self[k]=nil
	end
end

function __inherit_with_copy(Base, o)
	o = o or {}

	for k, v in pairs(Base) do
		assert(not o[k])
		if not o[k] then
			o[k]=v
		end
	end

	o.__super_class = Base
	o.__sub_class = nil
	o.__is_class = true

	if not Base.__sub_class then
		Base.__sub_class = {}
	end

	table.insert(Base.__sub_class, o)

	return o
end

function __refresh_inherit(self, old_class)
	if self.__sub_class then
		for _, sub_class in pairs(self.__sub_class) do
			for k, v in pairs(self) do
				if k ~= "__sub_class" then
					if not sub_class[k] then
						sub_class[k] = v
					else
						if old_class[k] and (old_class[k] == sub_class[k]) then
							sub_class[k] = v
						end
					end
				end
			end
			sub_class.__super_class = self 

			sub_class:refresh_inherit(old_class)
		end
	end
end

function __move_class_inherit_info(self, new_class)
	if self.__super_class then
		local parent_class = self.__super_class
		local find_idx = nil
		for idx, class in pairs(parent_class.__sub_class) do
			if class == self then
				find_idx = idx
				break
			end
		end
		table.remove(parent_class.__sub_class, find_idx)
	end

	if self.__sub_class then
		new_class.__sub_class = {}
		for idx, sub_class in pairs(self.__sub_class) do
			new_class.__sub_class[idx] = sub_class
		end
	end
end

local function get_class_tbl(Module)
	local class_tbl = {}
	for k, v in pairs(Module) do
		if type(v) == "table" and v.__is_class then
			class_tbl[k] = v
		end
	end
	return class_tbl
end

local function refresh_sub_class_func(new_class, old_class_func, depth)
	assert(depth <= 20)
	for idx, sub_class in pairs(new_class.__sub_class) do
		for k, v in pairs(new_class) do
			if type(v) == "function" then
				if not sub_class[k] or (sub_class[k] == old_class_func[k]) then
					sub_class[k] = v
				end
			end
		end
		if sub_class.__sub_class then
			refresh_sub_class_func(sub_class, old_class_func, depth + 1)
		end
	end
end

local function do_update_file_by_func(path_file, func, Old)
	local old_class_tbl = get_class_tbl(Old) 
	local old_module_data = {}
	if (path_file ~= "common/const.lua") and (not string.find(path_file,  "autocode/")) then
		for k, v in pairs(Old) do
			if type(v) ~= "function" then
				if type(v) == "table" then
					if not rawget(v, "__is_class") then
						old_module_data[k] = v
					end
				else
					old_module_data[k] = v
				end
			end
		end
	end
	--[[
		class_name = class_tbl,
	--]]
	setfenv(func, Old)()
	local new_class_tbl = get_class_tbl(Old) 

	for new_class_name, new_class_iml in pairs(new_class_tbl) do
		local old_class_iml = old_class_tbl[new_class_name]
		if old_class_iml then
			local old_class_func = {}
			new_class_tbl[new_class_name] = old_class_iml
			for k, v in pairs(old_class_iml) do
				if type(v) == "function" then
					old_class_iml[k] = nil
					old_class_func[k] = v
				end
			end
			for k, v in pairs(new_class_iml) do
				if type(v) == "function" then
					old_class_iml[k] = v
				end
			end
			if old_class_iml.__sub_class then
				refresh_sub_class_func(old_class_iml, old_class_func, 0)
			end
		end
	end

	for k, v in pairs(new_class_tbl) do
		Old[k] = v
	end

	for k, v in pairs(old_module_data) do
		Old[k] = v
		if LOG and LOG.update_file then
			LOG.update_file(string.format("k=%s,v=%s,type=%s", k, string.sub(tostring(v), 1, 50), type(v)))
		end
	end

	if rawget(Old, "__init__") then
		Old:__init__()
	end

	if rawget(Old, "after_init_module") then
		Old:after_init_module()
	end

	return true
end

function __update_import_by_content(import_module, path_file, content)
	local Old = import_module[path_file]
	if not Old then
		return false
	end

	local func, err = loadstring(content)

	if not func then
		print(string.format("ERROR!!!\n%s\n%s", err, debug.traceback()))
		return false
	end
	do_update_file_by_func(path_file, func, Old)
	return true
end

function __update_import(import_module, path_file, load_lua_func)
	local Old = import_module[path_file]
	if not Old then
		return false
	end

	local func, err = load_lua_func(path_file)

	if not func then
		print(string.format("ERROR!!!\n%s\n%s", err, debug.traceback()))
		return false
	end
	do_update_file_by_func(path_file, func, Old)
	return true
end

