
local save_field_tbl = {
}

cls_entity = cls_object:Inherit()

function cls_entity:__init__(oci)
	Super(cls_entity).__init__(self)
	for k, func in pairs(save_field_tbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
end
