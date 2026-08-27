clsItem = clsObject:Inherit()

function clsItem:__init__(oci)
	Super(clsItem).__init__(self)
	if ORM.is_cls(oci, ORM.CLS_ITEM_DATA) then
		self._data = oci
	else
		self._data = ORM.create(ORM.CLS_ITEM_DATA, oci)
	end
end

function clsItem:saveField(field)
	assert(type(field) == "string", "saveField only accepts string field name")
	ITEM_MGR.persistUserItems(self:getUserId())
end

function clsItem:saveToDB()
	ITEM_MGR.persistUserItems(self:getUserId())
end

function clsItem:getItemId()
	return self._data._itemId
end

function clsItem:getItemType()
	return self._data._itemType
end

function clsItem:getUserId()
	return self._data._userId
end

function clsItem:getCnt()
	return self._data._itemCnt
end

function clsItem:addCnt(cnt)
	assert(DATA_COMMON.canOverlap(self:getItemType()))
	assert(cnt > 0)
	self._data._itemCnt = self._data._itemCnt + cnt
	self:saveField("_itemCnt")
end

function clsItem:subCnt(cnt)
	assert(cnt > 0 and cnt <= self._data._itemCnt)
	self._data._itemCnt = self._data._itemCnt - cnt
	self:saveField("_itemCnt")
end

function clsItem:getItemPTOInfo()
	return {
		itemId = self:getItemId(),
		itemType = self:getItemType(),
		itemCnt = self:getCnt(),
	}
end

function clsItem:syncToClient()
	local info = self:getItemPTOInfo()
	local Fd = USER_MGR.getFdByUserId(self:getUserId())
	if Fd then
		for_caller.s2c_sync_item_data(Fd, info)
	end
end

function clsItem:canUse(userId, useCnt)
	return DATA_COMMON.getItemUseInfo(self:getItemType()) == 1
end

function clsItem:release()
	local userId = self:getUserId()
	ITEM_MGR.unrefItem(self)
	ITEM_MGR.persistUserItems(userId)
	Super(clsItem).release(self)
end

function clsItem:afterGenerate()
end

function clsItem:getItemKind()
	return DATA_COMMON.getItemKindByType(self:getItemType())
end
