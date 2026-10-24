all_user_queue_tbl = {}
--[[
	[userId] = {
		[queueIdx] = obj,
	}
]]

function ref_queue(queue_obj)
	local user_id = queue_obj:get_user_id()
	local queue_idx = queue_obj:get_queue_idx()
	if not all_user_queue_tbl[user_id] then
		all_user_queue_tbl[user_id] = {}
	end
	all_user_queue_tbl[user_id][queue_idx] = queue_obj
end

function unref_queue(work_queue_obj)
	local user_id = work_queue_obj:get_user_id()
	local queue_idx = work_queue_obj:get_queue_idx()
	if all_user_queue_tbl[user_id] then
		all_user_queue_tbl[user_id][queue_idx] = nil
		if table.is_empty(all_user_queue_tbl[user_id]) then
			all_user_queue_tbl[user_id] = nil
		end
	end
end

local function create_queue(oci)
	return QUEUE_BASE.cls_queue:New(oci)
end

local function try_init_user_queues(user_id)
	local doc, is_loaded = ORM.load(MONGO_SLAVE.COL.QUEUE, user_id, ORM.CLS_USER_QUEUE_DOC)
	if is_loaded then
		all_user_queue_tbl[user_id] = {}
		for _, queue_data in pairs(doc._queues) do
			create_queue(queue_data)
		end
	end
	return all_user_queue_tbl[user_id]
end

function load_data()
end

function save_data()
	MONGO_SLAVE.flush()
end

function system_startup()
	local offset_time = TIME.os_bj_sec() - GAME.get_shut_down_time()
	if offset_time <= 0 then
		return
	end
	for _, queue_info_tbl in pairs(all_user_queue_tbl) do
		for _, queue_obj in pairs(queue_info_tbl) do
			queue_obj:system_startup(offset_time)
		end
	end
end

local function init_user_queue(user_id)
	try_init_user_queues(user_id)
	if get_user_queue(user_id, CONST.FIRST_QUEUE_IDX) then
		return
	end
	local oci = {
		_user_id = user_id,
		_queue_idx = CONST.FIRST_QUEUE_IDX,
	}
	create_queue(oci)
end

function on_user_login(user_id, _, _, is_first_login)
	if not is_first_login then
		try_init_user_queues(user_id)
		return
	end
	init_user_queue(user_id)
end

function sync_all_queue_info_to_client(user_id)
	local fd = USER_MGR.get_fd_by_user_id(user_id)
	if not fd then
		return
	end
	local all_work_queue_tbl = get_user_all_queue_tbl(user_id)
	local list = {}
	for _, queue_obj in pairs(all_work_queue_tbl or EMPTY_TABLE) do
		table.insert(list, queue_obj:gen_client_pto_info())
	end
	for_caller.s2c_sync_all_queue_info(fd, {list = list})
end

function sync_queue_info_to_client(queue_obj)
	local user_id = queue_obj:get_user_id()
	local fd = USER_MGR.get_fd_by_user_id(user_id)
	if fd then
		for_caller.s2c_sync_queue_info(fd, queue_obj:gen_client_pto_info())
	end
end

local function try_update_user_queue(user_id)
	local need_sync_to_client = false
	for _, queue_obj in pairs(all_user_queue_tbl[user_id] or {}) do
		if queue_obj:check_is_expired() then
			need_sync_to_client = queue_obj:on_expired()
		end
	end
	if need_sync_to_client then
		sync_all_queue_info_to_client(user_id)
	end
end

function get_user_all_queue_tbl(user_id)
	try_init_user_queues(user_id)
	try_update_user_queue(user_id)
	return all_user_queue_tbl[user_id]
end

function get_user_queue_tbl(user_id)
	return get_user_all_queue_tbl(user_id)
end

function get_user_queue(user_id, queue_idx)
	local queue_tbl = get_user_queue_tbl(user_id)
	return queue_tbl and queue_tbl[queue_idx]
end

function create_user_queue(user_id, queue_idx, expire_time)
	if get_user_queue(user_id, queue_idx) then
		return
	end
	local oci = {
		_user_id = user_id,
		_queue_idx = queue_idx,
		_expire_time = expire_time,
	}
	create_queue(oci)
end

function get_idle_build_queue(user_id, target_id)
	for _, queue_idx in ipairs(CONST.QUEUE_PRIORITY) do
		local queue_obj = get_user_queue(user_id, queue_idx)
		if queue_obj and queue_obj:check_can_add_new_work(target_id) then
			return queue_obj
		end
	end
end

function check_work_is_exist(user_id, target_id)
	local queue_tbl = get_user_queue_tbl(user_id)
	if not queue_tbl then
		return false
	end
	for _, queue_obj in pairs(queue_tbl) do
		if queue_obj:check_target_is_in_queue(target_id) then
			return true
		end
	end
	return false
end

function check_can_add_new_work(user_id, target_id)
	local is_exist = check_work_is_exist(user_id, target_id)
	if is_exist then
		return false, 350044
	end
	local queue_obj = get_idle_build_queue(user_id, target_id)
	if not queue_obj then
		return false, 350144
	end
	return true, nil
end

function get_target_work_queue_info(user_id, target_id)
	local queue_tbl = get_user_queue_tbl(user_id)
	if not queue_tbl then
		return
	end
	for _, queue_obj in pairs(queue_tbl) do
		local is_exist, queue_idx = queue_obj:check_target_is_in_queue(target_id)
		if is_exist then
			return queue_tbl, queue_idx
		end
	end
	return false
end

function try_add_new_work(user_id, target_id, cancel_reward_list)
	local ret, msg_id = check_can_add_new_work(user_id, target_id)
	if not ret then
		return false, msg_id
	end
	local queue_obj = get_idle_build_queue(user_id, target_id)
	queue_obj:add_new_work(target_id, cancel_reward_list)
	local start_queue_idx, start_target_id = queue_obj:try_start_work()
	queue_obj:after_start_work(start_queue_idx, start_target_id)
	sync_queue_info_to_client(queue_obj)
	return true
end

function try_remove_work(user_id, queue_idx, target_id)
	if not queue_idx then
		return
	end
	local queue_obj = get_user_queue(user_id, queue_idx)
	if not queue_obj then
		return
	end
	queue_obj:on_work_finish(target_id)
	local start_queue_idx, start_target_id = queue_obj:try_start_work()
	queue_obj:after_start_work(start_queue_idx, start_target_id)
	sync_queue_info_to_client(queue_obj)
end

local function on_req_buy_queue(fd, tbl)
	local buy_queue_idx, buy_cnt = tbl.buy_queue_idx, tbl.buy_cnt
	if buy_cnt <= 0 then
		return
	end
	local queue_tbl = DATA_COMMON.get_value_by_key(1)
	local queue_buy_info = queue_tbl[buy_queue_idx]
	if not queue_buy_info then
		return
	end
	local _, cost_yb = table.unpack(queue_buy_info)
	local user_id = USER_MGR.get_user_id_by_fd(fd)
	local user = USER_MGR.get_user_by_fd(fd)
	if not user:check_can_use_diamond(cost_yb * buy_cnt) then
		return
	end
	user:sub_diamond_and_sync(cost_yb * buy_cnt, {CONST.FLOW_REASON.BUY_BUILD_QUEUE, buy_cnt})
	local queue = get_user_queue(user_id, buy_queue_idx)
	if queue then
		local expire_time = queue:get_expire_time()
		queue:set_expire_time(expire_time + CONST.ONE_HOUR_SEC * buy_cnt)
	else
		create_user_queue(user_id, buy_queue_idx, TIME.os_bj_sec() + CONST.ONE_HOUR_SEC * buy_cnt)
	end
	sync_all_queue_info_to_client(user_id)
	for_caller.s2c_buy_build_queue(fd, {buy_queue_idx = buy_queue_idx, buy_cnt = buy_cnt})
end

local function on_req_all_work_queue_info(fd)
	local user_id = USER_MGR.get_user_id_by_fd(fd)
	sync_all_queue_info_to_client(user_id)
end

local function on_cancel_build_work(fd, tbl)
	local work_idx, queue_idx = tbl.idx, tbl.queue_idx
	local user_id = USER_MGR.get_user_id_by_fd(fd)
	local queue_obj = get_user_queue(user_id, queue_idx)
	if not queue_obj then
		return
	end
	if queue_obj:get_work_idx() == work_idx then
		return
	end
	if not queue_obj:on_cancel(work_idx) then
		return
	end
	sync_queue_info_to_client(queue_obj)
end

function __init__()
	for_maker.c2s_buy_build_queue = on_req_buy_queue
	for_maker.c2s_req_all_queue_info = on_req_all_work_queue_info
	for_maker.c2s_cancel_build_work = on_cancel_build_work
	EVENT.listen(CONST.EVENT.ON_USER_LOGIN)
end
