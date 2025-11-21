
local string=string
local table=table
local pairs=pairs

_G._ImportModule = _G._ImportModule or {}
local _ImportModule = _G._ImportModule

local function getClassTbl(Module)
	local classTbl = {}
	for k, v in pairs(Module) do
		if type(v) == "table" and v.__IsClass then
			classTbl[k] = v
		end
	end
	return classTbl
end

local function updateImportByContent(pathFile, content)
	return __updateImportByContent(_ImportModule, pathFile, content)
end

local function updateImport(PathFile)
	return __updateImport(_ImportModule, PathFile, loadfile)
end

local function doImport(PathFile)
	local func, err = loadfile(PathFile)

	if not func then
		print(string.format("ERROR!!!\n%s\n%s", err, debug.traceback()))
		return func, err
	end

	local New = {}
	_ImportModule[PathFile] = New
	--设置原始环境
	setmetatable(New, {__index = _G})
	setfenv(func, New)()
	New.__FILE__ = PathFile

	if rawget(New, "__init__") then
		New:__init__()
	end

	return New
end

local function SafeImport(PathFile)
	local Old = _ImportModule[PathFile]
	if Old then
		return Old
	end

	return doImport(PathFile)
end

function Reimport(PathFile)
	return doImport(PathFile)
end

function localEnvDoFile(fileName)
	local env = getfenv(2)
	local func, err = loadfile(fileName)
	setfenv(func, env)()
end

function Import(PathFile)
	local Module, Err = SafeImport(PathFile)
	assert(Module, Err)

	return Module
end

function updateLuaFile(PathFile)
	local ret = updateImport(PathFile)
	return ret
end

function updateLuaByContent(path, content)
	updateImportByContent(path, content)
end

