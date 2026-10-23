local skynet = require "skynet"

offset = 0

function os_bj_sec_by_tbl(tbl)
	local ret = os.time(tbl)
	return ret
end

local TIME_BASE = os_bj_sec_by_tbl({year=2004,month=1,day=1,hour=0,min=0,sec=0,})

function os_bj_sec()
	return math.floor(skynet.time()) + offset
end

function add_offset(sec)
	offset = offset + sec
end

function reset_offset()
	offset = 0
end

function get_rela_day_no(time)
	local Standard = TIME_BASE
	if not time then
		time = os_bj_sec()
	end
	assert(time > Standard)
	local total_day = time / CONST.ONE_HOUR_SEC / CONST.ONE_DAY_HOUR
	return math.floor(total_day) + 1
end

function get_diff_day(time1, time2)
	local diff = math.abs(time1 - time2)
	return math.floor(diff / CONST.ONE_HOUR_SEC / CONST.ONE_DAY_HOUR) + 1
end