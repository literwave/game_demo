local skynet = require "skynet"

-- 这里要加载userId -> account的映射
userIdToAccount = {
	-- [userId] = account
}
accountToUserId = {
	-- [account] = userId
}

function loadData()
	
end

function saveData()
	
end

-- 先全部从库里拿吧
function queryUserId(account)
	local ret = skynet.call(".mongodb", "lua", "findOne", {
		database = "game",
		collection = "login",
		query = {_id = account},
	})
	return ret
end

function createAccount(account, userId)
	skynet.call(".mongodb", "lua", "update", {
		database = "game",
		collection = "login",
		selector = {_id = account},
		update = {
			["$setOnInsert"] = {_id = account, userTbl = {}},  -- 仅在插入时设置初始值
			["$set"] = {["userTbl." .. userId] = true}  -- 添加或更新 userId
		},
		upsert = true,  -- 如果文档不存在则创建
		multi = false   -- 只更新一个文档
	})
	return userId
end

function queryAccount(userId)
	skynet.call(".mongodb", "lua", "findOne", {
		database = "game",
		collection = "login",
		doc = {userId = userId}
	})
	return userId
end

function sdkLoginOk(loginInfo)
	local account = loginInfo.account
	local userId = loginInfo.userId
	if userId == "" then
		skynet.error("user create", account)
	else
		skynet.error("user load")
		local ret = queryUserId(account)
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