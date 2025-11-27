
local skynet = require "skynet"

SRV_GROUP_ID = 99
-- 服务器ID
SERVER_ID = skynet.getenv("host_id")

ALLOW_REGISTER = skynet.getenv("allow_register")
LANGUAGE = skynet.getenv("language")
PROFILE = skynet.getenv("profile")
GAME = skynet.getenv("game")

function getServerId()
	return SERVER_ID
end

function isAllowRegister()
	return ALLOW_REGISTER
end

function getCurLanguage()
	return LANGUAGE
end

function getCurLanguage()
	return LANGUAGE
end

function getProfile()
	return PROFILE
end

function getDataBase()
	return string.format("%s%s", GAME, SERVER_ID)
end




