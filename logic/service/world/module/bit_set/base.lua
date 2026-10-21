cls_bit_set = cls_object:Inherit()

function cls_bit_set:__init__(oci)
	Super(cls_bit_set).__init__(self)
	self._size = oci._size
	self._data = {}
	local word_cnt = math.ceil(self._size / CONST.INT_SIZE)
	for i = 1, word_cnt do
		self._data[i] = 0
	end
end

-- idx 与 map_res.list 相同，从 1 起
local function bit_pos(idx)
	local linear = idx - 1
	local word = math.floor(linear / CONST.INT_SIZE) + 1
	local bit = linear % CONST.INT_SIZE
	return word, bit
end

function cls_bit_set:set(idx, flag)
	local word, bit = bit_pos(idx)
	if flag then
		self._data[word] = self._data[word] | (1 << bit)
	else
		self._data[word] = self._data[word] & ~(1 << bit)
	end
end

function cls_bit_set:get(idx)
	local word, bit = bit_pos(idx)
	return ((self._data[word] >> bit) & 1) == 1
end
