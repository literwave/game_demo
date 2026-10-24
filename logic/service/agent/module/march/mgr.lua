local skynet = require "skynet"

function world_call(cmd, ...)
	local addr = skynet.localname(".world")
	if not addr then
		return
	end
	return skynet.call(addr, "lua", cmd, ...)
end

local function begin_march(user, troop, target_type, target_id, ex, ey)
	local now = TIME.os_bj_sec()
	local sx, sy
	if troop:get_march_state() == 0 then
		sx, sy = user:get_birth_x(), user:get_birth_y()
	else
		sx, sy = troop:calc_pos(now)
	end
	local path = world_call("find_march_path", sx, sy, ex, ey)
	if not path then
		return false
	end
	local cost = math.max(1, math.ceil(MARCH_PATH.length(path) / CONST.MARCH_SPEED))
	troop:set_march({
		state = CONST.MARCH_STATE.MOVING,
		target_type = target_type,
		target_id = target_id,
		path = path,
		start_time = now,
		end_time = now + cost,
	})
	local ok = world_call("start_march", troop:get_march_info())
	if not ok then
		troop:clear_march()
		return false
	end
	return true
end

local function begin_return(user, troop)
	if not user:has_birth_pos() then
		return false
	end
	return begin_march(user, troop, DATA_COMMON.TARGET_TYPE.RETURN_CITY, 0, user:get_birth_x(), user:get_birth_y())
end

function on_arrive(user_id, troop_idx, end_time)
	local user = USER_MGR.try_init_user(user_id)
	local troop = TROOP_MGR.get_troop(user_id, troop_idx)
	if not troop or troop:get_march_state() ~= CONST.MARCH_STATE.MOVING then
		return
	end
	if end_time and end_time ~= troop:get_end_time() then
		return
	end
	if TIME.os_bj_sec() + 1 < troop:get_end_time() then
		return
	end
	local fd = USER_MGR.get_fd_by_user_id(user_id)
	if troop:get_target_type() == DATA_COMMON.TARGET_TYPE.ATTACK_MONSTER then
		troop:set_arrived()
		BATTLE_MGR.attack_monster(user, troop)
		if begin_return(user, troop) and fd then
			for_caller.s2c_sync_march(fd, {marchInfo = troop:get_march_pto()})
		end
		return
	end
	local pto = troop:get_march_pto()
	pto.state = CONST.MARCH_STATE.ARRIVED
	troop:clear_march()
	world_call("remove_troop", user_id, troop_idx)
	if fd then
		for_caller.s2c_sync_march(fd, {marchInfo = pto})
	end
end

function on_aoi_push(fd, pack)
	if not fd or not pack then
		return
	end
	if pack.enter and #pack.enter > 0 then
		for_caller.s2c_aoi_enter(fd, {entities = pack.enter})
	end
	if pack.leave and #pack.leave > 0 then
		for_caller.s2c_aoi_leave(fd, {entityIds = pack.leave})
	end
	if pack.update and #pack.update > 0 then
		for_caller.s2c_aoi_update(fd, {entities = pack.update})
	end
end

function on_user_login(user_id)
	local user = USER_MGR.try_init_user(user_id)
	if user:has_birth_pos() then
		world_call("upsert_city", user_id, user:get_birth_x(), user:get_birth_y())
	end
	local now = TIME.os_bj_sec()
	for _, troop in pairs(TROOP_MGR.get_user_troops(user_id)) do
		local state = troop:get_march_state()
		if state == CONST.MARCH_STATE.MOVING then
			if now >= troop:get_end_time() then
				on_arrive(user_id, troop:get_troop_idx(), troop:get_end_time())
			else
				world_call("start_march", troop:get_march_info())
			end
		elseif state == CONST.MARCH_STATE.ARRIVED and troop:get_target_type() == DATA_COMMON.TARGET_TYPE.ATTACK_MONSTER then
			if begin_return(user, troop) then
				local fd = user:get_fd()
				if fd then
					for_caller.s2c_sync_march(fd, {marchInfo = troop:get_march_pto()})
				end
			end
		elseif state == CONST.MARCH_STATE.ARRIVED then
			troop:clear_march()
			world_call("remove_troop", user_id, troop:get_troop_idx())
		end
	end
end

local function on_march(fd, packet)
	local user = USER_MGR.get_user_by_fd(fd)
	if not user or not user:has_birth_pos() then
		return
	end
	local user_id = user:get_user_id()
	local troop = TROOP_MGR.get_troop(user_id, packet.troopIdx)
	if not troop or not troop:has_hero() then
		return
	end
	if troop:get_march_state() == CONST.MARCH_STATE.MOVING then
		USER_MGR.tell_me(user_id, "部队正在行军")
		return
	end
	local ex, ey, target_id
	if packet.targetType == DATA_COMMON.TARGET_TYPE.ATTACK_MONSTER then
		local pos = world_call("monster_pos", packet.targetId)
		if not pos then
			USER_MGR.tell_me(user_id, "目标不存在")
			return
		end
		ex, ey = pos.x, pos.y
		target_id = packet.targetId
	elseif packet.targetType == DATA_COMMON.TARGET_TYPE.RETURN_CITY then
		ex, ey = user:get_birth_x(), user:get_birth_y()
		target_id = 0
	else
		return
	end
	if not begin_march(user, troop, packet.targetType, target_id, ex, ey) then
		USER_MGR.tell_me(user_id, "目标无法到达")
		return
	end
	for_caller.s2c_march(fd, {marchInfo = troop:get_march_pto()})
	if packet.targetType == DATA_COMMON.TARGET_TYPE.ATTACK_MONSTER then
		EVENT.dispatch(CONST.EVENT.ON_MARCH, user_id, 1)
	end
end

local function on_cancel_march(fd, packet)
	local user = USER_MGR.get_user_by_fd(fd)
	if not user then
		return
	end
	local troop = TROOP_MGR.get_troop(user:get_user_id(), packet.troopIdx)
	if not troop or troop:get_march_state() ~= CONST.MARCH_STATE.MOVING then
		return
	end
	if troop:get_target_type() == DATA_COMMON.TARGET_TYPE.RETURN_CITY then
		return
	end
	if not begin_return(user, troop) then
		return
	end
	for_caller.s2c_cancel_march(fd, {
		troopIdx = packet.troopIdx,
		marchInfo = troop:get_march_pto(),
	})
end

local function on_req_march_list(fd)
	local user_id = USER_MGR.get_user_id_by_fd(fd)
	if not user_id then
		return
	end
	local march_list = {}
	for _, troop in pairs(TROOP_MGR.get_user_troops(user_id)) do
		if troop:get_march_state() ~= 0 then
			march_list[#march_list + 1] = troop:get_march_pto()
		end
	end
	for_caller.s2c_req_march_list(fd, {marchList = march_list})
end

local function on_aoi_focus(fd, packet)
	local user_id = USER_MGR.get_user_id_by_fd(fd)
	if not user_id or not packet.pos then
		return
	end
	local diff = world_call("aoi_focus", user_id, packet.pos.x, packet.pos.y)
	if not diff then
		return
	end
	on_aoi_push(fd, diff)
end

function __init__()
	for_maker.c2s_march = on_march
	for_maker.c2s_cancel_march = on_cancel_march
	for_maker.c2s_req_march_list = on_req_march_list
	for_maker.c2s_aoi_focus = on_aoi_focus
	EVENT.listen(CONST.EVENT.ON_USER_LOGIN)
end
