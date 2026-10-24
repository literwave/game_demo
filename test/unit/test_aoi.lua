-- vendor/aoi：半径 10。近处能看见，远处看不见，d 之后不再产生事件

local aoi = require "aoi"

local function has_pair(list, watcher, marker)
	for _, pair in ipairs(list) do
		if pair[1] == watcher and pair[2] == marker then
			return true
		end
	end
	return false
end

return {
	near = function()
		local space = aoi.new()
		space:update(1, "w", 0, 0, 0)
		space:update(2, "m", 1, 0, 0)
		local list = space:message()
		assert(has_pair(list, 1, 2), "watcher should see marker within radius")
		space:release()
	end,
	far = function()
		local space = aoi.new()
		space:update(1, "w", 0, 0, 0)
		space:update(2, "m", 100, 0, 0)
		local list = space:message()
		assert(#list == 0, "marker outside 20 should not be reported")
		space:release()
	end,
	drop = function()
		local space = aoi.new()
		space:update(1, "w", 0, 0, 0)
		space:update(2, "wm", 1, 0, 0)
		space:message()
		space:update(2, "d", 1, 0, 0)
		space:update(1, "w", 0.5, 0, 0)
		local list = space:message()
		assert(not has_pair(list, 1, 2), "dropped object should not be seen")
		space:release()
	end,
}
