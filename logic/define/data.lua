local skynet = require "skynet"
local sharedata = require "skynet.sharedata"
DATA_REPORT = nil
DATA_SERVER_GROUP = nil
DATA_HERO = nil
-- local DATA_NAME_CN = sharedata.query("NameCn")

-- local conf = {
-- 	[CONST.LANGUAGE.CHINESE] = function()
-- 		return DATA_NAME_CN
-- 	end,
-- }

skynet.init(function()
	DATA_HERO = sharedata.query("hero")
	DATA_REPORT = sharedata.query("ReportInfo")
	DATA_SERVER_GROUP = sharedata.query("ServerGroup")
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

local function getLastNameList(language)
	local lastNameTbl = conf[language]()
	return lastNameTbl[1]
end

function getHeroInfoByType(heroType)
	return DATA_HERO[heroType]
end