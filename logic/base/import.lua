
local string=string

_G._import_module = _G._import_module or {}
local _import_module = _G._import_module

local function update_import_by_content(path_file, content)
	return __update_import_by_content(_import_module, path_file, content)
end

local function update_import(path_file)
	return __update_import(_import_module, path_file, loadfile)
end

local function do_import(path_file)
	local func, err = loadfile(path_file)

	if not func then
		print(string.format("ERROR!!!\n%s\n%s", err, debug.traceback()))
		return func, err
	end

	local New = {}
	_import_module[path_file] = New
	--设置原始环境
	setmetatable(New, {__index = _G})
	setfenv(func, New)()
	New.__FILE__ = path_file

	if rawget(New, "__init__") then
		New:__init__()
	end

	return New
end

local function safe_import(path_file)
	local Old = _import_module[path_file]
	if Old then
		return Old
	end

	return do_import(path_file)
end

function Reimport(path_file)
	return do_import(path_file)
end

function local_env_do_file(file_name)
	local env = getfenv(2)
	local func, err = loadfile(file_name)
	setfenv(func, env)()
end

function Import(path_file)
	local Module, Err = safe_import(path_file)
	assert(Module, Err)

	return Module
end

function update_lua_file(path_file)
	local ret = update_import(path_file)
	return ret
end

function update_lua_by_content(path, content)
	update_import_by_content(path, content)
end

-- 一批文件一起热更：先全部编译，有一个编译不过就整批不更，避免只更一半。
-- 本服务没 Import 过的文件跳过，所以可以对所有服务广播同一批文件
function hot_update(path_list)
	local func_tbl = {}
	local updated = {}
	for _, path in ipairs(path_list) do
		if _import_module[path] then
			local func, err = loadfile(path)
			if not func then
				return {ok = false, err = err}
			end
			func_tbl[path] = func
		end
	end
	for _, path in ipairs(path_list) do
		local func = func_tbl[path]
		if func then
			local ok, err = pcall(__update_import, _import_module, path, function() return func end)
			if not ok then
				return {ok = false, err = string.format("%s: %s", path, tostring(err)), updated = updated}
			end
			table.insert(updated, path)
		end
	end
	return {ok = true, updated = updated}
end

