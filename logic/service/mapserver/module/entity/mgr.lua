allEntity = {
	-- [entityId] = entity
}

local ENTITY_TO_MOD = {
	[CONST.ENTITY_TYPE.MAIN_HALL] = Import("../logic/service/mapserver/module/entity/base.lua"),
}


function syncToMap(oci)
	local entityType = oci._type
	local mod = ENTITY_TO_MOD[entityType]
	assert(mod)
	local entity = mod.clsEntity:new(oci)
	allEntity[oci._id] = entity
end