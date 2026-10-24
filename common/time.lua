local skynet = require "skynet"

-- 时间戳都是 UTC 秒。切天和日期换算统一按北京时间（UTC+8），和服务器本机时区无关
local BJ_OFFSET = 8 * 3600

offset = 0

-- 公历日期距 1970-01-01 的天数。不用 os.time，它按本机时区和夏令时解释
local function days_from_civil(y, m, d)
	if m <= 2 then
		y = y - 1
	end
	local era = y // 400
	local yoe = y - era * 400
	local doy = (153 * ((m + 9) % 12) + 2) // 5 + d - 1
	local doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
	return era * 146097 + doe - 719468
end

-- 北京时间的 {year, month, day, hour, min, sec} -> 时间戳
function os_bj_sec_by_tbl(tbl)
	local days = days_from_civil(tbl.year, tbl.month, tbl.day)
	return days * 86400 + (tbl.hour or 0) * 3600 + (tbl.min or 0) * 60 + (tbl.sec or 0) - BJ_OFFSET
end

local TIME_BASE = os_bj_sec_by_tbl({year=2004,month=1,day=1,hour=0,min=0,sec=0,})

function os_bj_sec()
	return math.floor(skynet.time()) + offset
end

-- 带小数的秒，给地图帧用。os_bj_sec 是整秒，帧间隔比 1 秒短时不能用它当步长
function now()
	return skynet.time() + offset
end

-- 按北京时间格式化
function format(time, fmt)
	return os.date("!" .. (fmt or "%Y-%m-%d %H:%M:%S"), (time or os_bj_sec()) + BJ_OFFSET)
end

function add_offset(sec)
	offset = offset + sec
end

function reset_offset()
	offset = 0
end

-- 北京时间当天 0 点
function day_begin(time)
	return (get_rela_day_no(time) - 1) * CONST.ONE_DAY_SEC - BJ_OFFSET
end

-- 第 1 天（1970-01-01）是周四，补 3 天让周一做一周的开始
function get_rela_week_no(time)
	return (get_rela_day_no(time) - 1 + 3) // 7
end

-- 年 * 12 + 月（北京时间）
function get_rela_month_no(time)
	local date = os.date("!*t", (time or os_bj_sec()) + BJ_OFFSET)
	return date.year * 12 + date.month
end

-- 1 周一 ... 7 周日
function get_weekday(time)
	return (get_rela_day_no(time) - 1 + 3) % 7 + 1
end

-- 北京时间 1970-01-01 为第 1 天
function get_rela_day_no(time)
	if not time then
		time = os_bj_sec()
	end
	assert(time > TIME_BASE)
	return math.floor((time + BJ_OFFSET) / CONST.ONE_DAY_SEC) + 1
end

function get_diff_day(time1, time2)
	local diff = math.abs(time1 - time2)
	return math.floor(diff / CONST.ONE_HOUR_SEC / CONST.ONE_DAY_HOUR) + 1
end
