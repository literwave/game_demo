cls_build = cls_object:Inherit()

function cls_build:__init__(oci)
	Super(cls_build).__init__(self, oci)
	self._data = ORM.new(ORM.CLS_BUILD_DATA, oci)
	ORM.get(MONGO_SLAVE.COL.USER_BUILD, self._data._user_id)._builds[self._data._bid] = self._data
	BUILD_MGR.ref_build(self)
end

function cls_build:get_user_id()
	return self._data._user_id
end

function cls_build:get_bid()
	return self._data._bid
end

function cls_build:get_level()
	return self._data._level
end

function cls_build:set_level(level)
	self._data._level = level
end

function cls_build:get_build_type()
	return DATA_COMMON.get_build_type_by_id(self:get_bid())
end

function cls_build:get_build_pto_info()
	return {
		bid = self:get_bid(),
		level = self:get_level(),
	}
end

function cls_build:sync_to_client()
	local fd = USER_MGR.get_fd_by_user_id(self:get_user_id())
	if fd then
		for_caller.s2c_sync_build(fd, self:get_build_pto_info())
	end
end
