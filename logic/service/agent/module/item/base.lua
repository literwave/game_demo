local saveKeyTbl = {
	_itemId = function()
		return nil
	end,
	_itemType = function()
		return nil
	end,
	_userId = function()
		return nil
	end,
	_itemCnt = function()
		return 1
	end,
}

clsItem = clsObject:Inherit()

function clsItem:__init__(oci)
	Super(clsItem).__init__(self)

	for k, func in pairs(saveKeyTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
end

function clsItem:serialize(tbl)
	for key, _ in pairs(saveKeyTbl) do
		tbl[key] = self[key]
	end
end

function clsItem:saveField(keyList, value)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_ITEM_COL, self._userId, self._itemId, unpack(keyList)}, value)	
end

function clsItem:getItemId()
	return self._itemId
end

function clsItem:getItemType()
	return self._itemType
end

function clsItem:getUserId()
	return self._userId
end

function clsItem:getCnt()
	return self._itemCnt
end

function clsItem:addCnt(cnt)
	assert(DATA_COMMON.canOverlap(self._itemType))
	assert(cnt > 0)
	self._itemCnt = self._itemCnt + cnt
	self:saveField({"_itemCnt"}, self._itemCnt)
end

function clsItem:subCnt(cnt)
	assert(cnt > 0 and cnt <= self._itemCnt)
	self._itemCnt = self._itemCnt - cnt
	self:saveField({"_itemCnt"}, self._itemCnt)
end

function clsItem:getItemPTOInfo()
	local info = {
		itemId = self:getItemId(),
		itemType = self:getItemType(),
		itemCnt = self:getCnt(),
	}
	return info
end

function clsItem:syncToClient()
	local info = self:getItemPTOInfo()
	local vfd = USER_MGR.getVfdByUserId(self._userId)
	if vfd then
		for_caller.c_up_item_data(vfd, {info})
	end
end

function clsItem:canUse(userId, useCnt)
	return DATA_COMMON.getItemUseInfo(self:getItemType()) == 1
end

function clsItem:release()
	local userId = self:getUserId()
	local itemId = self:getItemId()
	ITEM_MGR.unrefItem(self)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_ITEM_COL, userId, itemId}, nil)
	Super(clsItem).release(self)
end

function clsItem:afterGenerate()
end

function clsItem:getItemKind()
	return DATA_COMMON.getItemKindByType(self._itemType)
end
