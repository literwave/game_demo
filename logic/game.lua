
local skynet = require "skynet"

SRV_GROUP_ID = 99
-- 服务器ID
SERVER_ID = tonumber(skynet.getenv("host_id"))

ALLOW_REGISTER = skynet.getenv("allow_register")
LANGUAGE = skynet.getenv("language")
PROFILE = skynet.getenv("profile")
GAME = skynet.getenv("game")

-- 北京时间 "2026-10-01 00:00:00"
local function parse_time(str)
	local y, m, d, h, mi, s = string.match(str or "", "^(%d+)-(%d+)-(%d+)%s+(%d+):(%d+):(%d+)$")
	if not y then
		return
	end
	return TIME.os_bj_sec_by_tbl({
		year = tonumber(y),
		month = tonumber(m),
		day = tonumber(d),
		hour = tonumber(h),
		min = tonumber(mi),
		sec = tonumber(s),
	})
end

-- 本文件比 TIME 先 import，第一次用到时才解析配置
config_open_time = nil
-- GM 改过的开服时间，只在内存里，重启后回到配置
gm_open_time = nil

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

function get_open_time()
	if gm_open_time then
		return gm_open_time
	end
	if not config_open_time then
		config_open_time = parse_time(skynet.getenv("open_time"))
	end
	local t = config_open_time
	assert(t, "config open_time missing or bad format, need \"YYYY-MM-DD HH:MM:SS\"")
	return t
end

-- 传 nil 恢复成配置里的
function set_open_time(t)
	gm_open_time = t
end

function get_shut_down_time()
	return 0
end