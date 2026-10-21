all_user_tbl = {
	-- [userId] = userObj
}
fd_to_user_id = {
	-- [vfd] = userId
}
user_id_to_fd = {
	-- [userId] = vfd
}

function tell_me_by_language_id(user_id, ...)
	local fd = user_id_to_fd[user_id]
	if fd then
		local tbl = table.val_to_number({...})
		for_caller.s2c_sys_notify_by_lanid(fd, {tbl = tbl})
	end
end

function tell_me(user_id, msg)
	local fd = user_id_to_fd[user_id]
	if not fd then
		return
	end
	if type(msg) == "string" then
		msg = { msg = msg }
	end
	for_caller.s2c_tell_me(fd, msg)
end

function get_user_by_id(user_id)
	return all_user_tbl[user_id]
end

function get_user_id_by_vfd(fd)
	return fd_to_user_id[fd]
end

function del_user_id_by_vfd(fd)
	fd_to_user_id[fd] = nil
end

function get_fd_by_user_id(user_id)
	return user_id_to_fd[user_id]
end

function get_user_by_fd(fd)
	local user_id = fd_to_user_id[fd]
	return all_user_tbl[user_id]
end

function get_user_id_by_fd(fd)
	return fd_to_user_id[fd]
end

function get_gate_srv_by_fd(fd)
	local user = get_user_by_fd(fd)
	local gate_srv = user:get_gate_srv()
	return gate_srv
end

local function module_on_user_logout(user_id)
	BUILD_MGR.on_user_logout(user_id)
	TROOP_MGR.on_user_logout(user_id)
end

function disconnect(fd, user_id)
	local user = get_user_by_id(user_id)
	MONGO_SLAVE.flush()
	all_user_tbl[user_id] = nil
	del_user_id_by_vfd(fd)
	user_id_to_fd[user_id] = nil
	module_on_user_logout(user_id)
end

function is_new_user(user_id)
	local user = all_user_tbl[user_id]
	local is_new_user = false
	if not user then
		local save_tbl = MONGO_SLAVE.common_load_single(MONGO_SLAVE.COL.USER_INFO, user_id) or {}
		if table.is_empty(save_tbl) then
			is_new_user = true
		end
	end
	return is_new_user
end

function try_init_user(user_id)
	local user = all_user_tbl[user_id]
	if not user then
		local save_tbl = MONGO_SLAVE.common_load_single(MONGO_SLAVE.COL.USER_INFO, user_id) or {}
		user = USER_BASE.cls_user:New(save_tbl)
		all_user_tbl[user_id] = user
	end
	return user
end

function ref_login(user_id, fd, user)
	user_id_to_fd[user_id] = fd
	fd_to_user_id[fd] = user_id
	all_user_tbl[user_id] = user
end

function get_game_user_id()
	return MONGO_SLAVE.fetch_user_id()
end

function create_new_user(gate_srv, fd, user_id, server_id)
	local oci = {
		_user_id = user_id,
		_birth_time = os.time(),
		_born_server_id = server_id,
		_name = CONST.NO_NAME,
		_sex = CONST.SEX_NONE,
		_head_icon = DATA_COMMON.get_value_by_key(2),
	}
	local user = USER_BASE.cls_user:New(oci)
	ref_login(user_id, fd, user)
	-- user:setFd(fd)
	-- print("gateSrv", gateSrv)
	-- user:setGateSrv(gateSrv)
	-- local userName = RANDOM_NAME.genNewUserName()
	-- user:setName(userName)
	ORM.touch(user._data)
	user:set_fd(fd)
	user:set_gate_srv(gate_srv)
	-- WORK_QUEUE_MGR.initUserWorkQueue(userId)
	REWARD_MGR.reward_user(user_id, DATA_COMMON.get_value_by_key(1))
	return user
	-- USER_MGR.updateUserPower(userId, CONST.POWER_TYPE.HERO)
end

function module_on_user_login(user, is_first_login)
	user:on_login()
	BUILD_MGR.on_user_login(user, is_first_login)
	QUEUE_MGR.on_user_login(user, is_first_login)
end

function module_on_user_next_day(user_id, times)
	times = times or 1
end

function kick_user(fd, user_id)
	disconnect(fd)
end

function detect_user_heart_beat(user_id)
	local user = all_user_tbl[user_id]
	if not user then
		return
	end
	local last_heart_beat_time = user:get_heart_beat_time()
	if os.time() - last_heart_beat_time > CONST.USER_HEART_BEAT_TIMEOUT then
		local fd = get_fd_by_user_id(user_id)
		EVENT.emit(CONST.EVENT.KICK_USER, fd, user_id)
	end
end

local function on_heart_beat(fd)
	local user = USER_MGR.get_user_by_fd(fd)
	user:set_heart_beat_time(os.time())
end

local function on_user_baseinfo(fd)
	local user = USER_MGR.get_user_by_fd(fd)
	user:sync_user_base_info()
end

local function on_user_create(fd, packet)
	local sex = packet.sex
	local name = packet.name
	if sex < CONST.SEX_MAN or sex > CONST.SEX_WOMAN then
		return
	end
	local user = USER_MGR.get_user_by_fd(fd)
	if user:get_sex() ~= CONST.SEX_NONE then
		return
	end
	user:set_sex(sex)
	user:set_name(name)
	for_caller.s2c_user_create(fd, packet)
end

function __init__()
	for_maker.c2s_heart_beat = on_heart_beat
	for_maker.c2s_user_base_info = on_user_baseinfo
	for_maker.c2s_user_create = on_user_create
	EVENT.register(CONST.EVENT.KICK_USER)
end