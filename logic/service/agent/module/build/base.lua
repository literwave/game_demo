clsBuild = clsObject:Inherit()

function clsBuild:__init__(oci)
	Super(clsBuild).__init__(self, oci)
	if ORM.is_cls(oci, ORM.CLS_BUILD_DATA) then
		self._data = oci
	else
		self._data = ORM.create(ORM.CLS_BUILD_DATA, oci)
	end
	ORM.put(MONGO_SLAVE.COL.USER_BUILD, self._data._userId, "_builds", self._data._bid, self._data)
	BUILD_MGR.refBuild(self)
end

function clsBuild:getUserId()
	return self._data._userId
end

function clsBuild:getBid()
	return self._data._bid
end

function clsBuild:getLevel()
	return self._data._level
end

function clsBuild:setLevel(level)
	self._data._level = level
end

function clsBuild:getBuildType()
	return DATA_COMMON.getBuildTypeById(self:getBid())
end

function clsBuild:getBuildPTOInfo()
	return {
		bid = self:getBid(),
		level = self:getLevel(),
	}
end

function clsBuild:syncToClient()
	local fd = USER_MGR.getFdByUserId(self:getUserId())
	if fd then
		for_caller.s2c_sync_build(fd, self:getBuildPTOInfo())
	end
end
