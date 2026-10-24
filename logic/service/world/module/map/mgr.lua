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

-- 已经落库的出生点占住，避免重启后分到同一格。没有出生点的旧号不补
local function load_used_birth()
	local all = MONGO_SLAVE.common_load_tbl(MONGO_SLAVE.COL.USER_INFO)
	for _, dat in pairs(all) do
		if dat._has_birth then
			map_obj:hold_birth_idx(pos_to_idx({x = dat._birth_x, y = dat._birth_y}, map_obj:get_width()))
		end
	end
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
	load_used_birth()
	skynet.error("world map init", map_res.w, map_res.h, "block", block_cnt)
end

function get_map()
	return map_obj
end

function is_block(idx)
	return map_obj:is_block(idx)
end

function alloc_birth_pos()
	local idx = map_obj:alloc_birth_idx()
	if not idx then
		return
	end
	return idx_to_pos(idx, map_obj:get_width())
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
