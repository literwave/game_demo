local skynet = require "skynet"

function queryUserId(account, userId)
	local userTbl = LREDIS.getValueByKey(account) or {}
	return userTbl[userId]
end

function createAccount(account, userId)
	local userTbl = LREDIS.getValueByKey(account) or {}
	userTbl[userId] = 1
	LREDIS.setValueByKey(account, userTbl)
end

local function fetchUserId()
	return skynet.call(".game_sid", "lua", "fetchUserId")
end

function sdkLoginOk(loginInfo)
	local account = loginInfo.account
	local userId = loginInfo.userId
	if userId == "" then
		skynet.error("user create")
		userId = fetchUserId()
		loginInfo.userId = userId
		createAccount(account, userId)
	else
		skynet.error("user load")
		local ret = queryUserId(account, userId)
		skynet.error("ret: ", ret)
		assert(ret, "user load error")
	end
end