local checkEnoughFunc = {
	[CONST.COST_TYPE.DIAMOND] = function(userId, costInfo)
		local user = USER_MGR.tryInitUser(userId)
		return user:checkDiamondEnough(userId, costInfo.count)
	end,
	[CONST.COST_TYPE.RES] = function(userId, costInfo)
		return RESOURCE.checkResEnough(userId, costInfo.count)
	end,
	[CONST.COST_TYPE.ITEM] = function(userId, costInfo)
		local itemInfo = ITEM_MGR.getItemInfo(costInfo.itemId)
		if not itemInfo then
			return false
		end
		local itemCount = ITEM_MGR.getItemCount(userId, itemInfo.itemId)
		if itemCount < costInfo.count then
			return false
		end
		return true
	end,
}

local subFunc = {
	[CONST.COST_TYPE.DIAMOND] = function(userId, costInfo)
		local user = USER_MGR.tryInitUser(userId)
		user:subDiamond(costInfo.count)
	end,
	[CONST.COST_TYPE.RES] = function(userId, costInfo)
		return RESOURCE.checkResEnough(userId, costInfo.count)
	end,
	[CONST.COST_TYPE.ITEM] = function(userId, costInfo)
		local itemInfo = ITEM_MGR.getItemInfo(costInfo.itemId)
		if not itemInfo then
			return false
		end
		local itemCount = ITEM_MGR.getItemCount(userId, itemInfo.itemId)
		if itemCount < costInfo.count then
			return false
		end
		return true
	end,
}

function checkCostEnough(userId, costList)
	if not next(costList) then
		return false
	end
	for _, constInfo in ipairs(costList) do
		local func = checkEnoughFunc[constInfo.costType]
		if not func then
			return false
		end
		local isEnough = func(userId, constInfo)
		if not isEnough then
			return false
		end
	end
	return true
end

function delCostList(userId, costList)
		for _, constInfo in ipairs(costList) do
		local func = subFunc[constInfo.costType]
		func(userId, constInfo)
	end
	return true
end