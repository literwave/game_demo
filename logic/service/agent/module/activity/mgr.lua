local skynet = require "skynet"

local function call_rank(cmd, ...)
	local addr = skynet.localname(".activity")
	if not addr then
		return
	end
	return skynet.call(addr, "lua", cmd, ...)
end

local function load_doc(user_id)
	return ORM.load(MONGO_SLAVE.COL.USER_ACTIVITY, user_id, ORM.CLS_USER_ACTIVITY_DOC)
end

local function act_of(doc, activity_id)
	local act = doc._acts[activity_id]
	if not act then
		doc._acts[activity_id] = {
			_activity_id = activity_id,
			_progress = 0,
			_day_no = 0,
		}
		act = doc._acts[activity_id]
	end
	return act
end

local function clear_map(map_obj)
	local keys = {}
	for key in pairs(map_obj) do
		keys[#keys + 1] = key
	end
	for _, key in ipairs(keys) do
		map_obj[key] = nil
	end
end

local function user_level(user)
	local lv = user:get_level()
	if lv < 1 then
		lv = 1
	end
	return lv
end

local function level_ok(user, conf)
	local need = 1
	if conf.OpenCond and conf.OpenCond.level then
		need = conf.OpenCond.level
	end
	return user_level(user) >= need
end

-- weekday：1 是周一。返回 open, ended, start, endt
local function time_window(conf, now, open_time)
	local time_conf = conf.Time or {}
	local kind = time_conf.type
	if kind == nil or kind == CONST.ACTIVITY_TIME.ALWAYS then
		return true, false, 0, 0
	end
	if kind == CONST.ACTIVITY_TIME.OPEN_DAY then
		local open_idx = TIME.get_rela_day_no(now) - TIME.get_rela_day_no(open_time) + 1
		local start_day = time_conf.open_day or 1
		local duration = time_conf.duration or 0
		local start_time = TIME.day_begin(open_time) + (start_day - 1) * CONST.ONE_DAY_SEC
		local end_time = start_time + duration * CONST.ONE_DAY_SEC
		local open = open_idx >= start_day and open_idx < start_day + duration
		return open, open_idx >= start_day + duration, start_time, end_time
	end
	if kind == CONST.ACTIVITY_TIME.WEEKDAY then
		local begin = TIME.day_begin(now)
		local weekday = time_conf.weekday or 1
		local delta = (TIME.get_weekday(now) - weekday) % 7
		local start_time = begin - delta * CONST.ONE_DAY_SEC
		local end_time = start_time + (time_conf.duration or 1) * CONST.ONE_DAY_SEC
		return now >= start_time and now < end_time, false, start_time, end_time
	end
	if kind == CONST.ACTIVITY_TIME.DAILY then
		local start_time = TIME.day_begin(now)
		return true, false, start_time, start_time + CONST.ONE_DAY_SEC
	end
	return false, false, 0, 0
end

local function state_of(user, conf, now, open_time)
	local open, ended, start_time, end_time = time_window(conf, now, open_time)
	if not level_ok(user, conf) then
		return CONST.ACTIVITY_STATE.CLOSED, start_time, end_time
	end
	if open then
		return CONST.ACTIVITY_STATE.OPEN, start_time, end_time
	end
	if ended then
		return CONST.ACTIVITY_STATE.END, start_time, end_time
	end
	return CONST.ACTIVITY_STATE.CLOSED, start_time, end_time
end

local function is_open(user, conf)
	local state = state_of(user, conf, TIME.os_bj_sec(), GAME.get_open_time())
	return state == CONST.ACTIVITY_STATE.OPEN
end

-- 只改这份活动自己的进度，不发协议。在线时长、充值额都取玩家身上的
local function prepare(user, conf, act)
	local now = TIME.os_bj_sec()
	local state, start_time, end_time = state_of(user, conf, now, GAME.get_open_time())
	local day = TIME.get_rela_day_no(now)
	if conf.Type == CONST.ACTIVITY_TYPE.ONLINE then
		if act._day_no ~= day then
			act._day_no = day
			clear_map(act._got_tbl)
		end
		act._progress = user:get_day_online_min()
	elseif conf.Type == CONST.ACTIVITY_TYPE.LOGIN then
		if state == CONST.ACTIVITY_STATE.OPEN and act._day_no ~= day then
			act._day_no = day
			act._progress = act._progress + 1
		end
	elseif conf.Type == CONST.ACTIVITY_TYPE.GIFT then
		local need = 1
		if conf.Params and conf.Params.need_recharge then
			need = conf.Params.need_recharge
		end
		if user:get_sum_recharge_diamond() >= need then
			act._progress = 1
		else
			act._progress = 0
		end
	elseif conf.Type == CONST.ACTIVITY_TYPE.RANK then
		local rank_type = 0
		if conf.Params and conf.Params.rank_type then
			rank_type = conf.Params.rank_type
		end
		act._progress = call_rank("get_rank", rank_type, user:get_user_id()) or 0
	end
	return state, start_time, end_time
end

local function got_list(act)
	local list = {}
	for idx, flag in pairs(act._got_tbl) do
		if flag ~= 0 then
			list[#list + 1] = idx
		end
	end
	return list
end

local function extra_map(act)
	local list = {}
	for key, value in pairs(act._extra_tbl) do
		list[#list + 1] = {key = key, value = value}
	end
	return list
end

local function act_pto(conf, act, state, start_time, end_time)
	return {
		activityId = conf.Id,
		state = state,
		progress = act._progress,
		startTime = start_time,
		endTime = end_time,
		gotList = got_list(act),
		extraMap = extra_map(act),
	}
end

local function sync_act(user, conf, act, state, start_time, end_time)
	local fd = user:get_fd()
	if not fd then
		return
	end
	for_caller.s2c_sync_activity(fd, {
		activityInfo = act_pto(conf, act, state, start_time, end_time),
	})
end

function on_calc_item_reward(user_id, ctx)
	local user = USER_MGR.try_init_user(user_id)
	for _, conf in pairs(DATA_COMMON.get_all_activity()) do
		if conf.Type == CONST.ACTIVITY_TYPE.RES_RATE and is_open(user, conf) and conf.Params then
			local ids = conf.Params.item_ids
			if ids and conf.Params.rate and conf.Params.rate > ctx.rate then
				for _, id in ipairs(ids) do
					if id == ctx.item_id then
						ctx.rate = conf.Params.rate
						break
					end
				end
			end
		end
	end
end

function on_calc_lottery_cost(user_id, ctx)
	local user = USER_MGR.try_init_user(user_id)
	for _, conf in pairs(DATA_COMMON.get_all_activity()) do
		if conf.Type == CONST.ACTIVITY_TYPE.LOTTERY and is_open(user, conf) and conf.Params then
			if conf.Params.lottery_id == ctx.lottery_id and conf.Params.cost_rate and conf.Params.cost_rate < ctx.rate then
				ctx.rate = conf.Params.cost_rate
			end
		end
	end
end

local function report_score(user_id)
	local user = USER_MGR.try_init_user(user_id)
	call_rank("set_score", CONST.RANK_TYPE.POWER, user_id, user:get_power())
	call_rank("set_score", CONST.RANK_TYPE.CITY, user_id, user:get_city_level())
end

-- type_set 为空时刷新全部活动
local function refresh(user, type_set, do_sync)
	local doc = load_doc(user:get_user_id())
	for _, conf in pairs(DATA_COMMON.get_all_activity()) do
		if not type_set or type_set[conf.Type] then
			local act = act_of(doc, conf.Id)
			local prev = act._progress
			local state, start_time, end_time = prepare(user, conf, act)
			if do_sync and prev ~= act._progress then
				sync_act(user, conf, act, state, start_time, end_time)
			end
		end
	end
	return doc
end

local DAY_TYPES = {
	[CONST.ACTIVITY_TYPE.LOGIN] = true,
	[CONST.ACTIVITY_TYPE.ONLINE] = true,
}

local ONLINE_TYPES = {
	[CONST.ACTIVITY_TYPE.ONLINE] = true,
}

local GIFT_TYPES = {
	[CONST.ACTIVITY_TYPE.GIFT] = true,
}

function on_user_login(user_id)
	report_score(user_id)
	refresh(USER_MGR.try_init_user(user_id), nil, true)
end

function on_new_day(user_id)
	refresh(USER_MGR.try_init_user(user_id), DAY_TYPES, true)
end

function on_online_minute(user_id)
	refresh(USER_MGR.try_init_user(user_id), ONLINE_TYPES, true)
end

function on_recharge(user_id)
	refresh(USER_MGR.try_init_user(user_id), GIFT_TYPES, true)
end

function on_hero_add(user_id)
	report_score(user_id)
end

function on_build_level(user_id, bid)
	if bid == CONST.BUILD_TYPE.MAIN_HALL then
		report_score(user_id)
	end
end

function on_user_logout(user_id)
	if ORM.get(MONGO_SLAVE.COL.USER_ACTIVITY, user_id) then
		MONGO_SLAVE.flush()
		ORM.unbind(MONGO_SLAVE.COL.USER_ACTIVITY, user_id)
	end
end

local function already_got(act, index)
	return act._got_tbl[index] ~= nil and act._got_tbl[index] ~= 0
end

local function on_req_activity_list(fd)
	local user = USER_MGR.get_user_by_fd(fd)
	if not user then
		return
	end
	local doc = refresh(user, nil, false)
	local activity_list = {}
	local now = TIME.os_bj_sec()
	local open_time = GAME.get_open_time()
	for _, conf in pairs(DATA_COMMON.get_all_activity()) do
		local act = act_of(doc, conf.Id)
		local state, start_time, end_time = state_of(user, conf, now, open_time)
		activity_list[#activity_list + 1] = act_pto(conf, act, state, start_time, end_time)
	end
	for_caller.s2c_req_activity_list(fd, {activityList = activity_list})
end

local function claim_reward(conf, act, index)
	if conf.Type == CONST.ACTIVITY_TYPE.GIFT then
		if index ~= 0 or act._progress < 1 or already_got(act, 0) then
			return
		end
		return conf.Rewards
	end
	local entry = conf.Rewards and conf.Rewards[index]
	if not entry or already_got(act, index) then
		return
	end
	if conf.Type == CONST.ACTIVITY_TYPE.LOGIN then
		if act._progress < (entry.day or index) then
			return
		end
		return entry.reward
	end
	if conf.Type == CONST.ACTIVITY_TYPE.ONLINE then
		if act._progress < (entry.minute or 0) then
			return
		end
		return entry.reward
	end
	if conf.Type == CONST.ACTIVITY_TYPE.RANK then
		if act._progress < (entry.rank_min or 1) or act._progress > (entry.rank_max or 0) then
			return
		end
		return entry.reward
	end
end

local function on_get_activity_reward(fd, packet)
	local user = USER_MGR.get_user_by_fd(fd)
	if not user then
		return
	end
	local conf = DATA_COMMON.get_activity_conf(packet.activityId)
	if not conf then
		return
	end
	local doc = load_doc(user:get_user_id())
	local act = act_of(doc, conf.Id)
	local state, start_time, end_time = prepare(user, conf, act)
	local allow = state == CONST.ACTIVITY_STATE.OPEN
	if conf.Type == CONST.ACTIVITY_TYPE.RANK then
		allow = state == CONST.ACTIVITY_STATE.END
	elseif conf.Type == CONST.ACTIVITY_TYPE.LOGIN or conf.Type == CONST.ACTIVITY_TYPE.GIFT then
		allow = state == CONST.ACTIVITY_STATE.OPEN or state == CONST.ACTIVITY_STATE.END
	end
	if not allow then
		return
	end
	local reward = claim_reward(conf, act, packet.index)
	if not reward then
		return
	end
	act._got_tbl[packet.index] = 1
	REWARD_MGR.reward_user(user:get_user_id(), reward, {CONST.FLOW_REASON.ACTIVITY, conf.Id, packet.index})
	sync_act(user, conf, act, state, start_time, end_time)
	for_caller.s2c_get_activity_reward(fd, {activityId = conf.Id, index = packet.index})
end

local function on_activity_exchange(fd, packet)
	local user = USER_MGR.get_user_by_fd(fd)
	if not user then
		return
	end
	local count = packet.count or 0
	if count < 1 then
		return
	end
	local conf = DATA_COMMON.get_activity_conf(packet.activityId)
	if not conf or conf.Type ~= CONST.ACTIVITY_TYPE.EXCHANGE then
		return
	end
	local entry = conf.Params and conf.Params.exchanges and conf.Params.exchanges[packet.index]
	if not entry then
		return
	end
	local doc = load_doc(user:get_user_id())
	local act = act_of(doc, conf.Id)
	local state, start_time, end_time = prepare(user, conf, act)
	if state ~= CONST.ACTIVITY_STATE.OPEN then
		return
	end
	local used = act._extra_tbl[packet.index] or 0
	if entry.limit and used + count > entry.limit then
		return
	end
	local cost_list = {
		{
			cost_type = CONST.COST_TYPE.ITEM,
			itemId = entry.cost_item,
			count = entry.cost_count * count,
		},
	}
	local reason_list = {CONST.FLOW_REASON.ACTIVITY, conf.Id, packet.index}
	if not ITEM_MGR.del_cost_list(user:get_user_id(), cost_list, reason_list) then
		return
	end
	act._extra_tbl[packet.index] = used + count
	REWARD_MGR.reward_user(user:get_user_id(), {
		GLOBAL_FUNC.gen_reward_info(entry.reward_type, entry.item_id, entry.item_count * count),
	}, reason_list)
	sync_act(user, conf, act, state, start_time, end_time)
	for_caller.s2c_activity_exchange(fd, {
		activityId = conf.Id,
		index = packet.index,
		count = count,
	})
end

function __init__()
	for_maker.c2s_req_activity_list = on_req_activity_list
	for_maker.c2s_get_activity_reward = on_get_activity_reward
	for_maker.c2s_activity_exchange = on_activity_exchange
	EVENT.listen(CONST.EVENT.ON_USER_LOGIN)
	EVENT.listen(CONST.EVENT.ON_USER_LOGOUT)
	EVENT.listen(CONST.EVENT.ON_NEW_DAY)
	EVENT.listen(CONST.EVENT.ON_ONLINE_MINUTE)
	EVENT.listen(CONST.EVENT.ON_RECHARGE)
	EVENT.listen(CONST.EVENT.ON_HERO_ADD)
	EVENT.listen(CONST.EVENT.ON_BUILD_LEVEL)
	EVENT.listen(CONST.EVENT.ON_CALC_ITEM_REWARD)
	EVENT.listen(CONST.EVENT.ON_CALC_LOTTERY_COST)
end
