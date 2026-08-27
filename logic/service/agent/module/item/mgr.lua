allItemTbl = {
--[[
	[userId] = {
		[itemType] = {
			[itemId] = item,
		},
	},
--]]
}

allItemIdTbl = {
--[[
	[userId] = {
		[itemId] = item,
	}
--]]
}

allItemKindTbl = {
--[[
	[userId] = {
		[itemKind] = {
			[itemId] = item,
		},
	}
--]]
}

local function refItem(item)
	local userId = item:getUserId()
	local itemType = item:getItemType()
	local itemId = item:getItemId()
	local itemKind = item:getItemKind()
	if not allItemTbl[userId] then
		allItemTbl[userId] = {}
	end
	if not allItemTbl[userId][itemType] then
		allItemTbl[userId][itemType] = {}
	end
	allItemTbl[userId][itemType][itemId] = item
	if not allItemIdTbl[userId] then
		allItemIdTbl[userId] = {}
	end
	allItemIdTbl[userId][itemId] = item
	if not allItemKindTbl[userId] then
		allItemKindTbl[userId] = {}
	end
	if not allItemKindTbl[userId][itemKind] then
		allItemKindTbl[userId][itemKind] = {}
	end
	allItemKindTbl[userId][itemKind][itemId] = item
end

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

function getItemMaxAddCnt(itemType)
	return DATA_COMMON.getItemOverlap(itemType)
end

local ITEM_KIND_TO_MOD = {
	[CONST.ITEM_KIND.HERO_EQUIP] = CLS_HERO_EQUIP_ITEM,
}

local function createItem(oci)
	local itemType = oci._itemType
	assert(itemType)
	local kind = DATA_COMMON.getItemKindByType(itemType)
	local mod = ITEM_KIND_TO_MOD[kind] or CLS_BASE_ITEM
	local item = mod.clsItem:New(oci)
	refItem(item)
	return item
end

function unrefItem(item)
	local userId = item:getUserId()
	local itemType = item:getItemType()
	local itemId = item:getItemId()
	local itemKind = item:getItemKind()
	if allItemTbl[userId] and allItemTbl[userId][itemType] then
		allItemTbl[userId][itemType][itemId] = nil
	end
	if allItemIdTbl[userId] then
		allItemIdTbl[userId][itemId] = nil
	end
	if allItemKindTbl[userId] and allItemKindTbl[userId][itemKind] then
		allItemKindTbl[userId][itemKind][itemId] = nil
	end
end

function persistUserItems(userId)
	assert(userId)
	local itemTbl = allItemIdTbl[userId] or {}
	local bagData = {}
	for itemId, item in pairs(itemTbl) do
		bagData[itemId] = item._data
	end
	local doc = ORM.create(ORM.CLS_USER_ITEM_DOC, { _items = bagData })
	MONGO_SLAVE.saveDoc(MONGO_SLAVE.USER_ITEM_COL, userId, ORM.dump(doc))
end

local function tryInitUserData(userId)
	if not allItemIdTbl[userId] then
		local raw = MONGO_SLAVE.loadSingleUserItem(userId) or {}
		allItemIdTbl[userId] = {}
		local doc = ORM.create(ORM.CLS_USER_ITEM_DOC, raw)
		for _, itemData in pairs(doc._items) do
			if ORM.is_cls(itemData, ORM.CLS_ITEM_DATA) then
				createItem(itemData)
			end
		end
	end
	return allItemIdTbl[userId]
end

local function saveItem(item)
	persistUserItems(item:getUserId())
end

local function generateItem(userId, itemType, cnt)
	local itemId = getIdByUserIdAndTimestamp(userId)
	local oci = {
		_itemId = tostring(itemId),
		_itemType = itemType,
		_userId = userId,
		_itemCnt = cnt or 1,
	}
	local item = createItem(oci)
	item:afterGenerate()
	saveItem(item)
	return item
end


local function doAddItemCntByType(userId, itemType, cnt, needSync, reasonList, newItemList)
	assert(cnt > 0)
	tryInitUserData(userId)
	local userItemTbl = allItemTbl[userId] or {}
	local itemTbl = userItemTbl[itemType] or {}
	if DATA_COMMON.canOverlap(itemType) then
		local _, item = next(itemTbl)
		if not item then
			item = generateItem(userId, itemType, cnt)
		else
			item:addCnt(cnt)
		end
		if needSync then
			item:syncToClient()
		end
	else
		assert(cnt < 10000000)
		for _ = 1, cnt do
			local item = generateItem(userId, itemType)
			if needSync then
				item:syncToClient()
			end
			if newItemList then
				table.insert(newItemList, item)
			end
		end
	end
	-- LOG.addItem(userId, itemType, cnt, reasonList)
end

function addItemCntByType(userId, itemType, cnt, reasonList)
	doAddItemCntByType(userId, itemType, cnt, true, reasonList)
end

function addItemCntByTypeNoSync(userId, itemType, cnt, reasonList, newItemList)
	return doAddItemCntByType(userId, itemType, cnt, false, reasonList, newItemList)
end

local function rewardResourceBase(userId, itemType, cnt, reasonList)
	addItemCntByType(userId, itemType, cnt, reasonList)
end

local ITEM_KIND_REWARD_FUNC = {
	[CONST.ITEM_KIND.RES] = rewardResourceBase,
	[CONST.ITEM_KIND.HERO_CHIP] = rewardResourceBase,
	[CONST.ITEM_KIND.HERO_EQUIP] = rewardResourceBase,
	[CONST.ITEM_KIND.RANDOM_REWARD] = rewardResourceBase,
	[CONST.ITEM_KIND.SOLDIER] = rewardResourceBase,
	[CONST.ITEM_KIND.VIP] = rewardResourceBase,
}

function addItem(userId, itemType, cnt, reasonList)
	local itemKind = DATA_COMMON.getItemKindByType(itemType)
	local func = ITEM_KIND_REWARD_FUNC[itemKind]
	if func then
		func(userId, itemType, cnt, reasonList)
	else
		addItemCntByType(userId, itemType, cnt, reasonList)
	end
end