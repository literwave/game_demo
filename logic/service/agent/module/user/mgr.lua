local skynet = require "skynet"
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

function disconnect(fd)
	local userId = getUserIdByVfd(fd)
	delUserIdByVfd(fd)
	userIdToFd[userId] = nil
end

function isNewUser(userId)
	local user = allUserTbl[userId]
	local isNewUser = false
	if not user then
		local saveTbl = MONGO_SLAVE.loadSingleUserInfo(userId) or {}
		if table.isEmpty(saveTbl) then
			isNewUser = true
		end
		user = USER_BASE.clsUser:New(saveTbl)
		allUserTbl[userId] = user
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

function refLogin(userId, fd)
	userIdToFd[userId] = fd
	fdToUserId[fd] = userId
end

function getGameUserId()
	return MONGO_SLAVE.fetchUserId()
end

function createNewUser(fd, userId, serverId)
	local oci = {
		_userId = userId,
		_birthTime = os.time(),
		_bornServerId = serverId,
	}
	local user = USER_BASE.clsUser:New(oci)
	-- local userName = RANDOM_NAME.genNewUserName()
	-- user:setName(userName)
	user:saveToDB()
	REWARD_MGR.rewardUser(userId, DATA_COMMON.getUserCreateReward())
	-- USER_MGR.updateUserPower(userId, CONST.POWER_TYPE.HERO)
end

function moduleOnUserLogin(user)
	user:onLogin()
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

function __init__()
	for_maker.c2s_heart_beat = onHeartBeat
end