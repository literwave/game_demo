local BITSET = Import("../logic/service/world/module/bit_set/base.lua")

cls_map = cls_object:Inherit()

function cls_map:__init__(oci)
	Super(cls_map).__init__(self)
	self._width = oci._width
	self._height = oci._height
	self._cell_cnt = self._width * self._height
	self._bit_set = BITSET.cls_bit_set:New({
		_size = self._cell_cnt,
	})
end

function cls_map:get_width()
	return self._width
end

function cls_map:get_height()
	return self._height
end

function cls_map:in_bound(idx)
	return idx >= 1 and idx <= self._cell_cnt
end

function cls_map:load_block_from_res(map_res)
	local list = map_res.list
	local obstruct = CONST.MAP_CELL_TYPE.OBSTRUCT
	local cnt = 0
	for idx = 1, #list do
		if list[idx][1] == obstruct then
			self._bit_set:set(idx, true)
			cnt = cnt + 1
		end
	end
	return cnt
end

function cls_map:is_block(idx)
	if not self:in_bound(idx) then
		return true
	end
	return self._bit_set:get(idx)
end
