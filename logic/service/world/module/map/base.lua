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
	-- 可以落主城的格子，和已经分出去的出生点
	self._birth_ok = BITSET.cls_bit_set:New({
		_size = self._cell_cnt,
	})
	self._birth_taken = BITSET.cls_bit_set:New({
		_size = self._cell_cnt,
	})
	self._birth_free = 0
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

local function can_birth(cell_type)
	return cell_type ~= CONST.MAP_CELL_TYPE.OBSTRUCT
		and cell_type ~= CONST.MAP_CELL_TYPE.SYS_FORTRESS
		and cell_type ~= CONST.MAP_CELL_TYPE.SYS_CITY
		and cell_type ~= CONST.MAP_CELL_TYPE.FORTRESS
end

function cls_map:load_block_from_res(map_res)
	local list = map_res.list
	local obstruct = CONST.MAP_CELL_TYPE.OBSTRUCT
	local cnt = 0
	local birth_free = 0
	for idx = 1, #list do
		local cell_type = list[idx][1]
		if cell_type == obstruct then
			self._bit_set:set(idx, true)
			cnt = cnt + 1
		elseif can_birth(cell_type) then
			self._birth_ok:set(idx, true)
			birth_free = birth_free + 1
		end
	end
	self._birth_free = birth_free
	return cnt
end

function cls_map:is_block(idx)
	if not self:in_bound(idx) then
		return true
	end
	return self._bit_set:get(idx)
end

function cls_map:release_birth_idx(idx)
	if not self:in_bound(idx) or not self._birth_taken:get(idx) then
		return
	end
	self._birth_taken:set(idx, false)
	self._birth_free = self._birth_free + 1
end

function cls_map:hold_birth_idx(idx)
	if not self:in_bound(idx) or not self._birth_ok:get(idx) or self._birth_taken:get(idx) then
		return false
	end
	self._birth_taken:set(idx, true)
	self._birth_free = self._birth_free - 1
	return true
end

-- 先随机几次，撞上障碍或已占用再从随机起点扫一整圈
function cls_map:alloc_birth_idx()
	if self._birth_free < 1 then
		return
	end
	local n = self._cell_cnt
	for _ = 1, 32 do
		local idx = math.random(1, n)
		if self:hold_birth_idx(idx) then
			return idx
		end
	end
	local start = math.random(1, n)
	for i = 0, n - 1 do
		local idx = (start + i - 1) % n + 1
		if self:hold_birth_idx(idx) then
			return idx
		end
	end
end
