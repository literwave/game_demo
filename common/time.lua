TIME = {}

local offset = 0

function osBJSecByTbl(tbl)
	local ret = os.time(tbl)
	return ret
end

local TIME_BASE = osBJSecByTbl({year=2004,month=1,day=1,hour=0,min=0,sec=0,})

function osBJSec()
	return os.time() + offset
end

function getRelaDayNo(time)
	local totalDay = 0
	local Standard = TIME_BASE
	if not time then
		time = osBJSec()
	end
	assert(time > Standard)
	totalDay = time / CONST.ONE_HOUR_SEC / CONST.ONE_DAY_HOUR
	return math.floor(totalDay) + 1
end

function getDiffDay(time1, time2)
	local diff = math.abs(time1 - time2)
	return math.floor(diff / CONST.ONE_HOUR_SEC / CONST.ONE_DAY_HOUR) + 1
end