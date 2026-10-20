clsItem = clsObject:Inherit()

function clsItem:__init__(oci)
	Super(clsItem).__init__(self)
	if ORM.is_cls(oci, ORM.CLS_ITEM_DATA) then
		self._data = oci
	else
		self._data = ORM.create(ORM.CLS_ITEM_DATA, oci)
	end
	ORM.put(MONGO_SLAVE.COL.USER_ITEM, self._data._userId, "_items", self._data._itemId, self._data)
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
end

function clsItem:subCnt(cnt)
	assert(cnt > 0 and cnt <= self._data._itemCnt)
	self._data._itemCnt = self._data._itemCnt - cnt
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
	ORM.remove(MONGO_SLAVE.COL.USER_ITEM, self:getUserId(), "_items", self:getItemId())
	ITEM_MGR.unrefItem(self)
	Super(clsItem).release(self)
end

function clsItem:afterGenerate()
end

function clsItem:getItemKind()
	return DATA_COMMON.getItemKindByType(self:getItemType())
end
