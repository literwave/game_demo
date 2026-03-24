
local saveFieldTbl = {
	_width = function ()
		return nil
	end,
	_height = function ()
		return nil
	end,
}

clsBitSet = clsObject:Inherit()

function clsBitSet:__init__(oci)
	Super(clsBitSet).__init__(self)
	for k, func in pairs(saveFieldTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
	local size = math.ceil((self._width * self._height) / CONST.INT_SIZE)
	for i = 1, size do
		self._data[i] = 0
	end
	return self
end
