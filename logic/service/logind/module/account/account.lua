local skynet = require "skynet"

-- 这里要加载userId -> account的映射
userIdToAccount = {
	-- [userId] = account
}
accountInfoTbl = {
	-- {
	-- 	[account][userId] = true
	-- }
}

function loadData()
	accountInfoTbl = MONGO_SLAVE.loadAllAccountInfo()
end

function saveData()
	MONGO_SLAVE.saveAccountInfo()
end

function queryUserId(account, userId)
	local userIdTbl = accountInfoTbl[account]
	if not userIdTbl then
		return
	end
	return userIdTbl[userId]
end

function createAccount(account, userId)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.ACCOUNT_INFO_COL, account, userId}, true)
end

function sdkLoginOk(loginInfo)
	local account = loginInfo.account
	local userId = loginInfo.userId
	if userId == "" then
		skynet.error("user create", account)
	else
		skynet.error("user load")
		local ret = queryUserId(account, userId)
		if not ret then
			skynet.error("user load error", account, userId)
			return
		end
	end
end