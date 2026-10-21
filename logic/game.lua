
local skynet = require "skynet"

SRV_GROUP_ID = 99
-- 服务器ID
SERVER_ID = skynet.getenv("host_id")

ALLOW_REGISTER = skynet.getenv("allow_register")
LANGUAGE = skynet.getenv("language")
PROFILE = skynet.getenv("profile")
GAME = skynet.getenv("game")

function get_server_id()
	return SERVER_ID
end

function is_allow_register()
	return ALLOW_REGISTER
end

function get_cur_language()
	return LANGUAGE
end

function get_cur_language()
	return LANGUAGE
end

function get_profile()
	return PROFILE
end

function get_data_base()
	return string.format("%s%s", GAME, SERVER_ID)
end

function get_login_lock_key()
	return "login_lock"
end

function get_shut_down_time()
	return 0
end