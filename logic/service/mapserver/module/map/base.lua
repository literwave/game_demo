
local saveFieldTbl = {
}

clsMap = clsObject:Inherit()

local BITSET = Import("../logic/service/mapserver/module/bit_set/base.lua")

function clsMap:__init__(oci)
	Super(clsMap).__init__(self, oci)
	for k, func in pairs(saveFieldTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
	self._bitSet = BITSET.new(CONST.MAP_WIDTH, CONST.MAP_HEIGHT)
end

function clsMap:registerPart(partType, width, height)
	self._partType = partType
	self._width = width
	self._height = height
	self._qtree = QTREE.new(CONST.MAP_WIDTH, CONST.MAP_HEIGHT)
end