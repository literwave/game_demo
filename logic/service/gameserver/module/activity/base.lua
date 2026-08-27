
local saveFieldTbl = {
	_id = function ()
		return nil
	end,
	_startTime = function ()
		return nil
	end,
	_endTime = function ()
		return nil
	end,
}

clsAct = clsObject:Inherit()

function clsAct:__init__(oci)
	Super(clsAct).__init__(self, oci)
	for k, func in pairs(saveFieldTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
end

function clsAct:saveField(field, val)
	assert(type(field) == "string", "saveField only accepts string field name")
	self[field] = val
	MONGO_SLAVE.saveDocField(MONGO_SLAVE.USER_INFO_COL, self._userId, field, val)
end

function clsAct:getUserId()
	return self._userId
end
function clsAct:isOnline()
	return self:getVfd() ~= nil
end

function clsAct:getBirthTime()
	return self._birthTime
end

function clsAct:getName()
	return self._name
end

function clsAct:setName(name)
	self._name = name
	self:saveField("_name", name)
end

function clsAct:getSex()
	return self._sex
end

function clsAct:setSex(sex)
	self._sex = sex
	self:saveField("_sex", sex)
end

function clsAct:getResNum(resType)
	return self._resTbl[resType] or 0
end

function clsAct:addRes(resType, num)
	local resNum = self:getResNum(resType)
	self._resTbl[resType] = num + resNum
end

function clsAct:serialize(tbl)
	for key, _ in pairs(saveFieldTbl) do
		tbl[key] = self[key]
	end
end

function clsAct:saveToDB()
	local info = {}
	self:serialize(info)
	MONGO_SLAVE.saveDoc(MONGO_SLAVE.USER_INFO_COL, self._userId, info)
end

function clsAct:setSdkParamTbl(paramTbl)
	self._sdkParamTbl = paramTbl
	self:saveField("_sdkParamTbl", self._sdkParamTbl)
end

function clsAct:updateByLoginParamTbl(paramTbl)
	self:setDeviceId(paramTbl.loginInfo.deviceId)
	self:setClientPlatform(paramTbl.loginInfo.platform)
	if paramTbl.sdkParamTbl then
		self:setSdkParamTbl(paramTbl.sdkParamTbl)
	end
end

function clsAct:getAccount()
	return self._account
end

function clsAct:setAccount(account)
	self._account = account
end

function clsAct:getLoginAddr()
	return self._loginAddr
end

function clsAct:setLoginAddr(addr)
	self._loginAddr = addr
end

function clsAct:getGateSrv()
	return self._gateSrv
end

function clsAct:setGateSrv(gateSrv)
	self._gateSrv = gateSrv
end

function clsAct:getFd()
	return self._fd
end

function clsAct:setFd(fd)
	self._fd = fd
end

function clsAct:getHeartBeatTime()
	return self._heartBeatTime
end

function clsAct:setAndSyncHeartBeatTime(time)
	local fd = self:getFd()
	local ptoTbl = {
		heartBeatTime = time
	}
	for_caller.s2c_heart_beat(fd, ptoTbl)
end

function clsAct:onLogin()
	self:setLoginTime(os.time())
end

function clsAct:setLoginTime(time)
	self:saveField("_loginTime", time)
end

function clsAct:setBornServerId(serverId)
	self:saveField("_bornServerId", serverId)
end

function clsAct:getDiamond()
	return self._realDiamond + self._giftDiamond
end

function clsAct:getRealDiamond()
	return self._realDiamond
end

function clsAct:getGiftDiamond()
	return self._giftDiamond
end

function clsAct:addSumRechargeDiamond(addCnt)
	self._sumRechargeDiamond = self._sumRechargeDiamond + addCnt
	self:saveField("_sumRechargeDiamond", self._sumRechargeDiamond)
end

function clsAct:getSumRechargeDiamond()
	return self._sumRechargeDiamond
end

function clsAct:addRealDiamond(addCnt, reasonList)
	assert(addCnt >= 0)
	assert(reasonList[1] == CONST.FLOW_REASON.RECHARGE or reasonList[1] == CONST.FLOW_REASON.WIZ)
	self._realDiamond = self._realDiamond + addCnt
	self:saveField("_realDiamond", self._realDiamond)
end

function clsAct:addGiftDiamond(addCnt, reasonList)
	assert(addCnt >= 0)
	self._giftDiamond = self._giftDiamond + addCnt
	self:saveField("_giftDiamond", self._giftDiamond)
end

function clsAct:addRealDiamondAndSync(addCnt, reasonList)
	self:addRealDiamond(addCnt, reasonList)
	self:syncDiamond()
end

function clsAct:addGiftDiamondAndSync(addCnt, reasonList)
	self:addGiftDiamond(addCnt, reasonList)
	self:syncDiamond()
end

function clsAct:syncDiamond()
	local ptoTbl = {
		diamond = self:getDiamond()
	}
	local fd = self:getFd()
	if fd then
		for_caller.s2c_sync_user_diamond(fd, ptoTbl)	
	end
end

function clsAct:addDiamond(addCnt, reasonList)
	assert(addCnt >= 0)
	self._realDiamond = self._realDiamond + addCnt
	self:saveField("_realDiamond", self._realDiamond)
end

function clsAct:subDiamond(sumSubCnt, reasonList)
	assert(sumSubCnt > 0)
	assert(self:getDiamond() >= sumSubCnt)
	local subReal, subGift = 0, 0
	if self._realDiamond >= sumSubCnt then
		subReal = sumSubCnt
		self._realDiamond = self._realDiamond - sumSubCnt
	else
		subReal = self._realDiamond
		self._realDiamond = 0
		subGift = sumSubCnt - subReal
		self._giftDiamond = self._giftDiamond - subGift
	end
	if subReal > 0 then
		self:saveField("_realDiamond", self._realDiamond)
	end
	if subGift > 0 then
		self:saveField("_giftDiamond", self._giftDiamond)
	end
	-- afterSubDiamond(self, subReal, subGift, extTbl, reasonList)
end

function clsAct:setAndSyncVerifyLogin(token)
	self._token = token
	local fd = self:getFd()
	local ptoTbl = {
		token = token
	}
	for_caller.s2c_verify_login(fd, ptoTbl)	
end

function clsAct:getHeadIcon()
	return self._headIcon
end

function clsAct:setHeadIcon(headIcon)
	self._headIcon = headIcon
	self:saveField("_headIcon", headIcon)
end

function clsAct:getClientPTOInfo()
	return {
		name = self:getName(),
		headIcon = self:getHeadIcon(),
		sex = self:getSex(),
		birthTime = self:getBirthTime(),
	}
end

function clsAct:syncUserBaseInfo()
	local ptoTbl = self:getClientPTOInfo()
	for_caller.s2c_user_base_info(self:getFd(), ptoTbl)
end

function clsAct:getLotteryTimes()
	return self._lotteryTimes
end

function clsAct:setLotteryTimes(lotteryTimes)
	self._lotteryTimes = lotteryTimes
	self:saveField("_lotteryTimes", lotteryTimes)
end
