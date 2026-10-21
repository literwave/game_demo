local skynet = require "skynet"
local socket = require "skynet.socket"
local websocket = require "http.websocket"
local protobuf = require "protobuf"
local crypt = require "client.crypt"
local PROTOCOL = skynet.getenv("protocol")

local CMD = {}

CONNECTION = {
	-- [fd] = {

	-- }
}

local AGENT_INIT_CNT = skynet.getenv("agent_init_cnt")
local AGENT_MAX_USER_CNT = tonumber(skynet.getenv("agent_max_user_cnt"))
local AGENT_POOLS = {
	-- {
	-- 	userCnt = *,
	-- 	agent = *,
	-- }
}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	pack = skynet.pack
}

local handle = {}

local function decode_pack(msg)
	local _, pos = string.unpack(">I4", msg)
	return protobuf.decode("Login.c2s_verify_login", msg:sub(pos))
end

local function encode_pack(msg)
	local pack_name = "Login.s2c_user_login_ok"
	local pack_data = string.pack(">I2", PACK_NAME_TO_ID[pack_name]) .. protobuf.encode(pack_name, msg)
	pack_data = string.pack(">I2", #pack_data) .. pack_data
	return pack_data
end

function handle.connect(id)
	print("gate ws connect from: " .. tostring(id))
end

function handle.handshake(id, header, url)
	local addr = websocket.addrinfo(id)
	print("gate ws handshake from: " .. tostring(id), "url", url, "addr:", addr)
end

local function get_balance_agent_info()
	table.sort(AGENT_POOLS, function(a, b)
		return a.user_cnt < b.user_cnt
	end)
	return AGENT_POOLS[1]
end

local function first_login(packet, fd)
	local token = packet.token
	local user_id = packet.userId
	local passwd = packet.passwd
	local user_info = LREDIS.get_value_by_key(token) or EMPTY_TABLE
	if user_id ~= user_info.userId or passwd ~= user_info.passwd then
		skynet.error("token error", token, user_id, passwd, user_info.userId, user_info.passwd)
		return
	end
	local agent_info = get_balance_agent_info()
	if not agent_info then
		skynet.error("get agent failed", user_id)
		return
	end
	local agent = agent_info.agent
	skynet.call(agent, "lua", "login", skynet.self(), fd, user_id, addr, user_info.account, user_info.serverId, token)
	print("userId: ", user_id)
	agent_info.user_cnt = agent_info.user_cnt + 1
	local c = {
		agent = agent,
		userId = user_id,
		addr = addr,
	}
	CONNECTION[fd] = c
	local pto_tbl = {
		userId = user_id,
		serverId = user_info.serverId,
	}
	local send_packet = encode_pack(pto_tbl)
	websocket.write(fd, send_packet, "binary")
	skynet.error("login ok")
end

function handle.message(fd, msg)
	local function error_handler(err)
		skynet.error("handle.message mistake", err)
		skynet.error("stack", debug.traceback())
		return err
	end
	local ok, ret = xpcall(function ()
		local conn = CONNECTION[fd]
		if not conn then
			local packet = decode_pack(msg)
			if not packet then
				return
			end
			first_login(packet, fd)
		else
			local agent = conn.agent
			local user_id = conn.userId
			skynet.send(agent, "client", fd, msg, user_id)
		end
	end, error_handler)
	if not ok then
		skynet.error("handle.message ", fd, "mistake：", ret)
	end
end

function handle.close(id, code, reason)
	local conn = CONNECTION[id]
	if conn then
		local agent = conn.agent
		for _, agent_info in pairs(AGENT_POOLS) do
			if agent_info.agent == agent then
				agent_info.user_cnt = agent_info.user_cnt - 1
			end
		end
		skynet.send(agent, "lua", "disconnect", id, conn.userId)
	end
	CONNECTION[id] = nil
	print("gate ws close from: " .. tostring(id), code, reason)
end

function handle.error(id)
	local conn = CONNECTION[id]
	if conn then
		local agent = conn.agent
		for _, agent_info in pairs(AGENT_POOLS) do
			if agent_info.agent == agent then
				agent_info.user_cnt = agent_info.user_cnt - 1
			end
		end
		skynet.send(agent, "lua", "disconnect", id, conn.userId)
	end
	CONNECTION[id] = nil
	print("gate ws error from: " .. tostring(id))
end

function CMD.open(conf)
	skynet.error(string.format("gate Listen on %s:%d", conf.address or "0.0.0.0", conf.port))
	local fd = socket.listen(conf.address or "0.0.0.0", conf.port)
	local addr = string.format("%s:%s", conf.address or "127.0.0.1", conf.port)
	socket.start(fd, function (fd, addr)
		websocket.accept(fd, handle, PROTOCOL, addr)
	end)
	for _ = 1, AGENT_INIT_CNT do
		local agent = {
			user_cnt = 0,
			agent = skynet.newservice("agent")
		}
		table.insert(AGENT_POOLS, agent)
	end
	skynet.send(".logind", "lua", "register_gate", skynet.self(), conf.serverId, addr)
end

function CMD.send_client_pack(fd, packet)
	websocket.write(fd, packet, "binary") 
end

function CMD.kick(fd)

end

function CMD.shutdown()
	skynet.exit()
end


skynet.start(function()
	dofile "../logic/service/gated/preload.lua"
	skynet.dispatch("lua", function (session, address, cmd, ...)
		local f = CMD[cmd]
		if f then
			if session ~= 0 then
				skynet.ret(f(...))
			else
				f(...)
			end
		end
	end)
end)