allColList = {}
allColTbl = {}
allColNameTbl = {}

-- 设计思路，colName就是这个模块的变量，这样就不用写枚举字符串了，
-- 这里应该是写在单个agent里的，不应该写在common模块里的，
-- 
local colDescTbl = {
	{
		colKey = "USER_INFO_COL",
		colName = "userInfoCol",
	},
	{
		colKey = "USER_HERO_COL",
		colName = "userHeroCol",
	},
	{
		colKey = "USER_BUILD_COL",
		colName = "userBuildCol",
	},
	{
		colKey = "WORK_QUEUE_COL",
		colName = "workQueueCol"
	}
}

local function tryInitColList()
	if next(allColList) then
		assert(false)
	end
	local env = getfenv(1)
	for _, info in ipairs(colDescTbl) do
		local colName = info.colName
		table.insert(allColList, {
			colName = colName,
		})
		env[info.colKey] = info.colName
	end
	for _, colInfo in pairs(allColList) do
		local colName = colInfo.colName
		assert(not allColNameTbl[colName])
		allColNameTbl[colName] = true
	end
	assert(next(allColList))
end

function initAgentMongo()
	tryInitColList()
end