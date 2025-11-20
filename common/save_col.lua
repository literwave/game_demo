allColList = {}
allColTbl = {}
allColNameTbl = {}

local colDescTbl = {
	{
		colName = "userInfoCol",
	},
}

local function tryInitColList()
	if next(allColList) then
		assert(false)
	end
	local env = getfenv(1)
	local gid = 1
	for _, info in ipairs(colDescTbl) do
		local colName = info.colName
		table.insert(allColList, {
			colIdx = gid,
			colName = colName,
		})
		env[info.colName] = gid
		gid = gid + 1
	end
	for _, colInfo in pairs(allColList) do
		local colName = colInfo.colName
		local colIdx = colInfo.colIdx
		assert(not allColNameTbl[colName])
		assert(not allColTbl[colIdx])
		allColNameTbl[colName] = colIdx
		allColTbl[colIdx] = colName
	end
	assert(next(allColList))
end

function initMongo()
	tryInitColList()
end