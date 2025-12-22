allUserTbl = {
	-- [userId] = userObj
}
fdToUserId = {
	-- [vfd] = userId
}
userIdToFd = {
	-- [userId] = vfd
}

function getUserById(UserId)
	return allUserTbl[UserId]
end

function getUserIdByVfd(fd)
	return fdToUserId[fd]
end

function delUserIdByVfd(fd)
	fdToUserId[fd] = nil
end

function getFdByUserId(userId)
	return userIdToFd[userId]
end

function getUserByFd(fd)
	local userId = fdToUserId[fd]
	return allUserTbl[userId]
end

function getGateSrvByFd(fd)
	local user = getUserByFd(fd)
	local gateSrv = user:getGateSrv()
	return gateSrv
end

local function moduleOnUserLogout(userId)
	BUILD_MGR.onUserLogout(userId)
end

function disconnect(fd, userId)
	local user = getUserById(userId)
	user:saveToDB()
	allUserTbl[userId] = nil
	delUserIdByVfd(fd)
	userIdToFd[userId] = nil
	moduleOnUserLogout(userId)
end

function isNewUser(userId)
	local user = allUserTbl[userId]
	local isNewUser = false
	if not user then
		local saveTbl = MONGO_SLAVE.loadSingleUserInfo(userId) or {}
		if table.isEmpty(saveTbl) then
			isNewUser = true
		end
	end
	return isNewUser
end

function tryInitUser(userId)
	local user = allUserTbl[userId]
	if not user then
		local saveTbl = MONGO_SLAVE.loadSingleUserInfo(userId) or {}
		user = USER_BASE.clsUser:New(saveTbl)
		allUserTbl[userId] = user
	end
	return user
end

function refLogin(userId, fd, user)
	userIdToFd[userId] = fd
	fdToUserId[fd] = userId
	allUserTbl[userId] = user
end

function getGameUserId()
	return MONGO_SLAVE.fetchUserId()
end

function createNewUser(gateSrv, fd, userId, serverId)
	local oci = {
		_userId = userId,
		_birthTime = os.time(),
		_bornServerId = serverId,
	}
	local user = USER_BASE.clsUser:New(oci)
	refLogin(userId, fd, user)
	-- user:setFd(fd)
	-- print("gateSrv", gateSrv)
	-- user:setGateSrv(gateSrv)
	-- local userName = RANDOM_NAME.genNewUserName()
	-- user:setName(userName)
	user:saveToDB()
	user:setFd(fd)
	user:setGateSrv(gateSrv)
	-- WORK_QUEUE_MGR.initUserWorkQueue(userId)
	REWARD_MGR.rewardUser(userId, DATA_COMMON.getUserCreateReward())
	return user
	-- USER_MGR.updateUserPower(userId, CONST.POWER_TYPE.HERO)
end

function moduleOnUserLogin(user, isFirstLogin)
	user:onLogin()
	BUILD_MGR.onUserLogin(user, isFirstLogin)
end

local function kickUser(fd, userId)
	disconnect(fd)
end

function detectUserHeartBeat(userId)
	local user = allUserTbl[userId]
	if not user then
		return
	end
	local lastHeartBeatTime = user:getHeartBeatTime()
	if os.time() - lastHeartBeatTime > CONST.USER_HEART_BEAT_TIMEOUT then
		local fd = getFdByUserId(userId)
		kickUser(fd, userId)
	end
end

local function onHeartBeat(fd)
	local user = USER_MGR.getUserByFd(fd)
	user:setHeartBeatTime(os.time())
end

local function onUserBaseinfo(fd)
	local user = USER_MGR.getUserByFd(fd)
	user:syncUserBaseInfo()
end

local function OnUserCreate(fd, packet)
	local sex = packet.sex
	local name = packet.name
	if sex < CONST.SEX_MAN or sex > CONST.SEX_WOMAN then
		return
	end
	local user = USER_MGR.getUserByFd(fd)
	if user:getSex() ~= CONST.SEX_NONE then
		return
	end
	user:setSex(sex)
	user:setName(name)
	for_caller.s2c_user_create(fd, packet)
end

function __init__()
	for_maker.c2s_heart_beat = onHeartBeat
	for_maker.c2s_user_base_info = onUserBaseinfo
	for_maker.c2s_user_create = OnUserCreate
end