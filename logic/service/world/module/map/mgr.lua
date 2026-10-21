local skynet = require "skynet"
local navigation = require "navigation"

local MAP_RES_PATH = "../res/map/map_res.lua"

map_obj = nil
map_res = nil
nav_obj = nil

local function idx_to_pos(idx, w)
	local linear = idx - 1
	return {
		x = linear % w,
		y = linear // w,
	}
end

local function pos_to_idx(pos, w)
	return math.floor(pos.y) * w + math.floor(pos.x) + 1
end

function init()
	map_res = dofile(MAP_RES_PATH)
	assert(map_res and map_res.w and map_res.h and map_res.list, "load map_res failed")
	map_obj = MAP_BASE.cls_map:New({
		_width = map_res.w,
		_height = map_res.h,
	})
	local block_cnt = map_obj:load_block_from_res(map_res)
	local w = map_res.w
	local obstruct = CONST.MAP_CELL_TYPE.OBSTRUCT
	local obstacles = {}
	for idx = 1, #map_res.list do
		if map_res.list[idx][1] == obstruct then
			local pos = idx_to_pos(idx, w)
			obstacles[#obstacles + 1] = { pos.x, pos.y }
		end
	end
	nav_obj = navigation.new(w, map_res.h, obstacles)
	skynet.error("world map init", map_res.w, map_res.h, "block", block_cnt)
end

function get_map()
	return map_obj
end

function is_block(idx)
	return map_obj:is_block(idx)
end

function find_path(from_idx, to_idx)
	local w = map_obj:get_width()
	local path = nav_obj:find_path(idx_to_pos(from_idx, w), idx_to_pos(to_idx, w))
	local ret = {}
	for _, pos in ipairs(path or {}) do
		ret[#ret + 1] = pos_to_idx(pos, w)
	end
	return ret
end
