-- activity/rank/mgr.lua：zset 排名，同分先到的靠前，重启后从持久化分数重建

local MGR_FILE = "logic/service/activity/module/rank/mgr.lua"

local POWER = 1

local function setup(doc)
	local env = setmetatable({}, {__index = _G})
	local clock = {now = 1000}
	doc = doc or {_power_tbl = {}, _city_tbl = {}}
	env.DATA_COMMON = {RANK_TYPE = {POWER = 1, CITY_LEVEL = 2}}
	env.TIME = {os_bj_sec = function() return clock.now end}
	env.ORM = {load = function() return doc end}
	env.MONGO_SLAVE = {COL = {}, system_startup = function() end}
	assert(loadfile(MGR_FILE, "t", env))()
	env.__init__()
	return env, doc, clock
end

local T = {}

function T.higher_score_first()
	local M = setup()
	M.set_score(POWER, 1, 100)
	M.set_score(POWER, 2, 300)
	M.set_score(POWER, 3, 200)
	assert(M.get_rank(POWER, 2) == 1 and M.get_rank(POWER, 3) == 2 and M.get_rank(POWER, 1) == 3)
	assert(M.get_rank(POWER, 99) == 0, "not on board")
end

function T.tie_earlier_first_and_update_moves()
	local M, _, clock = setup()
	M.set_score(POWER, 1, 100)
	clock.now = 2000
	M.set_score(POWER, 2, 100)
	assert(M.get_rank(POWER, 1) == 1, "reached first ranks higher")
	clock.now = 3000
	M.set_score(POWER, 2, 150)
	assert(M.get_rank(POWER, 2) == 1 and M.get_rank(POWER, 1) == 2)
	M.set_score(POWER, 2, 0)
	assert(M.get_rank(POWER, 2) == 0 and M.get_rank(POWER, 1) == 1, "score 0 leaves board")
end

function T.rebuild_from_doc()
	local _, doc = setup()
	doc._power_tbl[1] = {_score = 100, _time = 5}
	doc._power_tbl[2] = {_score = 100, _time = 3}
	local M = setup(doc)
	assert(M.get_rank(POWER, 2) == 1 and M.get_rank(POWER, 1) == 2)
end

function T.rank_list_page_and_self()
	local M, _, clock = setup()
	for uid = 1, 5 do
		clock.now = clock.now + 1
		M.set_score(POWER, uid, uid * 100, "p" .. uid, uid)
	end
	local ret = M.get_rank_list(POWER, 2, 2, 1)
	assert(#ret.list == 2)
	assert(ret.list[1].rank == 2 and ret.list[1].uid == 4 and ret.list[1].name == "p4")
	assert(ret.list[2].rank == 3 and ret.list[2].uid == 3 and ret.list[2].head_icon == 3)
	assert(ret.self.rank == 5 and ret.self.score == 100)
	assert(#M.get_rank_list(POWER, 6, 10, 1).list == 0, "start past the end")
	assert(#M.get_rank_list(POWER, 4, 10, 1).list == 2, "page cut at the end")
	local outsider = M.get_rank_list(POWER, 1, 10, 99).self
	assert(outsider.rank == 0 and outsider.score == 0 and outsider.uid == 99)
end

function T.name_kept_when_score_changes()
	local M = setup()
	M.set_score(POWER, 1, 100, "old", 1)
	M.set_score(POWER, 1, 100, "new", 2)
	M.set_score(POWER, 1, 200)
	local item = M.get_rank_list(POWER, 1, 1, 1).list[1]
	assert(item.name == "new" and item.head_icon == 2 and item.score == 200)
end

return T
