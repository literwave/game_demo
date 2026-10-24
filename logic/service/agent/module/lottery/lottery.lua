local function on_req_user_lottery_info(fd)
	local user = USER_MGR.get_user_by_fd(fd)
	if not user then
		return
	end
	for_caller.s2c_req_user_lottery_info(fd, {lotteryTimes = user:get_lottery_times()})
end

local function draw(pool)
	local weight_list = {}
	for _, entry in ipairs(pool or EMPTY_TABLE) do
		table.insert(weight_list, {entry, entry.weight or 0})
	end
	return rand_item_by_weight(weight_list)
end

-- 先把每一发都抽完、确认奖池可用，再扣消耗；中途失败不会白扣
local function on_user_lottery(fd, packet)
	local user = USER_MGR.get_user_by_fd(fd)
	if not user then
		return
	end
	local use_lottery_times = packet.useLotteryTimes
	local conf = DATA_COMMON.get_lottery_conf(use_lottery_times)
	if not conf or not conf.CostList then
		return
	end
	local user_id = user:get_user_id()
	local cost_list = conf.CostList
	local ctx = {lottery_id = use_lottery_times, rate = 100}
	EVENT.dispatch(CONST.EVENT.ON_CALC_LOTTERY_COST, user_id, ctx)
	local rate = ctx.rate
	if rate < 100 then
		cost_list = {}
		for _, cost in ipairs(conf.CostList) do
			local count = math.floor(cost.count * rate / 100)
			if count < 1 then
				count = 1
			end
			cost_list[#cost_list + 1] = {
				cost_type = cost.cost_type,
				itemId = cost.itemId,
				count = count,
			}
		end
	end
	if not ITEM_MGR.check_cost_enough(user_id, cost_list) then
		return
	end
	local lottery_times = user:get_lottery_times()
	local reward_list = {}
	for _ = 1, use_lottery_times do
		lottery_times = lottery_times + 1
		local entry
		if conf.HeroPools and conf.UpHeroTimes and lottery_times >= conf.UpHeroTimes then
			entry = draw(conf.HeroPools)
			lottery_times = 0
		else
			entry = draw(conf.CommonPools)
		end
		if not entry then
			LOG._error("lottery pool empty: %s", use_lottery_times)
			return
		end
		table.insert(reward_list, GLOBAL_FUNC.gen_reward_info(entry.reward_type, entry.item_id, entry.item_count))
	end
	local reason_list = {CONST.FLOW_REASON.LOTTERY, use_lottery_times}
	assert(ITEM_MGR.del_cost_list(user_id, cost_list, reason_list))
	user:set_lottery_times(lottery_times)
	REWARD_MGR.reward_user_and_show(user_id, reward_list, reason_list)
	for_caller.s2c_user_lottery(fd, {useLotteryTimes = use_lottery_times, lotteryTimes = lottery_times})
	EVENT.dispatch(CONST.EVENT.ON_LOTTERY, user_id, use_lottery_times)
end

function __init__()
	for_maker.c2s_req_user_lottery_info = on_req_user_lottery_info
	for_maker.c2s_user_lottery = on_user_lottery
end
