allUserBuildTbl = {
--[[
	[userId] = {
		[bid] = build,
	}
]]
}

function refBuild(build)
	local userId = build:getUserId()
	local bid = build:getBid()
	if not allUserBuildTbl[userId] then
		allUserBuildTbl[userId] = {}
	end
	allUserBuildTbl[userId][bid] = build
end

function unrefBuild(build)
	local userId = build:getUserId()
	local bid = build:getBid()
	if allUserBuildTbl[userId] then
		allUserBuildTbl[userId][bid] = nil
		if table.isEmpty(allUserBuildTbl[userId]) then
			allUserBuildTbl[userId] = nil
		end
	end
end

local function createBuild(oci)
	return BUILD_BASE.clsBuild:New(oci)
end

function persistUserBuilds(userId)
	assert(userId)
	local buildTbl = allUserBuildTbl[userId] or {}
	local bagData = {}
	for bid, build in pairs(buildTbl) do
		bagData[bid] = build._data
	end
	local doc = ORM.create(ORM.CLS_USER_BUILD_DOC, { _builds = bagData })
	MONGO_SLAVE.saveDoc(MONGO_SLAVE.USER_BUILD_COL, userId, ORM.dump(doc))
end

local function tryInitUserBuilds(userId)
	if not allUserBuildTbl[userId] then
		allUserBuildTbl[userId] = {}
		local raw = MONGO_SLAVE.loadSingleUserBuild(userId) or {}
		local doc = ORM.create(ORM.CLS_USER_BUILD_DOC, raw)
		for _, buildData in pairs(doc._builds) do
			if ORM.is_cls(buildData, ORM.CLS_BUILD_DATA) then
				createBuild(buildData)
			end
		end
	end
	return allUserBuildTbl[userId]
end

function getBuildByBid(userId, bid)
	local buildTbl = tryInitUserBuilds(userId)
	return buildTbl[bid]
end

local function initUserBuilds(userId)
	tryInitUserBuilds(userId)
	if next(allUserBuildTbl[userId]) then
		return
	end
	for _, initLev in ipairs(DATA_COMMON.getInitialBuildList()) do
		if type(initLev) == "table" then
			for bid, level in pairs(initLev) do
				createBuild({
					_userId = userId,
					_bid = bid,
					_level = level,
				})
			end
		end
	end
	persistUserBuilds(userId)
end

function onUserLogin(user, isFirstLogin)
	local userId = user:getUserId()
	-- 无建筑时补初始建筑（含首次创角中途失败、未 persist 的号）
	initUserBuilds(userId)
	syncAllBuildToClient(userId)
end

function onUserLogout(userId)
	if allUserBuildTbl[userId] then
		persistUserBuilds(userId)
		allUserBuildTbl[userId] = nil
	end
end

function syncAllBuildToClient(userId)
	local fd = USER_MGR.getFdByUserId(userId)
	if not fd then
		return
	end
	local buildTbl = tryInitUserBuilds(userId)
	for _, build in pairs(buildTbl) do
		build:syncToClient()
	end
	for_caller.s2c_req_all_build_end(fd, {})
end

local function onCreateBuild(fd, packet)
	local userId = USER_MGR.getUserIdByFd(fd)
	local bid = packet.bid
	if getBuildByBid(userId, bid) then
		return
	end
	if not DATA_COMMON.getBuildTypeById(bid) then
		return
	end
	if not packet.isInstant then
		local ok = QUEUE_MGR.tryAddNewWork(userId, bid)
		if not ok then
			return
		end
	end
	local build = createBuild({
		_userId = userId,
		_bid = bid,
		_level = 1,
	})
	build:saveToDB()
	build:syncToClient()
end

local function onUpBuild(fd, packet)
	local userId = USER_MGR.getUserIdByFd(fd)
	local build = getBuildByBid(userId, packet.bid)
	if not build then
		return
	end
	local maxLv = DATA_COMMON.getBuildMaxLevel(build:getBuildType())
	if build:getLevel() >= maxLv then
		return
	end
	if not packet.isInstant then
		local ok = QUEUE_MGR.tryAddNewWork(userId, packet.bid)
		if not ok then
			return
		end
	end
	build:setLevel(build:getLevel() + 1)
	build:syncToClient()
end

function __init__()
	for_maker.c2s_create_build = onCreateBuild
	for_maker.c2s_up_build = onUpBuild
end
