
local saveFieldTbl = {
	_userId = function()
		return nil
	end,
	_birthTime = function()
		return nil
	end,
	_logintime = function()
		return nil
	end,
	_name = function()
		return nil
	end,
	_sdkParamTbl = function ()
		return nil
	end,
	_resTbl = function ()
		return {
			--[[
				[resourceType] = cnt,
			]]
		}
	end,
}

clsUser = clsObject:Inherit()

function clsUser:__init__(oci)
	Super(clsUser).__init__(self, oci)
	for k, func in pairs(saveFieldTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
	self._account = nil
	self._loginAddr = nil
	self._fd = nil
	self._heartBeatTime = nil
end

function clsUser:saveField(keyList, val)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_INFO_COL, self._userId, table.unpack(keyList)}, val)
end

function clsUser:getUserId()
	return self._userId
end
function clsUser:isOnline()
	return self:getVfd() ~= nil
end

function clsUser:getBirthTime()
	return self._birthTime
end

function clsUser:getName()
	return self._name
end
function clsUser:getVfd()
	local userId = self:getUserId()
	return USER_MGR.getVfdByUserId(userId)
end

function clsUser:getResNum(resType)
	return self._resTbl[resType] or 0
end

function clsUser:addRes(resType, num)
	local resNum = self:getResNum(resType)
	self._resTbl[resType] = num + resNum
end

function clsUser:serialize(tbl)
	for key, _ in pairs(saveFieldTbl) do
		tbl[key] = self[key]
	end
end

function clsUser:saveToDB()
	local info = {}
	self:serialize(info)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_INFO_COL, self._userId}, info)
end

function clsUser:setSdkParamTbl(paramTbl)
	self._sdkParamTbl = paramTbl
	self:saveField({"_sdkParamTbl"}, self._sdkParamTbl)
end

function clsUser:updateByLoginParamTbl(paramTbl)
	self:setDeviceId(paramTbl.loginInfo.deviceId)
	self:setClientPlatform(paramTbl.loginInfo.platform)
	if paramTbl.sdkParamTbl then
		self:setSdkParamTbl(paramTbl.sdkParamTbl)
	end
end

function clsUser:getAccount()
	return self._account
end

function clsUser:setAccount(account)
	self._account = account
end

function clsUser:getLoginAddr()
	return self._loginAddr
end

function clsUser:setLoginAddr(addr)
	self._loginAddr = addr
end

function clsUser:getFd()
	return self._fd
end

function clsUser:setFd(fd)
	self._fd = fd
end

function clsUser:getHeartBeatTime()
	return self._heartBeatTime
end

function clsUser:setAndSyncHeartBeatTime(time)
	local fd = self:getFd()
	local ptoTbl = {
		heartBeatTime = time
	}
	for_caller.s2cheartbeat(fd, ptoTbl)
end

function clsUser:onLogin()
	self:setLoginTime(os.time())
end

function clsUser:setLoginTime(time)
	self:saveField({"_loginTime"}, time)
end