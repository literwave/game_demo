clsBitSet = clsObject:Inherit()

function clsBitSet:__init__(oci)
	Super(clsBitSet).__init__(self)
	self._size = oci._size
	self._data = {}
	local wordCnt = math.ceil(self._size / CONST.INT_SIZE)
	for i = 1, wordCnt do
		self._data[i] = 0
	end
end

-- idx 与 map_res.list 相同，从 1 起
local function bitPos(idx)
	local linear = idx - 1
	local word = math.floor(linear / CONST.INT_SIZE) + 1
	local bit = linear % CONST.INT_SIZE
	return word, bit
end

function clsBitSet:set(idx, flag)
	local word, bit = bitPos(idx)
	if flag then
		self._data[word] = self._data[word] | (1 << bit)
	else
		self._data[word] = self._data[word] & ~(1 << bit)
	end
end

function clsBitSet:get(idx)
	local word, bit = bitPos(idx)
	return ((self._data[word] >> bit) & 1) == 1
end
