local skynet = require "skynet"
local navigation = require "navigation"

local MAP_RES_PATH = "../res/map/map_res.lua"

mapObj = nil
mapRes = nil
navObj = nil

local function idxToPos(idx, w)
	local linear = idx - 1
	return {
		x = linear % w,
		y = linear // w,
	}
end

local function posToIdx(pos, w)
	return math.floor(pos.y) * w + math.floor(pos.x) + 1
end

function init()
	mapRes = dofile(MAP_RES_PATH)
	assert(mapRes and mapRes.w and mapRes.h and mapRes.list, "load map_res failed")
	mapObj = MAP_BASE.clsMap:New({
		_width = mapRes.w,
		_height = mapRes.h,
	})
	local blockCnt = mapObj:loadBlockFromRes(mapRes)
	local w = mapRes.w
	local obstruct = CONST.MAP_CELL_TYPE.OBSTRUCT
	local obstacles = {}
	for idx = 1, #mapRes.list do
		if mapRes.list[idx][1] == obstruct then
			local pos = idxToPos(idx, w)
			obstacles[#obstacles + 1] = { pos.x, pos.y }
		end
	end
	navObj = navigation.new(w, mapRes.h, obstacles)
	skynet.error("world map init", mapRes.w, mapRes.h, "block", blockCnt)
end

function getMap()
	return mapObj
end

function isBlock(idx)
	return mapObj:isBlock(idx)
end

function findPath(fromIdx, toIdx)
	local w = mapObj:getWidth()
	local path = navObj:find_path(idxToPos(fromIdx, w), idxToPos(toIdx, w))
	local ret = {}
	for _, pos in ipairs(path or {}) do
		ret[#ret + 1] = posToIdx(pos, w)
	end
	return ret
end
