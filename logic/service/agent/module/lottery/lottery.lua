local function onReqUserLotteryInfo(fd)
	local user = USER_MGR.getUserByFd(fd)
	local lotteryTimes = user:getLotteryTimes() or 0
	for_caller.s2c_req_user_lottery_info(fd, {lotteryTimes = lotteryTimes})
end

local function onUserLottery(fd, packet)
	local useLotteryTimes = packet.useLotteryTimes
	local user = USER_MGR.getUserByFd(fd)
	local lotteryTimes = user:getLotteryTimes() or 0
	local commonPools = DATA_COMMON.getLotteryCommonPools(useLotteryTimes)
	local heroPools = DATA_COMMON.getLotteryHeroPools(useLotteryTimes)
	local upHeroItemLotteryTimes = DATA_COMMON.getUpHeroItemLotteryTimes(useLotteryTimes)
	local costList = DATA_COMMON.getLotteryCost(useLotteryTimes)
	if not costList then
		return
	end
	if ITEM_MGR.checkItemEnough(user:getUserId(), costList) then
		return
	end
	local rewardList = {}
	for _ = 1, useLotteryTimes do
		local item
		if lotteryTimes >= upHeroItemLotteryTimes then
			item = randItemByWeight(heroPools)
			lotteryTimes = 0
		else
			item = randItemByWeight(commonPools)
		end
		table.insert(rewardList, item)
	end
	ITEM_MGR.delCostList(user:getUserId(), costList)
	user:setLotteryTimes(lotteryTimes)
	REWARD_MGR.rewardUserAndShow(user:getUserId(), rewardList)
	for_maker.s2c_user_lottery(fd, {useLotteryTimes = useLotteryTimes, lotteryTimes = lotteryTimes})
end

function __init__()
	for_maker.c2s_req_user_lottery_info = onReqUserLotteryInfo
	for_maker.c2s_user_lottery = onUserLottery
end