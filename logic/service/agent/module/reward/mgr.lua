
local function rewardResource(ret, userId, rewardInfoList, reasonList)
	for _, rewardInfo in pairs(rewardInfoList) do
		local resType = rewardInfo.item_type 
		local cnt = rewardInfo.item_count
		USER_RESOURCE.addResAndSync(userId, resType, cnt, reasonList)
		table.insert(ret, rewardInfo)
	end
end

local function rewardAccItem(ret, userId, rewardInfo, reasonList) 
end

local function rewardHeroChip(ret, userId, rewardInfo, reasonList)
end

local function rewardActivityItem(ret, userId, rewardInfo, reasonList)
end

local function rewardResourceItem(ret, userId, rewardInfo, reasonList)
end

local ITEM_KIND_REWARD_FUNC = {
	[CONST.ITEM_KIND.RES] = rewardResourceItem,
	[CONST.ITEM_KIND.HERO_CHIP] = rewardHeroChip,
	[CONST.ITEM_KIND.ACC] = rewardAccItem,
	[CONST.ITEM_KIND.ACTIVITY] = rewardActivityItem,
}

local function rewardItem(ret, userId, rewardInfoList, reasonList)
end

local function rewardHero(ret, userId, rewardInfoList, reasonList) 
	local mailRewardList = {}
	for _, rewardInfo in pairs(rewardInfoList) do
		local heroType = rewardInfo.item_type
		if not DATA_COMMON.isHeroDisable(heroType) then
			if HERO_MGR.getHeroByType(userId, heroType) then
				local newRewardInfo = genRewardInfo()
				rewardItem(ret, userId, newRewardInfo, reasonList)
			else
				if HERO_MGR.checkHeroNumLimit(userId) then
					table.insert(mailRewardList, rewardInfo)
				else
					local hero = HERO_MGR.addHero(userId, heroType, reasonList)
					table.insert(ret, rewardInfo)
				end
			end
		else
			LOG.mainError(string.format("rewardDisableHero Error,userId=%s,heroType=%s,reasonList=%s", userId, heroType, table.concat(reasonList, "-")))
		end
	end
	if table.hasElement(mailRewardList) then
		--MAIL_MGR.sendSystemMail(userId, senderName, content, detail, mailRewardList)
	end
end

local function rewardDiamond(ret, userId, rewardInfoList, reasonList)
	local user = USER_MGR.tryInitUser(userId)
	for _, rewardInfo in pairs(rewardInfoList) do
		local cnt = rewardInfo.item_count
		user:addGiftDiamondAndSync(cnt, reasonList)
		table.insert(ret, rewardInfo)
	end
end

local function rewardTreasureBoxExp(ret, userId, rewardInfoList, reasonList)
	local user = USER_MGR.tryInitUser(userId)
	for _, rewardInfo in pairs(rewardInfoList) do
		local cnt = rewardInfo.item_count
		user:addTreasureBoxExp(cnt, reasonList)
		table.insert(ret, rewardInfo)
	end
end

local GIVE_REWARD_FUNC = {
	[CONST.REWARD_TYPE_ITEM] = rewardItem,
	[CONST.REWARD_TYPE_RES] = rewardResource,
	[CONST.REWARD_TYPE_HERO] = rewardHero,
	[CONST.REWARD_TYPE_DIAMOND] = rewardDiamond,
	[CONST.REWARD_TYPE_TREASUREBOX_EXP] = rewardTreasureBoxExp,
}

local function giveReward(ret, userId, rewardType, rewardInfoList, reasonList)
	local giveRewardFunc = GIVE_REWARD_FUNC[rewardType]
	assert(giveRewardFunc, "invalid reward_type!")
	return giveRewardFunc(ret, userId, rewardInfoList, reasonList)
end

function rewardUser(userId, rewardList, reasonList)
	local rewardTbl = {}
	for _, rewardInfo in pairs(rewardList) do
		local rewardType = rewardInfo.reward_type
		if not rewardTbl[rewardType] then
			rewardTbl[rewardType] = {}
		end
		table.insert(rewardTbl[rewardType], table.deepcopy(rewardInfo))
	end
	local actualRwdList = {}
	for rewardType, rewardInfoList in pairs(rewardTbl) do
		giveReward(actualRwdList, userId, rewardType, rewardInfoList, reasonList)
	end
	return actualRwdList
end

function showReward(userId, rewardList, showTypeList)
	local fd = USER_MGR.getFdByUserId(userId)
	if fd then
		showTypeList = showTypeList or {CONST.REWARD_SHOW_TYPE.WINDOW}
		for_caller.c_show_reward(fd, rewardList, showTypeList)
	end
end

function rewardUserAndShow(userId, rewardList, reasonList, showTypeList)
	local actualRwdList = rewardUser(userId, rewardList, reasonList)
	showReward(userId, actualRwdList, showTypeList)
end
