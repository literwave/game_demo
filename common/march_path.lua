-- 行军路径：拐点列表 {{_x, _y}, ...}，含起点和终点。整条路按路程匀速走
-- agent 的部队和 world 的 AOI 实体都用这里算位置，保证两边一致

local function seg_len(a, b)
	local dx = b._x - a._x
	local dy = b._y - a._y
	return math.sqrt(dx * dx + dy * dy)
end

function length(path)
	local total = 0
	for i = 2, #path do
		total = total + seg_len(path[i - 1], path[i])
	end
	return total
end

function first_pos(path)
	local p = path[1]
	if not p then
		return 0, 0
	end
	return p._x, p._y
end

function last_pos(path)
	local p = path[#path]
	if not p then
		return 0, 0
	end
	return p._x, p._y
end

function pos_at(path, start_time, end_time, now)
	if now <= start_time then
		return first_pos(path)
	end
	if now >= end_time then
		return last_pos(path)
	end
	local walk = length(path) * (now - start_time) / (end_time - start_time)
	for i = 2, #path do
		local a, b = path[i - 1], path[i]
		local len = seg_len(a, b)
		if walk <= len then
			local rate = len > 0 and walk / len or 0
			return a._x + (b._x - a._x) * rate, a._y + (b._y - a._y) * rate
		end
		walk = walk - len
	end
	return last_pos(path)
end

-- 转成不带 orm 元表的纯 table，跨服务传
function copy(path)
	local ret = {}
	for i, p in ipairs(path) do
		ret[i] = {_x = p._x, _y = p._y}
	end
	return ret
end
