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
	return vfdToUserId[fd]
end

function delUserIdByVfd(fd)
	fdToUserId[fd] = nil
end

function getFdByUserId(userId)
	return userIdToFd[userId]
end

function disconnect(fd)
	local userId = getUserIdByVfd(fd)
	delUserIdByVfd(fd)
	userIdToFd[userId] = nil
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

local function refLogin(userId, fd)
	userIdToFd[userId] = fd
	fdToUserId[fd] = userId
end

function getGameUserId()
	return MONGO_SLAVE.fetchUserId()
end

function createNewUser(fd)
	local userId = getGameUserId()
	local oci = {
		_userId = userId,
		_birthTime = os.time(),
	}
	local user = USER_BASE.clsUser:New(oci)
	-- local userName = RANDOM_NAME.genNewUserName()
	-- user:setName(userName)
	allUserTbl[userId] = user
	refLogin(userId, fd)
	user:saveToDB()
	-- 这里送一个卡牌？
	-- HERO_MGR.addHero(userId, , {CONST.FLOW_REASON.NEW_USER})
	-- USER_MGR.updateUserPower(userId, CONST.POWER_TYPE.HERO)
	return user
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
	for_maker.c2sheartbeat = onHeartBeat
end