local skynet = require "skynet"
local http = require "http.httpc"
local dns = require "dns"

function onRet(code, ret, paramTbl)
	if code ~= 200 then
		LOG.debugPrint(string.format("tag=rastarLoginErr1:%s,%s", code, sys.dump(ret)))
		local vfd = paramTbl.vfd
		for_caller.c_kick_user(vfd, CONST.KICK_LOGIN_ERROR)
		-- 发给网关踢掉vfd
		lnetcom.kickVfd(vfd)
		return
	end
	local tbl = JSON4LUA.safeDecode(ret)
	if tbl.code ~= 200 then -- sdk 返回失败
		local vfd = paramTbl.vfd
		for_caller.c_kick_user(vfd, CONST.KICK_LOGIN_ERROR)
		-- 发给网关踢掉vfd
		lnetcom.kickVfd(vfd)
		LOG.debugPrint(string.format("tag=rastarLoginErr2:%s", sys.dump(ret)))
		return
	end

	local openid = tbl.data.user_info.openid
	local acc = FUNCLIB.genSdkLoginAccount(paramTbl.loginInfo.accountType, openid)
	paramTbl.account = acc
	paramTbl.openid = openid
	local loginInfo = paramTbl.loginInfo
	paramTbl.sdkParamTbl = {
		app_id = loginInfo.appid,
		cch_id = loginInfo.cchid,
		access_token = loginInfo.token,
		session_id = loginInfo.rastarSessionId,
		app_version = loginInfo.appVersion,
	}
	USER_MGR.sdkLoginOk(paramTbl)
end

local url = "https://v2accesstoken.rastargame.com/sy/v3/verify"
function onUserLogin(paramTbl)
	local loginInfo = paramTbl.loginInfo
	local body = {
		ts = math.ceil(skynet.time() / 1000),
		access_token = loginInfo.token,
		app_id = loginInfo.appid,
		cch_id = loginInfo.cchid,
		--sign_type = "md5",
		--nonce = nil,
		--sign = nil,
	}
	local dnsServer = dns.server()
	LOG._debug(dnsServer)
	local data = JSON4LUA.encode(body)
	local bgUrl = string.format("/gameSrv/rastarLogin?url=%s", url)
	local domain = DATA_COMMON.getLoginAddressBySrvGroup(GAME.SRV_GROUP_ID)
	local code, retData = http.post(domain, bgUrl, data)
	onRet(code, retData, paramTbl)
end

