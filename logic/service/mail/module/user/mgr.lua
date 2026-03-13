fdToUserId = {
	-- [vfd] = userId
}
userIdToFd = {
	-- [userId] = fd
}
fdToGateSrv = {
	-- [fd] = gateSrv
}

function getUserIdByVfd(fd)
	return fdToUserId[fd]
end

function delUserIdByVfd(fd)
	fdToUserId[fd] = nil
end

function getFdByUserId(userId)
	return userIdToFd[userId]
end

function getUserIdByFd(fd)
	return fdToUserId[fd]
end

function getGateSrvByFd(fd)
	return fdToGateSrv[fd]
end

local function moduleOnUserLogout(userId)
end

function disconnect(fd, userId)
	delUserIdByVfd(fd)
	userIdToFd[userId] = nil
	fdToGateSrv[fd] = nil
	moduleOnUserLogout(userId)
end

function refLogin(userId, fd, gateSrv)
	userIdToFd[userId] = fd
	fdToUserId[fd] = userId
	fdToGateSrv[userId] = gateSrv
end

function moduleOnUserLogin(user, isFirstLogin)
	QUEUE_MGR.onUserLogin(user, isFirstLogin)
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