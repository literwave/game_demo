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

function sdkLoginOk(loginInfo)
	local account = loginInfo.account
	local userId = loginInfo.userId
	if userId == "" then
		skynet.error("user create", account)
	else
		skynet.error("user load")
		local ret = queryUserId(account, userId)
		assert(ret, "user load error")
	end
end