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

function getVfdByUserId(userId)
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
		local saveTbl = MONGO_SLAVE.loadSingleUserInfo(userId)
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
	local userId = skynet.call(".game_sid", "lua", "fetchUserId")
	return userId
end

function createNewUser(fd)
	local userId = getGameUserId()
	skynet.error("userId: ", userId)
	local oci = {
		_userId = userId,
		_birthTime = os.time(),
	}
	local user = USER_BASE.clsUser:New(oci)
	-- local userName = RANDOM_NAME.genNewUserName()
	-- user:setName(userName)
	allUserTbl[userId] = user
	fdToUserId[fd] = userId
	user:saveToDB()

	-- 这里送一个武将？
	-- HERO_MGR.addHero(userId, , {CONST.FLOW_REASON.NEW_USER})
	-- USER_MGR.updateUserPower(userId, CONST.POWER_TYPE.HERO)
	return user
end

local function moduleOnUserLogin(user)
	user:onLogin()
end
