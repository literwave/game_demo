allKeyList = {}
allKeyTbl = {}
allKeyNameTbl = {}

-- 设计思路，colName就是这个模块的变量，这样就不用写枚举字符串了，
-- 这里应该是写在单个agent里的，不应该写在common模块里的，
-- 
local keyDescTbl = {
	{
		key = "ACCOUNT_INFO_KEY",
		keyName = "accountInfoKey",
	},
}

local function tryInitKeyList()
	if next(allKeyList) then
		assert(false)
	end
	local env = getfenv(1)
	for _, info in ipairs(keyDescTbl) do
		table.insert(allKeyList, {
			keyName = info.keyName,
		})
		env[info.key] = info.keyName
	end
	for _, keyInfo in pairs(allKeyList) do
		local keyName = keyInfo.keyName
		assert(not allKeyNameTbl[keyName])
		allKeyNameTbl[keyName] = true
	end
	assert(next(allKeyList))
end

function systemStartUp()
	tryInitKeyList()
	LREDIS.tryInitRedisCon()
end