
function __ImlInterFaceWithCopy(self, imlClass)
	for k, v in pairs(imlClass) do
		assert(not self[k])
		if not self[k] then
			self[k]=v
		end
	end
end

function __RemoveInterFace(self, imlClass)
	for k, v in pairs(imlClass) do
		assert(self[k])
		self[k]=nil
	end
end

function __InheritWithCopy(Base, o)
	o = o or {}

	for k, v in pairs(Base) do
		assert(not o[k])
		if not o[k] then
			o[k]=v
		end
	end

	o.__SuperClass = Base
	o.__SubClass = nil
	o.__IsClass = true

	if not Base.__SubClass then
		Base.__SubClass = {}
	end

	table.insert(Base.__SubClass, o)

	return o
end

function __refreshInherit(self, oldClass)
	if self.__SubClass then
		for _, sub_class in pairs(self.__SubClass) do
			for k, v in pairs(self) do
				if k ~= "__SubClass" then
					if not sub_class[k] then
						sub_class[k] = v
					else
						if oldClass[k] and (oldClass[k] == sub_class[k]) then
							sub_class[k] = v
						end
					end
				end
			end
			sub_class.__SuperClass = self 

			sub_class:refreshInherit(oldClass)
		end
	end
end

function __moveClassInheritInfo(self, newClass)
	if self.__SuperClass then
		local parentClass = self.__SuperClass
		local findIdx = nil
		for idx, class in pairs(parentClass.__SubClass) do
			if class == self then
				findIdx = idx
				break
			end
		end
		table.remove(parentClass.__SubClass, findIdx)
	end

	if self.__SubClass then
		newClass.__SubClass = {}
		for idx, sub_class in pairs(self.__SubClass) do
			newClass.__SubClass[idx] = sub_class
		end
	end
end

local function getClassTbl(Module)
	local classTbl = {}
	for k, v in pairs(Module) do
		if type(v) == "table" and v.__IsClass then
			classTbl[k] = v
		end
	end
	return classTbl
end

local function refreshSubClassFunc(newClass, oldClassFunc, depth)
	assert(depth <= 20)
	for idx, subClass in pairs(newClass.__SubClass) do
		for k, v in pairs(newClass) do
			if type(v) == "function" then
				if not subClass[k] or (subClass[k] == oldClassFunc[k]) then
					subClass[k] = v
				end
			end
		end
		if subClass.__SubClass then
			refreshSubClassFunc(subClass, oldClassFunc, depth + 1)
		end
	end
end

local function doUpdateFileByFunc(PathFile, func, Old)
	local oldClassTbl = getClassTbl(Old) 
	local oldModuleData = {}
	if (PathFile ~= "common/const.lua") and (not string.find(PathFile,  "autocode/")) then
		for k, v in pairs(Old) do
			if type(v) ~= "function" then
				if type(v) == "table" then
					if not rawget(v, "__IsClass") then
						oldModuleData[k] = v
					end
				else
					oldModuleData[k] = v
				end
			end
		end
	end
	--[[
		class_name = class_tbl,
	--]]
	setfenv(func, Old)()
	local newClassTbl = getClassTbl(Old) 

	for newClassName, newClassIml in pairs(newClassTbl) do
		local oldClassIml = oldClassTbl[newClassName]
		if oldClassIml then
			local oldClassFunc = {}
			newClassTbl[newClassName] = oldClassIml
			for k, v in pairs(oldClassIml) do
				if type(v) == "function" then
					oldClassIml[k] = nil
					oldClassFunc[k] = v
				end
			end
			for k, v in pairs(newClassIml) do
				if type(v) == "function" then
					oldClassIml[k] = v
				end
			end
			if oldClassIml.__SubClass then
				refreshSubClassFunc(oldClassIml, oldClassFunc, 0)
			end
		end
	end

	for k, v in pairs(newClassTbl) do
		Old[k] = v
	end

	for k, v in pairs(oldModuleData) do
		Old[k] = v
		if LOG and LOG.updateFile then
			LOG.updateFile(string.format("k=%s,v=%s,type=%s", k, string.sub(tostring(v), 1, 50), type(v)))
		end
	end

	if rawget(Old, "__init__") then
		Old:__init__()
	end

	if rawget(Old, "afterInitModule") then
		Old:afterInitModule()
	end

	return true
end

function __updateImportByContent(importModule, PathFile, content)
	local Old = importModule[PathFile]
	if not Old then
		return false
	end

	local func, err = loadstring(content)

	if not func then
		print(string.format("ERROR!!!\n%s\n%s", err, debug.traceback()))
		return false
	end
	doUpdateFileByFunc(PathFile, func, Old)
	return true
end

function __updateImport(importModule, PathFile, loadLuaFunc)
	local Old = importModule[PathFile]
	if not Old then
		return false
	end

	local func, err = loadLuaFunc(PathFile)

	if not func then
		print(string.format("ERROR!!!\n%s\n%s", err, debug.traceback()))
		return false
	end
	doUpdateFileByFunc(PathFile, func, Old)
	return true
end

