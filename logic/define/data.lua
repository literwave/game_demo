local skynet = require "skynet"
local sharedata = require "skynet.sharedata"
DATA_REPORT = nil
DATA_SERVER_GROUP = nil
DATA_HERO = nil
DATA_BUILD_DETAIL = nil
DATA_BUILD_LEVEL = nil
DATA_BUILD_CONF = nil
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

skynet.init(function()
	DATA_HERO = sharedata.query("Hero")
	DATA_REPORT = sharedata.query("ReportInfo")
	DATA_SERVER_GROUP = sharedata.query("ServerGroup")
	DATA_GLOBAL = sharedata.query("Global")
	DATA_HERO_DEBRIS = sharedata.query("HeroDebris")
	DATA_BUILD_DETAIL = sharedata.query("BuildingDetail")
	DATA_BUILD_LEVEL = sharedata.query("BuildingLv")
	DATA_BUILD_CONF = sharedata.query("innerCity")
	initConfigData()
end)

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

function getUserCreateReward()
	return DATA_GLOBAL[1].value2
end

function getItemKindByType(itemType)
	local itemKind = DATA_ITEM[itemType].itemKind
	return itemKind
end

function getInitialBuildList()
	return initBuildList
end

function getBuildTypeById(bid)
	print(table2str(DATA_BUILD_CONF))
	return DATA_BUILD_CONF.builds[bid].buildType
end

function getInitialBuildFacilityList(bid)
	return {}
end