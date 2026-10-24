-- common/time.lua 按北京时间切天、换算日期，以及 user:touch_day 返回的跨天/跨周/跨月
-- 和本机时区无关：TZ=UTC 和 TZ=Asia/Shanghai 下结果应一样

local DAY = 86400

local function load_time()
	local env = setmetatable({}, {__index = _G})
	env.CONST = {ONE_DAY_SEC = DAY, ONE_HOUR_SEC = 3600, ONE_DAY_HOUR = 24}
	package.loaded.skynet = package.loaded.skynet or {time = os.time}
	assert(loadfile("common/time.lua", "t", env))()
	return env
end

local function load_user(time)
	local env = setmetatable({}, {__index = _G})
	env.TIME = time
	env.cls_object = {Inherit = function() return {} end}
	assert(loadfile("logic/service/agent/module/user/base.lua", "t", env))()
	local data = {_login_time = 0, _login_days = 0, _week_login_days = 0, _day_online_sec = 0}
	return setmetatable({_data = data}, {__index = env.cls_user}), data
end

local function bj(TIME, y, m, d, h, mi, s)
	return TIME.os_bj_sec_by_tbl({year = y, month = m, day = d, hour = h or 12, min = mi or 0, sec = s or 0})
end

local T = {}

function T.bj_tbl_to_ts()
	local TIME = load_time()
	-- 北京 2026-10-01 00:00 = UTC 2026-09-30 16:00
	assert(bj(TIME, 2026, 10, 1, 0) == 1790784000)
	assert(TIME.format(1790784000) == "2026-10-01 00:00:00")
end

function T.day_turns_at_bj_midnight()
	local TIME = load_time()
	local midnight = bj(TIME, 2026, 10, 1, 0)
	assert(TIME.get_rela_day_no(midnight - 1) + 1 == TIME.get_rela_day_no(midnight))
	assert(TIME.get_rela_day_no(midnight) == TIME.get_rela_day_no(midnight + DAY - 1))
	assert(TIME.day_begin(midnight + 3600 * 10) == midnight)
	-- 2026-10-01 周四
	assert(TIME.get_weekday(midnight) == 4)
	assert(TIME.get_rela_month_no(midnight - 1) + 1 == TIME.get_rela_month_no(midnight))
end

function T.month_no()
	local TIME = load_time()
	assert(TIME.get_rela_month_no(bj(TIME, 2026, 1, 31)) + 1 == TIME.get_rela_month_no(bj(TIME, 2026, 2, 1)))
	assert(TIME.get_rela_month_no(bj(TIME, 2026, 12, 31, 23, 59, 59)) + 1 == TIME.get_rela_month_no(bj(TIME, 2027, 1, 1, 0)))
	assert(TIME.get_rela_month_no(bj(TIME, 2026, 3, 1, 0)) == TIME.get_rela_month_no(bj(TIME, 2026, 3, 31, 23)))
end

function T.touch_day_cross()
	local TIME = load_time()
	local user, data = load_user(TIME)
	local cross = user:touch_day(bj(TIME, 2026, 10, 28))
	assert(cross and cross.week and cross.month, "first login counts as all")
	assert(user:touch_day(bj(TIME, 2026, 10, 28, 23, 59, 59)) == nil, "same day")
	-- 2026-10-28 周三 -> 10-29 周四 0 点：只跨天
	cross = user:touch_day(bj(TIME, 2026, 10, 29, 0))
	assert(cross and not cross.week and not cross.month)
	-- -> 11-02 周一：跨周跨月
	cross = user:touch_day(bj(TIME, 2026, 11, 2, 0))
	assert(cross and cross.week and cross.month)
	-- -> 11-09 周一：跨周不跨月
	cross = user:touch_day(bj(TIME, 2026, 11, 9))
	assert(cross and cross.week and not cross.month)
	assert(data._login_days == 4 and data._week_login_days == 1)
end

return T
