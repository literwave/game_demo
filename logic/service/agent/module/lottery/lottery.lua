local function on_req_user_lottery_info(fd)
	local user = USER_MGR.get_user_by_fd(fd)
	local lottery_times = user:get_lottery_times() or 0
	for_caller.s2c_req_user_lottery_info(fd, {lotteryTimes = lottery_times})
end

local function on_user_lottery(fd, packet)
	local use_lottery_times = packet.useLotteryTimes
	local user = USER_MGR.get_user_by_fd(fd)
	local lottery_times = user:get_lottery_times() or 0
	local common_pools = DATA_COMMON.get_lottery_common_pools(use_lottery_times)
	local hero_pools = DATA_COMMON.get_lottery_hero_pools(use_lottery_times)
	local up_hero_item_lottery_times = DATA_COMMON.get_up_hero_item_lottery_times(use_lottery_times)
	local cost_list = DATA_COMMON.get_lottery_cost(use_lottery_times)
	if not cost_list then
		return
	end
	if ITEM_MGR.check_item_enough(user:get_user_id(), cost_list) then
		return
	end
	local reward_list = {}
	for _ = 1, use_lottery_times do
		local item
		if lottery_times >= up_hero_item_lottery_times then
			item = rand_item_by_weight(hero_pools)
			lottery_times = 0
		else
			item = rand_item_by_weight(common_pools)
		end
		table.insert(reward_list, item)
	end
	ITEM_MGR.del_cost_list(user:get_user_id(), cost_list)
	user:set_lottery_times(lottery_times)
	REWARD_MGR.reward_user_and_show(user:get_user_id(), reward_list)
	for_maker.s2c_user_lottery(fd, {useLotteryTimes = use_lottery_times, lotteryTimes = lottery_times})
end

function __init__()
	for_maker.c2s_req_user_lottery_info = on_req_user_lottery_info
	for_maker.c2s_user_lottery = on_user_lottery
end