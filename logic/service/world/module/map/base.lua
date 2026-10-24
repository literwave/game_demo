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
	-- 建议出生点。新号只从这里分，迁城可以落到其它空地
	self._spawn = BITSET.cls_bit_set:New({
		_size = self._cell_cnt,
	})
	self._spawn_list = {}
	self._spawn_free = 0
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

function cls_map:set_block(idx)
	if not self:in_bound(idx) or self._bit_set:get(idx) then
		return false
	end
	self._bit_set:set(idx, true)
	return true
end

function cls_map:is_birth_cell(idx)
	return self:in_bound(idx) and self._birth_ok:get(idx)
end

function cls_map:allow_birth(idx)
	if not self:in_bound(idx) or self._bit_set:get(idx) or self._birth_ok:get(idx) then
		return false
	end
	self._birth_ok:set(idx, true)
	self._birth_free = self._birth_free + 1
	return true
end

function cls_map:mark_spawn(idx)
	if not self._birth_ok:get(idx) or self._spawn:get(idx) then
		return false
	end
	self._spawn:set(idx, true)
	self._spawn_list[#self._spawn_list + 1] = idx
	self._spawn_free = self._spawn_free + 1
	return true
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
	if self._spawn:get(idx) then
		self._spawn_free = self._spawn_free + 1
	end
end

function cls_map:hold_birth_idx(idx)
	if not self:in_bound(idx) or not self._birth_ok:get(idx) or self._birth_taken:get(idx) then
		return false
	end
	self._birth_taken:set(idx, true)
	self._birth_free = self._birth_free - 1
	if self._spawn:get(idx) then
		self._spawn_free = self._spawn_free - 1
	end
	return true
end

-- 先占新格子再放开旧格子。新格子不能落城时旧格子保持占用
function cls_map:relocate_birth(old_idx, new_idx)
	if old_idx == new_idx then
		return true
	end
	if not self:hold_birth_idx(new_idx) then
		return false
	end
	self:release_birth_idx(old_idx)
	return true
end

-- 新号只占建议出生点，出生区满了就不再往资源州丢
function cls_map:alloc_birth_idx()
	local list = self._spawn_list
	if self._spawn_free < 1 or #list < 1 then
		return
	end
	for _ = 1, 32 do
		local idx = list[math.random(#list)]
		if self:hold_birth_idx(idx) then
			return idx
		end
	end
	for i = 1, #list do
		if self:hold_birth_idx(list[i]) then
			return list[i]
		end
	end
end

-- 野怪落在空地上，不占建议出生点
function cls_map:alloc_wild_idx()
	local n = self._cell_cnt
	for _ = 1, 64 do
		local idx = math.random(1, n)
		if self._birth_ok:get(idx) and not self._spawn:get(idx) and self:hold_birth_idx(idx) then
			return idx
		end
	end
	local start = math.random(1, n)
	for i = 0, n - 1 do
		local idx = (start + i - 1) % n + 1
		if self._birth_ok:get(idx) and not self._spawn:get(idx) and self:hold_birth_idx(idx) then
			return idx
		end
	end
end
