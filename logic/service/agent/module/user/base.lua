clsUser = clsObject:Inherit()

function clsUser:__init__(oci)
	Super(clsUser).__init__(self, oci)
	self._data = ORM.create(ORM.CLS_USER_DATA, oci)
	-- 运行时字段，不落库
	self._loginAddr = nil
	self._fd = nil
	self._heartBeatTime = nil
	self._gateSrv = nil
	self._token = nil
	self._account = nil
end

-- 方案 A：子树更新，路径只允许 string 字段名（无 @、无数字段）
function clsUser:saveField(field)
	assert(type(field) == "string", "saveField only accepts string field name")
	local userId = self._data._userId
	local value = ORM.dump_field(self._data, field)
	MONGO_SLAVE.saveDocField(MONGO_SLAVE.USER_INFO_COL, userId, field, value)
end

function clsUser:saveToDB()
	MONGO_SLAVE.saveDoc(MONGO_SLAVE.USER_INFO_COL, self._data._userId, ORM.dump(self._data))
end

function clsUser:getUserId()
	return self._data._userId
end

function clsUser:isOnline()
	return self:getFd() ~= nil
end

function clsUser:getBirthTime()
	return self._data._birthTime
end

function clsUser:getName()
	return self._data._name
end

function clsUser:setName(name)
	self._data._name = name
	self:saveField("_name")
end

function clsUser:getSex()
	return self._data._sex
end

function clsUser:setSex(sex)
	self._data._sex = sex
	self:saveField("_sex")
end

function clsUser:getResTbl()
	return self._data._resTbl
end

function clsUser:getResNum(resType)
	return self._data._resTbl[resType] or 0
end

function clsUser:addRes(resType, num)
	local resNum = self:getResNum(resType)
	self._data._resTbl[resType] = num + resNum
end

function clsUser:syncRes(resTypeList)
	local resList = {}
	for _, resType in ipairs(resTypeList) do
		table.insert(resList, makeCommonPtoTbl(resType, self:getResNum(resType)))
	end
	local fd = self:getFd()
	if fd then
		for_caller.s2c_sync_user_res_list(fd, {resList = resList})
	end
end

function clsUser:setSdkParamTbl(paramTbl)
	-- 归一成 <string,string>，与 SdkParamMap 一致
	local tbl = {}
	if paramTbl then
		for k, v in pairs(paramTbl) do
			tbl[tostring(k)] = tostring(v)
		end
	end
	self._data._sdkParamTbl = tbl
	self:saveField("_sdkParamTbl")
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

function clsUser:getGateSrv()
	return self._gateSrv
end

function clsUser:setGateSrv(gateSrv)
	self._gateSrv = gateSrv
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

function clsUser:setHeartBeatTime(time)
	self._heartBeatTime = time
end

function clsUser:setAndSyncHeartBeatTime(time)
	self:setHeartBeatTime(time)
	local fd = self:getFd()
	local ptoTbl = {
		heartBeatTime = time
	}
	for_caller.s2c_heart_beat(fd, ptoTbl)
end

function clsUser:onLogin()
	self:setLoginTime(os.time())
end

function clsUser:setLoginTime(time)
	self._data._loginTime = time
	self:saveField("_loginTime")
end

function clsUser:getLoginTime()
	return self._data._loginTime
end

function clsUser:setBornServerId(serverId)
	self._data._bornServerId = serverId
	self:saveField("_bornServerId")
end

function clsUser:getDiamond()
	return self._data._realDiamond + self._data._giftDiamond
end

function clsUser:getRealDiamond()
	return self._data._realDiamond
end

function clsUser:getGiftDiamond()
	return self._data._giftDiamond
end

function clsUser:addSumRechargeDiamond(addCnt)
	self._data._sumRechargeDiamond = self._data._sumRechargeDiamond + addCnt
	self:saveField("_sumRechargeDiamond")
end

function clsUser:getSumRechargeDiamond()
	return self._data._sumRechargeDiamond
end

function clsUser:addRealDiamond(addCnt, reasonList)
	assert(addCnt >= 0)
	assert(reasonList[1] == CONST.FLOW_REASON.RECHARGE or reasonList[1] == CONST.FLOW_REASON.WIZ)
	self._data._realDiamond = self._data._realDiamond + addCnt
	self:saveField("_realDiamond")
end

function clsUser:addGiftDiamond(addCnt, reasonList)
	assert(addCnt >= 0)
	self._data._giftDiamond = self._data._giftDiamond + addCnt
	self:saveField("_giftDiamond")
end

function clsUser:addRealDiamondAndSync(addCnt, reasonList)
	self:addRealDiamond(addCnt, reasonList)
	self:syncDiamond()
end

function clsUser:addGiftDiamondAndSync(addCnt, reasonList)
	self:addGiftDiamond(addCnt, reasonList)
	self:syncDiamond()
end

function clsUser:syncDiamond()
	local ptoTbl = {
		diamond = self:getDiamond()
	}
	local fd = self:getFd()
	if fd then
		for_caller.s2c_sync_user_diamond(fd, ptoTbl)
	end
end

function clsUser:addDiamond(addCnt, reasonList)
	assert(addCnt >= 0)
	self._data._realDiamond = self._data._realDiamond + addCnt
	self:saveField("_realDiamond")
end

function clsUser:subDiamond(sumSubCnt, reasonList)
	assert(sumSubCnt > 0)
	assert(self:getDiamond() >= sumSubCnt)
	local subReal, subGift = 0, 0
	if self._data._realDiamond >= sumSubCnt then
		subReal = sumSubCnt
		self._data._realDiamond = self._data._realDiamond - sumSubCnt
	else
		subReal = self._data._realDiamond
		self._data._realDiamond = 0
		subGift = sumSubCnt - subReal
		self._data._giftDiamond = self._data._giftDiamond - subGift
	end
	if subReal > 0 then
		self:saveField("_realDiamond")
	end
	if subGift > 0 then
		self:saveField("_giftDiamond")
	end
end

function clsUser:setAndSyncVerifyLogin(token)
	self._token = token
	local fd = self:getFd()
	local ptoTbl = {
		token = token
	}
	for_caller.s2c_verify_login(fd, ptoTbl)
end

function clsUser:getHeadIcon()
	return self._data._headIcon
end

function clsUser:setHeadIcon(headIcon)
	self._data._headIcon = headIcon
	self:saveField("_headIcon")
end

function clsUser:getClientPTOInfo()
	return {
		name = self:getName(),
		headIcon = self:getHeadIcon(),
		sex = self:getSex(),
		birthTime = self:getBirthTime(),
	}
end

function clsUser:syncUserBaseInfo()
	local ptoTbl = self:getClientPTOInfo()
	for_caller.s2c_user_base_info(self:getFd(), ptoTbl)
end

function clsUser:getLotteryTimes()
	return self._data._lotteryTimes
end

function clsUser:setLotteryTimes(lotteryTimes)
	self._data._lotteryTimes = lotteryTimes
	self:saveField("_lotteryTimes")
end
