local sharedata = require "skynet.sharedata"
local DATA_REPORT = sharedata.query("ReportInfo")
local DATA_SERVER_GROUP = sharedata.query("ServerGroup")
-- local DATA_NAME_CN = sharedata.query("NameCn")

-- local conf = {
-- 	[CONST.LANGUAGE.CHINESE] = function()
-- 		return DATA_NAME_CN
-- 	end,
-- }

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