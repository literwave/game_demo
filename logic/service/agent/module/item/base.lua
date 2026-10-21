cls_item = cls_object:Inherit()

function cls_item:__init__(oci)
	Super(cls_item).__init__(self)
	if ORM.is_cls(oci, ORM.CLS_ITEM_DATA) then
		self._data = oci
	else
		self._data = ORM.create(ORM.CLS_ITEM_DATA, oci)
	end
	ORM.put(MONGO_SLAVE.COL.USER_ITEM, self._data._user_id, "_items", self._data._item_id, self._data)
end

function cls_item:get_item_id()
	return self._data._item_id
end

function cls_item:get_item_type()
	return self._data._item_type
end

function cls_item:get_user_id()
	return self._data._user_id
end

function cls_item:get_cnt()
	return self._data._item_cnt
end

function cls_item:add_cnt(cnt)
	assert(DATA_COMMON.can_overlap(self:get_item_type()))
	assert(cnt > 0)
	self._data._item_cnt = self._data._item_cnt + cnt
end

function cls_item:sub_cnt(cnt)
	assert(cnt > 0 and cnt <= self._data._item_cnt)
	self._data._item_cnt = self._data._item_cnt - cnt
end

function cls_item:get_item_pto_info()
	return {
		itemId = self:get_item_id(),
		itemType = self:get_item_type(),
		itemCnt = self:get_cnt(),
	}
end

function cls_item:sync_to_client()
	local info = self:get_item_pto_info()
	local Fd = USER_MGR.get_fd_by_user_id(self:get_user_id())
	if Fd then
		for_caller.s2c_sync_item_data(Fd, info)
	end
end

function cls_item:can_use(user_id, use_cnt)
	return DATA_COMMON.get_item_use_info(self:get_item_type()) == 1
end

function cls_item:release()
	ORM.remove(MONGO_SLAVE.COL.USER_ITEM, self:get_user_id(), "_items", self:get_item_id())
	ITEM_MGR.unref_item(self)
	Super(cls_item).release(self)
end

function cls_item:after_generate()
end

function cls_item:get_item_kind()
	return DATA_COMMON.get_item_kind_by_type(self:get_item_type())
end
