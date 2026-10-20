local sharedata = require "skynet.sharedata"

local DATA_HERO = sharedata.query("Hero")
local DATA_REPORT = sharedata.query("ReportInfo")
local DATA_SERVER_GROUP = sharedata.query("ServerGroup")
local DATA_GLOBAL = sharedata.query("Global")
local DATA_BUILD_DETAIL = sharedata.query("BuildingDetail")
local DATA_BUILD_LEVEL = sharedata.query("BuildingLv")
local DATA_BUILD_CONF = sharedata.query("innerCity")
local DATA_HEAD_ICON = sharedata.query("HeadIcon")
local DATA_LOTTERY = sharedata.query("Lottery")
local DATA_ITEM = sharedata.query("Item")
-- local DATA_NAME_CN = sharedata.query("NameCn")

-- local conf = {
-- 	[CONST.LANGUAGE.CHINESE] = function()
-- 		return DATA_NAME_CN
-- 	end,
-- }

-- 二次处理配置表的内容
initBuildList = {}
local function initConfigData()
	for _, conf in pairs(DATA_BUILD_DETAIL) do
		table.insert(initBuildList, conf.InitLev)
	end
end
initConfigData()

function getValueByKey(key)
	return DATA_GLOBAL[key].value2
end

local function getReportInfo(reportId)
	return DATA_REPORT[reportId]
end

local function getReportInfoBySrvGroup(groupId)
	local reportId = DATA_SERVER_GROUP[groupId].reportId
	return getReportInfo(reportId)
end

function getLoginAddressBySrvGroup(groupId)
	local info = getReportInfoBySrvGroup(groupId)
	return info.LoginDomain, info.HttpPort, info.HttpsPort
end

function getFirstNameList(language)
	local nameTbl = conf[language]()
	return nameTbl[1]
end

function getHeroInfoByType(heroType)
	return DATA_HERO[heroType]
end

function getItemKindByType(itemType)
	local itemKind = DATA_ITEM[itemType].itemKind
	return itemKind
end

function getInitialBuildList()
	return initBuildList
end

function getBuildTypeById(bid)
	return DATA_BUILD_CONF.builds[bid].buildType
end

function getLotteryCommonPools(useLotteryTimes)
end

function getLotteryHeroPools(useLotteryTimes)
end

function getUpHeroItemLotteryTimes(useLotteryTimes)
end

function getLotteryCost(useLotteryTimes)
end

function canOverlap(itemType)
	return DATA_ITEM[itemType].canOverlap == 1
end

function getItemOverlap(itemType)
	return DATA_ITEM[itemType].Overlap
end

function getItemKindByType(itemType)
	return DATA_ITEM[itemType].Kind
end

function canLockMail()
end

function getQueueCapacity()
	return 5
end

function getBuildLevelUpLimit()
	return {}
end

function getBuildCreateLimit()
	return {}
end

function getBuildMaxLevel(bType)
	return 1
end