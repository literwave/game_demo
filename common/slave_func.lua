local skynet = require "skynet"
local socket = require "skynet.socket"
local protobuf = require "protobuf"
CMD = {}

local accType2Module = {
	[1] = Import("../logic/service/logind/module/login/pc.lua"),
	-- [2] = Import("../logic/module/login/wechat.lua")
}

function CMD.shutdown()
	skynet.exit()
end

local function decodePack(fd)
	socket.start(fd)
	socket.limit(fd, 8192)
	local sz = socket.read(fd, 2)
	sz = string.unpack(">I2", sz)
	local packMsg = socket.read(fd, sz)
	local _, pos = string.unpack(">I2", packMsg)
	local payload_data = packMsg:sub(pos)
	local loginInfo = protobuf.decode("Login.c2s_user_login", payload_data)
	return loginInfo
end

function CMD.auth(fd, addr)
	skynet.error("login step 1-auth", fd, addr, fd)
	local loginInfo = decodePack(fd)
	local loginModule = accType2Module[loginInfo.accountType]
	if loginModule then
		loginModule.onUserLogin(loginInfo)
	end
	socket.abandon(fd)
	return loginInfo.account, loginInfo.userId, loginInfo.serverId
end

function CMD.createUserOk(account, userId)
	ACCOUNT.createAccount(account, userId)
end

