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
end
