userHeroTbl = {}
--[[
	[userId] = {
		[heroType] = hero,
	}
--]]

local function refHero(hero)
	local userId = hero:getUserId()
	if not userHeroTbl[userId] then
		userHeroTbl[userId] = {}
	end
	local heroType = hero:getHeroType()
	userHeroTbl[userId][heroType] = hero
end

function createHero(oci)
	local hero = CLS_HERO.clsHero:New(oci)
	refHero(hero)
	return hero
end

local function tryInitUserHeroData(userId)
	if not ORM.get(MONGO_SLAVE.COL.USER_HERO, userId) then
		local raw = MONGO_SLAVE.commonLoadSingle(MONGO_SLAVE.COL.USER_HERO, userId) or {}
		local doc = ORM.create(ORM.CLS_USER_HERO_DOC, raw)
		ORM.hold(doc, MONGO_SLAVE.COL.USER_HERO, userId)
		userHeroTbl[userId] = {}
		for _, heroData in pairs(doc._heroes) do
			if ORM.is_cls(heroData, ORM.CLS_HERO_DATA) then
				createHero(heroData)
			end
		end
	end
	return userHeroTbl[userId]
end

function getHeroTblByUserId(userId)
	return tryInitUserHeroData(userId)
end

function getHeroByType(userId, heroType)
	local heroTbl = tryInitUserHeroData(userId)
	return heroTbl[heroType]
end

function saveData()
	MONGO_SLAVE.flush()
end

function addHero(userId, heroType, reasonList)
	assert(userId)
	assert(DATA_COMMON.getHeroInfoByType(heroType))
	local exist = getHeroByType(userId, heroType)
	if exist then
		return exist
	end
	tryInitUserHeroData(userId)
	local oci = {
		_userId = userId,
		_heroType = heroType,
		_newTag = true,
		_level = 1,
		_star = 1,
	}
	local hero = createHero(oci)
	hero:syncToClient()
	return hero
end

local function OnReqAllHeroBaseInfo(fd)
	local heroTbl = getHeroTblByUserId(USER_MGR.getUserIdByFd(fd))
	local heroInfoList = {}
	for _, hero in pairs(heroTbl) do
		table.insert(heroInfoList, hero:getHeroPTOBaseInfo())
	end
	for_caller.s2c_req_all_hero_base_info(fd, {heroInfoList = heroInfoList})
end

function __init__()
	for_maker.c2s_req_all_hero_base_info = OnReqAllHeroBaseInfo
end
