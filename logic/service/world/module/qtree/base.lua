
local saveFieldTbl = {
	_x = function ()
		return nil
	end,
	_y = function ()
		return nil
	end,
	_size = function ()
		return nil
	end,
	_type = function ()
		return nil
	end,
	_children = function ()
		return nil
	end,
}

clsQTree = clsObject:Inherit()

function clsQTree:__init__(oci)
	Super(clsQTree).__init__(self)
	for k, func in pairs(saveFieldTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
end

function clsQTree:split()
	local half = self._size / 2
	if half < 1 then return end
	self._children = {
		qTree.new(self._x, self._y, half),
		qTree.new(self._x + half, self._y, half),
		qTree.new(self._x, self._y + half, half),
		qTree.new(self._x + half, self._y + half, half)
	}
end
