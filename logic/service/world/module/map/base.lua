local BITSET = Import("../logic/service/world/module/bit_set/base.lua")

clsMap = clsObject:Inherit()

function clsMap:__init__(oci)
	Super(clsMap).__init__(self)
	self._width = oci._width
	self._height = oci._height
	self._cellCnt = self._width * self._height
	self._bitSet = BITSET.clsBitSet:New({
		_size = self._cellCnt,
	})
end

function clsMap:getWidth()
	return self._width
end

function clsMap:getHeight()
	return self._height
end

function clsMap:inBound(idx)
	return idx >= 1 and idx <= self._cellCnt
end

function clsMap:loadBlockFromRes(mapRes)
	local list = mapRes.list
	local obstruct = CONST.MAP_CELL_TYPE.OBSTRUCT
	local cnt = 0
	for idx = 1, #list do
		if list[idx][1] == obstruct then
			self._bitSet:set(idx, true)
			cnt = cnt + 1
		end
	end
	return cnt
end

function clsMap:isBlock(idx)
	if not self:inBound(idx) then
		return true
	end
	return self._bitSet:get(idx)
end
