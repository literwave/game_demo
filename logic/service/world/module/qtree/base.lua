
local save_field_tbl = {
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

cls_q_tree = cls_object:Inherit()

function cls_q_tree:__init__(oci)
	Super(cls_q_tree).__init__(self)
	for k, func in pairs(save_field_tbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
end

function cls_q_tree:split()
	local half = self._size / 2
	if half < 1 then return end
	self._children = {
		q_tree.new(self._x, self._y, half),
		q_tree.new(self._x + half, self._y, half),
		q_tree.new(self._x, self._y + half, half),
		q_tree.new(self._x + half, self._y + half, half)
	}
end
