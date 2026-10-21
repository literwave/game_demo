
function Super(tmp_class)
	return tmp_class.__super_class
end

----------------------------------------------------------------- lua class
--基础类库

--------------------------- class def
cls_object = {
	Inherit = __inherit_with_copy,
	implement_from = __iml_inter_face_with_copy,
	__is_class = true,
}
		
function cls_object:New(...)
	local o = {}

	setmetatable(o, { __index = self })

	o:__init__(...)

	return o
end

function cls_object:move_class_inherit_info(new_class)
	__move_class_inherit_info(self, new_class)
end

function cls_object:refresh_inherit(old_class) -- 刷新所有的子类把newClass当父类
	__refresh_inherit(self, old_class)
end

----------------------------

function cls_object:__init__()
end

function cls_object:release()
end