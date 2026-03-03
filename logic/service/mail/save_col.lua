allColList = {}
allColTbl = {}
allColNameTbl = {}

-- 设计思路，colName就是这个模块的变量，这样就不用写枚举字符串了，
local colDescTbl = {
	{
		colKey = "MAIL_COL",
		colName = "mailCol",USER_MAIL_COL
	},
	{
		colKey = "USER_MAIL_COL",
		colName = "userMailCol",
	},
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

function initMailMongo()
	tryInitColList()
end