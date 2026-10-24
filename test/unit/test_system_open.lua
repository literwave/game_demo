-- system_open/mgr.lua：按 SystemOpen.Cond 自动开系统

local SYSTEM_OPEN = {}
for _, row in ipairs(dofile("game_common/server/res/SystemOpen.lua")) do
	SYSTEM_OPEN[row.Id] = row
end

local function setup(level)
	local env = setmetatable({}, {__index = _G})
	local opened = {}
	local events = {}
	local user = {
		level = level,
		get_level = function(self) return self.level end,
		get_user_id = function() return 1 end,
		get_fd = function() return nil end,
		is_system_open = function(_, id) return opened[id] ~= nil end,
		set_system_open = function(_, id) opened[id] = true end,
	}
	env.EMPTY_TABLE = {}
	env.CONST = {EVENT = {ON_SYSTEM_OPEN = "on_system_open"}}
	env.DATA_COMMON = {get_system_open_tbl = function() return SYSTEM_OPEN end}
	env.EVENT = {emit = function(_, _, id) events[#events + 1] = id end}
	env.USER_MGR = {try_init_user = function() return user end}
	assert(loadfile("logic/service/agent/module/system_open/mgr.lua", "t", env))()
	return env, user, opened, events
end

local T = {}

function T.open_by_level()
	local M, user, opened, events = setup(1)
	M.check_open(user)
	assert(opened[1] and not opened[2], "HEAD_ICON lv1 open, CREATE_ALLIANCE lv5 not yet")
	user.level = 5
	M.on_user_level(1)
	assert(opened[2])
	assert(#events == 2, "each system emits once")
	M.on_user_login(1)
	assert(#events == 2, "already open ones are not emitted again")
end

return T
