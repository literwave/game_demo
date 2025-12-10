local skynet = require "skynet"
local protobuf = require "protobuf"
local websocket = require "http.websocket"
local crypt = require "client.crypt"
local PROTOCOL = skynet.getenv("protocol")

local TOKEN_EXPIRED_TIME = 300
CMD = {}

SERVER_TBL = {
	-- [serverId] =
	-- 	{gateInfo, gateInfo}
}

local function tryGetGateInfo(serverId)
	local gateList = SERVER_TBL[serverId]
	if not gateList then
		return nil
	end
	return gateList[math.random(1, #gateList)]
end

local accType2Module = {
	[1] = Import("../logic/service/logind/module/login/pc.lua"),
	-- [2] = Import("../logic/module/login/wechat.lua")
}

function CMD.shutdown()
	skynet.exit()
end

local function decodePack(msg)
	local _, pos = string.unpack(">I4", msg)
	local loginInfo = protobuf.decode("Login.c2s_user_login", msg:sub(pos))
	return loginInfo
end

local function encodePack(msg)
	local packData = string.pack(">I2", 258) .. protobuf.encode("Login.s2c_user_login", msg)
	packData = string.pack(">I2", #packData) .. packData
	return packData
end

local handle = {}

function handle.connect(id)
	print("logind ws connect from: " .. tostring(id))
end

function handle.handshake(id, header, url)
	local addr = websocket.addrinfo(id)
	print("logind ws handshake from: " .. tostring(id), "url", url, "addr:", addr)
end

function handle.message(id, msg)
	local loginInfo = decodePack(msg)
	local loginModule = accType2Module[loginInfo.accountType]
	if loginModule then
		loginModule.onUserLogin(loginInfo)
	end
	local gateInfo = tryGetGateInfo(loginInfo.serverId)
	if not gateInfo then
		skynet.error("auth error: ", loginInfo.serverId, loginInfo.userId)
	end
	local token = string.format("%s@%s:%s", crypt.base64encode(loginInfo.userId),
		crypt.base64encode(loginInfo.serverId),
		crypt.base64encode(loginInfo.passwd)
	)
	local tokenTbl = {
		userId = loginInfo.userId,
		passwd = loginInfo.passwd,
		serverId = loginInfo.serverId,
		account = loginInfo.account,
	}
	LREDIS.setValueByKey(token, tokenTbl, TOKEN_EXPIRED_TIME)
	local pack = {
		accountType = loginInfo.accountType,
		appId =  loginInfo.appId,
		cchid = loginInfo.cchid,
		account = loginInfo.account,
		passwd = loginInfo.passwd,
		gateAddr = gateInfo.addr,
		token = token,
		userId = loginInfo.userId,
	}
	websocket.write(id, encodePack(pack))
	websocket.close(id)
end

function handle.close(id, code, reason)
	print("logind ws close from: " .. tostring(id), code, reason)
end

function handle.error(id)
	print("logind ws error from: " .. tostring(id))
end

function CMD.auth(fd, addr)
	skynet.error("login step 1-auth", fd, addr, fd)
	websocket.accept(fd, handle, PROTOCOL, addr)
end

function CMD.createUserOk(account, userId)
	ACCOUNT.createAccount(account, userId)
end

function CMD.registerGate(serverId, gateInfo)
	if not SERVER_TBL[serverId] then
		SERVER_TBL[serverId] = {}
	end
	table.insert(SERVER_TBL[serverId], gateInfo)
end

