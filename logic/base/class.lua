
function Super(TmpClass)
	return TmpClass.__SuperClass
end

----------------------------------------------------------------- lua class
--基础类库

--------------------------- class def
clsObject = {
	Inherit = __InheritWithCopy,
	ImplementFrom = __ImlInterFaceWithCopy,
	__IsClass = true,
}
		
function clsObject:New(...)
	local o = {}

	setmetatable(o, { __index = self })

	o:__init__(...)

	return o
end

function clsObject:moveClassInheritInfo(newClass)
	__moveClassInheritInfo(self, newClass)
end

function clsObject:refreshInherit(oldClass) -- 刷新所有的子类把newClass当父类
	__refreshInherit(self, oldClass)
end

----------------------------

function clsObject:__init__()
end

function clsObject:release()
end