local skynet = require "skynet"

local function getUserTbl(account)
	return LREDIS.getValueByKey(account) or {}
end

function queryUserId(account, userId)
	local userTbl = getUserTbl(account)
	return userTbl[userId]
end

function createAccount(account, userId)
	local userTbl = getUserTbl(account)
	userTbl[userId] = 1
	LREDIS.setValueByKey(account, userTbl)
end

local function fetchUserId()
	return skynet.call(".game_sid", "lua", "fetchUserId")
end

function sdkLoginOk(loginInfo)
	local account = loginInfo.account
	-- local userId = loginInfo.userId
	local userTbl = getUserTbl(account)
	local userId = next(userTbl)
	if not userId then
		skynet.error("user create")
		userId = fetchUserId()
		loginInfo.userId = userId
		createAccount(account, userId)
	end
	-- 先不支持一个账号多个用户，先预留功能吧
	-- if userId == "" then
	-- 	skynet.error("user create")
	-- 	userId = fetchUserId()
	-- 	loginInfo.userId = userId
	-- 	createAccount(account, userId)
	-- else
	-- 	skynet.error("user load")
	-- 	local ret = queryUserId(account, userId)
	-- 	skynet.error("ret: ", ret)
	-- 	assert(ret, "user load error")
	-- end
end