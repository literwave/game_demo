all_entity = {
	-- [entityId] = entity
}

local ENTITY_TO_MOD = {
	[CONST.ENTITY_TYPE.MAIN_HALL] = Import("../logic/service/world/module/entity/base.lua"),
}


function sync_to_map(oci)
	local entity_type = oci._type
	local mod = ENTITY_TO_MOD[entity_type]
	assert(mod)
	local entity = mod.cls_entity:new(oci)
	all_entity[oci._id] = entity
end