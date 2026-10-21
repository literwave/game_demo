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

local function try_get_gate_info(server_id)
	local gate_list = SERVER_TBL[server_id]
	if not gate_list then
		return nil
	end
	return gate_list[math.random(1, #gate_list)]
end

local acc_type2_module = {
	[1] = Import("../logic/service/logind/module/login/pc.lua"),
	-- [2] = Import("../logic/module/login/wechat.lua")
}

function CMD.shutdown()
	skynet.exit()
end

local function decode_pack(msg)
	local _, pos = string.unpack(">I4", msg)
	local login_info = protobuf.decode("Login.c2s_user_login", msg:sub(pos))
	return login_info
end

local function encode_pack(msg)
	local pack_name = "Login.s2c_user_login"
	local pack_data = string.pack(">I2", PACK_NAME_TO_ID[pack_name]) .. protobuf.encode(pack_name, msg)
	pack_data = string.pack(">I2", #pack_data) .. pack_data
	return pack_data
end

local handle = {}

function handle.connect(id)
	skynet.error("logind ws connect from: " .. tostring(id))
end

function handle.handshake(id, header, url)
	local addr = websocket.addrinfo(id)
	skynet.error("logind ws handshake from: " .. tostring(id), "url", url, "addr:", addr)
end

function handle.message(id, msg)
	local login_info = decode_pack(msg)
	local login_module = acc_type2_module[login_info.accountType]
	if login_module then
		login_module.on_user_login(login_info)
	end
	local gate_info = try_get_gate_info(login_info.serverId)
	if not gate_info then
		skynet.error("auth error: ", login_info.serverId, login_info.userId)
	end
	local token = string.format("%s@%s:%s", crypt.base64encode(login_info.userId),
		crypt.base64encode(login_info.serverId),
		crypt.base64encode(login_info.passwd)
	)
	print("loginInfo: ", login_info.userId)
	local token_tbl = {
		userId = login_info.userId,
		passwd = login_info.passwd,
		serverId = login_info.serverId,
		account = login_info.account,
	}
	LREDIS.set_value_by_key(token, token_tbl, TOKEN_EXPIRED_TIME)
	local pack = {
		accountType = login_info.accountType,
		appId =  login_info.appId,
		cchid = login_info.cchid,
		account = login_info.account,
		passwd = login_info.passwd,
		gateAddr = gate_info.addr,
		token = token,
		userId = login_info.userId,
	}
	websocket.write(id, encode_pack(pack), "binary")
	skynet.error("login succ", login_info.userId, token)
	websocket.close(id)
end

function handle.close(id, code, reason)
	skynet.error("logind ws close from:", id, code, reason)
end

function handle.error(id)
	skynet.error("logind ws error from:", id,
		"handshake failed; connect with ws://host:33021 not raw TCP/HTTP")
end

function CMD.auth(fd, addr)
	skynet.error("login step 1-auth", fd, addr)
	skynet.fork(function()
		local ok, err = websocket.accept(fd, handle, PROTOCOL, addr)
		if not ok then
			skynet.error("login error", fd, addr, err)
		end
	end)
end

function CMD.create_user_ok(account, user_id)
	ACCOUNT.create_account(account, user_id)
end

function CMD.register_gate(server_id, gate_info)
	if not SERVER_TBL[server_id] then
		SERVER_TBL[server_id] = {}
	end
	table.insert(SERVER_TBL[server_id], gate_info)
end

