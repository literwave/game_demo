local skynet = require "skynet"

function subItemList(itemList, cb)
	local tAddr = USER_MGR.getAgentByUserId()
	local sAddr = SERVICE_NAME
	local tbl = {
		mod = getfenv(2),
		func = "subItemList",
		cb = cb,
		args = itemList,
		sAddr = sAddr,
	}
	skynet.send(tAddr, "lua", "subItemList", tbl)
end

function genRewardInfo(rewardType, itemType, itemCount)
	return {reward_type = rewardType, item_type = itemType, item_count = itemCount}
end