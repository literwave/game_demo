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
	
end

-- 先全部从库里拿吧
function queryUserId(account, userId)
	local userIdTbl = accountInfoTbl[account]
	if not userIdTbl then
		return
	end
	return userIdTbl[userId]
end

function createAccount(account)
	local userId = MONGO_SLAVE.fetchUserId()
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.accountInfoCol, account, userId}, true)
	return userId
end

function queryAccount(account)
	skynet.call(".mongodb", "lua", "findOne", {
		database = "game",
		collection = MONGO_SLAVE.accountInfoCol,
	})
	return account
end

function sdkLoginOk(loginInfo)
	local account = loginInfo.account
	local userId = loginInfo.userId
	if userId == "" then
		createAccount(account)
		skynet.error("user create", account)
	else
		skynet.error("user load")
		local ret = queryUserId(account, userId)
		if not ret then
			skynet.error("user load error1", account, userId)
			return
		end
		local userTbl = ret.userTbl
		if not userTbl[userId] then
			skynet.error("user load error2", account, userId)
		end
	end
end