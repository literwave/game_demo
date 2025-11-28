local skynet = require "skynet"
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
	if not userHeroTbl[userId] then
		local dataTbl = MONGO_SLAVE.loadSingleUserHero(userId) or {}
		userHeroTbl[userId] = {}
		for _, oci in pairs(dataTbl) do
			createHero(oci)
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
	local saveTbl = {}
	for userId, heroTbl in pairs(userHeroTbl) do
		local heroInfoTbl = {}
		for heroType, hero in pairs(heroTbl) do
			local info = {}
			hero:serialize(info)
			heroInfoTbl[heroType] = info
		end
		saveTbl[userId] = heroInfoTbl
	end
	MONGO_SLAVE.saveManyUserHero(saveTbl)
end

function addHero(userId, heroType, reasonList)
	assert(userId)
	assert(DATA_COMMON.getHeroInfoByType(heroType))
	assert(not getHeroByType(userId, heroType))
	tryInitUserHeroData(userId)
	local oci = {
		_userId = userId,
		_heroType = heroType,
		_newTag = true,
	}
	local hero = createHero(oci)
	hero:saveToDB()
	hero:syncToClient()
	return hero
end