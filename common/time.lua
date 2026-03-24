TIME = {}

local offset = 0

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