local function sync_one(user, system_id)
	local fd = user:get_fd()
	if not fd then
		return
	end
	for_caller.s2c_sync_system_open(fd, {
		systemId = system_id,
	})
end

function get_open_list(user)
	local list = {}
	local open_tbl = user:get_system_open_tbl()
	if not open_tbl then
		return list
	end
	for system_id, open_time in pairs(open_tbl) do
		if open_time then
			list[#list + 1] = system_id
		end
	end
	return list
end

-- 返回 true 表示本次新开启；已开启的不重复发事件
function open_system(user, system_id)
	if user:is_system_open(system_id) then
		return false
	end
	user:set_system_open(system_id)
	EVENT.emit(CONST.EVENT.ON_SYSTEM_OPEN, user:get_user_id(), system_id)
	sync_one(user, system_id)
	return true
end

local COND_CHECK = {
	level = function(user, need)
		return user:get_level() >= need
	end,
}

-- Cond 是 { {level = 5}, ... }，全部满足才开；不认识的条件不开
local function cond_ok(user, cond_list)
	for _, cond in ipairs(cond_list or EMPTY_TABLE) do
		for key, need in pairs(cond) do
			local check = COND_CHECK[key]
			if not check or not check(user, need) then
				return false
			end
		end
	end
	return true
end

-- 单个条件表，如资源地的 OpenCond = {level = 1}
function is_cond_ok(user, cond)
	return cond_ok(user, {cond})
end

-- 按 Cond 把满足条件的系统都开了
function check_open(user)
	for system_id, conf in pairs(DATA_COMMON.get_system_open_tbl()) do
		if not user:is_system_open(system_id) and cond_ok(user, conf.Cond) then
			open_system(user, system_id)
		end
	end
end

function on_user_login(user_id)
	check_open(USER_MGR.try_init_user(user_id))
end

function on_user_level(user_id)
	check_open(USER_MGR.try_init_user(user_id))
end

-- 返回本次新开启的数量
function open_all(user)
	local cnt = 0
	for system_id in pairs(DATA_COMMON.get_system_open_tbl()) do
		if open_system(user, system_id) then
			cnt = cnt + 1
		end
	end
	return cnt
end

function sync_all(user)
	local fd = user:get_fd()
	if fd then
		for_caller.s2c_req_system_open(fd, {
			systemIdList = get_open_list(user),
		})
	end
end

local function on_req_system_open(fd)
	local user = USER_MGR.get_user_by_fd(fd)
	if not user then
		return
	end
	for_caller.s2c_req_system_open(fd, {
		systemIdList = get_open_list(user),
	})
end

function __init__()
	for_maker.c2s_req_system_open = on_req_system_open
	EVENT.listen(CONST.EVENT.ON_USER_LOGIN)
	EVENT.listen(CONST.EVENT.ON_USER_LEVEL)
end
