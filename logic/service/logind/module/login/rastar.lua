local skynet = require "skynet"
local http = require "http.httpc"
local dns = require "dns"

function on_ret(code, ret, param_tbl)
	if code ~= 200 then
		LOG.debug_print(string.format("tag=rastarLoginErr1:%s,%s", code, sys.dump(ret)))
		local vfd = param_tbl.vfd
		for_caller.c_kick_user(vfd, CONST.KICK_LOGIN_ERROR)
		-- 发给网关踢掉vfd
		lnetcom.kick_vfd(vfd)
		return
	end
	local tbl = json4_lua.safe_decode(ret)
	if tbl.code ~= 200 then -- sdk 返回失败
		local vfd = param_tbl.vfd
		for_caller.c_kick_user(vfd, CONST.KICK_LOGIN_ERROR)
		-- 发给网关踢掉vfd
		lnetcom.kick_vfd(vfd)
		LOG.debug_print(string.format("tag=rastarLoginErr2:%s", sys.dump(ret)))
		return
	end

	local openid = tbl.data.user_info.openid
	local acc = FUNCLIB.gen_sdk_login_account(param_tbl.loginInfo.accountType, openid)
	param_tbl.account = acc
	param_tbl.openid = openid
	local login_info = param_tbl.loginInfo
	param_tbl.sdk_param_tbl = {
		app_id = login_info.appid,
		cch_id = login_info.cchid,
		access_token = login_info.token,
		session_id = login_info.rastarSessionId,
		app_version = login_info.appVersion,
	}
	USER_MGR.sdk_login_ok(param_tbl)
end

local url = "https://v2accesstoken.rastargame.com/sy/v3/verify"
function on_user_login(param_tbl)
	local login_info = param_tbl.loginInfo
	local body = {
		ts = math.ceil(skynet.time() / 1000),
		access_token = login_info.token,
		app_id = login_info.appid,
		cch_id = login_info.cchid,
		--sign_type = "md5",
		--nonce = nil,
		--sign = nil,
	}
	local dns_server = dns.server()
	LOG._debug(dns_server)
	local data = json4_lua.encode(body)
	local bg_url = string.format("/gameSrv/rastarLogin?url=%s", url)
	local domain = DATA_COMMON.get_login_address_by_srv_group(GAME.SRV_GROUP_ID)
	local code, ret_data = http.post(domain, bg_url, data)
	on_ret(code, ret_data, param_tbl)
end

