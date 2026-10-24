-- task/mgr.lua：状态类条件接取时 get 当前值，累加类条件从 0 开始按事件增量加
-- 依赖都换成假的，只加载 mgr.lua 本身

local MGR_FILE = "logic/service/agent/module/task/mgr.lua"

local MAIN_LOTTERY = 1001
local MAIN_BUILD = 1002
local DAILY_LOTTERY = 2001
local DAILY_LOGIN = 2002

local CONF = {
	[MAIN_LOTTERY] = {Cond = {type = 4}, Target = 2, NextId = MAIN_BUILD, Reward = {}},
	[MAIN_BUILD] = {Cond = {type = 2, bid = 1}, Target = 3, Reward = {}},
	[DAILY_LOTTERY] = {Cond = {type = 4}, Target = 1, Reward = {}},
	[DAILY_LOGIN] = {Cond = {type = 1}, Target = 1, Reward = {}},
}

local TYPE = {[MAIN_LOTTERY] = 1, [MAIN_BUILD] = 1, [DAILY_LOTTERY] = 2, [DAILY_LOGIN] = 2}

local function setup()
	local env = setmetatable({}, {__index = _G})
	local clock = {day = 100}
	local user = {login_days = 1, login_today = true, build_lv = 2, synced = {}, rewarded = {}}
	function user:get_user_id() return 1 end
	function user:get_fd() return 9 end
	function user:get_login_days() return self.login_days end
	function user:is_login_today() return self.login_today end
	function user:get_week_login_days() return self.login_days end
	function user:get_power() return 0 end

	local doc = {_tasks = {}, _reset_time = 0, _main_id = 0}
	env.EMPTY_TABLE = {}
	env.CONST = {
		TASK_TYPE = {MAIN = 1, DAILY = 2, WEEK = 3},
		TASK_STATE = {DOING = 0, CAN_GET = 1, GOT = 2},
		TASK_COND = {LOGIN = 1, BUILD_LV = 2, HERO_CNT = 3, LOTTERY = 4, HEAD_ICON = 5, OWN_ITEM = 6, MARCH = 7, POWER = 8},
		FLOW_REASON = {TASK = 7},
		EVENT = {},
	}
	local function now() return clock.day * 86400 + 100 end
	env.TIME = {
		os_bj_sec = now,
		get_rela_day_no = function(t) return (t or now()) // 86400 end,
		get_rela_week_no = function(t) return (t or now()) // (86400 * 70) end,
	}
	env.DATA_COMMON = {
		get_task_conf = function(id) return CONF[id] end,
		get_task_type = function(id) return TYPE[id] end,
		get_main_task_head = function() return MAIN_LOTTERY end,
		get_daily_task_tbl = function() return {[DAILY_LOTTERY] = CONF[DAILY_LOTTERY], [DAILY_LOGIN] = CONF[DAILY_LOGIN]} end,
		get_week_task_tbl = function() return {} end,
	}
	env.USER_MGR = {
		try_init_user = function() return user end,
		get_user_by_fd = function() return user end,
	}
	env.BUILD_MGR = {
		get_build_by_bid = function()
			return {get_level = function() return user.build_lv end}
		end,
	}
	env.ORM = {load = function() return doc, false end, get = function() return doc end}
	env.MONGO_SLAVE = {COL = {}, flush = function() end}
	env.REWARD_MGR = {reward_user_and_show = function(_, list) user.rewarded[#user.rewarded + 1] = list end}
	env.EVENT = {listen = function() end}
	env.for_maker = {}
	env.for_caller = {
		s2c_sync_task = function(_, pto) user.synced[#user.synced + 1] = pto.taskInfo end,
		s2c_get_task_reward = function() end,
		s2c_req_task_list = function() end,
	}
	assert(loadfile(MGR_FILE, "t", env))()
	env.__init__()
	return env, user, doc, clock
end

local T = {}

function T.login_creates_main_and_daily()
	local M, _, doc = setup()
	M.on_user_login(1)
	assert(doc._main_id == MAIN_LOTTERY)
	assert(doc._tasks[MAIN_LOTTERY] and doc._tasks[DAILY_LOTTERY] and doc._tasks[DAILY_LOGIN])
	assert(doc._tasks[DAILY_LOGIN]._state == 1, "login get on accept")
	assert(doc._tasks[MAIN_LOTTERY]._progress == 0, "count cond starts at 0")
end

function T.lottery_adds_delta()
	local M, _, doc = setup()
	M.on_user_login(1)
	M.on_lottery(1, 1)
	assert(doc._tasks[MAIN_LOTTERY]._progress == 1)
	assert(doc._tasks[DAILY_LOTTERY]._state == 1)
	M.on_lottery(1, 3)
	assert(doc._tasks[MAIN_LOTTERY]._progress == 4)
end

function T.daily_rollover_resets_before_delta()
	local M, _, doc, clock = setup()
	M.on_user_login(1)
	M.on_lottery(1, 5)
	clock.day = 101
	M.on_lottery(1, 1)
	local daily = doc._tasks[DAILY_LOTTERY]
	assert(daily._progress == 1 and daily._state == 1, "new day only counts today's lottery")
	assert(doc._tasks[MAIN_LOTTERY]._progress == 6, "main keeps accumulating")
end

function T.claim_main_accepts_next_with_get()
	local M, user, doc = setup()
	M.on_user_login(1)
	M.on_lottery(1, 2)
	M.for_maker.c2s_get_task_reward(9, {taskId = MAIN_LOTTERY})
	assert(doc._main_id == MAIN_BUILD)
	assert(doc._tasks[MAIN_LOTTERY] == nil)
	assert(doc._tasks[MAIN_BUILD]._progress == 2, "build level got on accept")
	assert(#user.rewarded == 1)
	user.build_lv = 3
	M.on_build_level(1, 1)
	assert(doc._tasks[MAIN_BUILD]._state == 1)
end

function T.claim_rejected_when_not_done()
	local M, user, doc = setup()
	M.on_user_login(1)
	M.for_maker.c2s_get_task_reward(9, {taskId = MAIN_LOTTERY})
	assert(doc._main_id == MAIN_LOTTERY and #user.rewarded == 0)
end

return T
