local skynet = require "skynet"
local tinsert = table.insert

_G.__import_module__ = _G.__import_module__ or {}
_G._mod_list = _G._mod_list or {} -- 用来等所有模块加载完成执行__start_up__ 函数的


local __import_module__ = _G.__import_module__
local __mod_list__ = _G._mod_list
local function doimport(pathfile)
	local func, err = loadfile(pathfile, "bt")
	if not func then
		skynet.eror(string.format("ERROR!!!\n%s\n%s", err, debug.traceback()))
		return func, err
	end
	local mod = func()
	__import_module__[pathfile] = mod
	if mod.__startup__ then
		tinsert(__mod_list__, mod)
	end
	
	if mod.__init__ then
		mod:__init__()
	end
	if mod.__protocol__ then
		mod:__protocol__()
	end
	return mod
end

local function safeimport(pathfile)
	local old = __import_module__[pathfile]
	if old then
		return old
	end
	return doimport(pathfile)
end

function import(pathfile)
	local module, err = safeimport(pathfile)
	assert(module, err)
	return module
end

function exModuleStartUp()
	for _, mod in ipairs(__mod_list__) do
		mod:__start_up()
	end
end
