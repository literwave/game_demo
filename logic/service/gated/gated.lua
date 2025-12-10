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

local handle = {}

local function decodePack(msg)
	local _, pos = string.unpack(">I4", msg)
	return protobuf.decode("Login.c2s_verify_login", msg:sub(pos))
end

local function encodePack(msg)
	local packData = string.pack(">I2", 258) .. protobuf.encode("Login.s2c_user_login_ok", msg)
	packData = string.pack(">I2", #packData) .. packData
	return packData
end

function handle.connect(id)
	print("gate ws connect from: " .. tostring(id))
end

function handle.handshake(id, header, url)
	local addr = websocket.addrinfo(id)
	print("gate ws handshake from: " .. tostring(id), "url", url, "addr:", addr)
end

local function getBalanceAgentInfo()
	table.sort(AGENT_POOLS, function(a, b)
		return a.userCnt < b.userCnt
	end)
	return AGENT_POOLS[1]
end

local function firstLogin(packet, fd)
	local token = packet.token
	local userId = packet.userId
	local passwd = packet.passwd
	local userInfo = LREDIS.getValueByKey(token)
	if userId ~= userInfo.userId or passwd ~= userInfo.passwd then
		skynet.error("token error", token, userId, passwd, userInfo.userId, userInfo.passwd)
		return
	end
	local agentInfo = getBalanceAgentInfo()
	if not agentInfo then
		skynet.error("get agent failed", userId)
		return
	end
	local agent = agentInfo.agent
	skynet.send(agent, "lua", "login", skynet.self(), fd, userId, addr, userInfo.account, userInfo.serverId)
	agentInfo.userCnt = agentInfo.userCnt + 1
	local c = {
		agent = agent,
		userId = userId,
		addr = addr,
	}
	CONNECTION[fd] = c
	local ptoTbl = {
		userId = userId,
		serverId = userInfo.serverId,
	}
	websocket.write(fd, encodePack(ptoTbl))
end

function handle.message(fd, msg)
	local conn = CONNECTION[fd]
	if not conn then
		local packet = decodePack(msg)
		if not packet then
			return
		end
		firstLogin(packet, fd)
		
	else
		local agent = conn.agent
		local userId = conn.userId
		skynet.send(agent, "client", fd, msg, userId)
	end
end

function handle.close(id, code, reason)
	local conn = CONNECTION[id]
	if conn then
		local agent = conn.agent
		for _, agentInfo in pairs(AGENT_POOLS) do
			if agentInfo.agent == agent then
				agentInfo.userCnt = agentInfo.userCnt - 1
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
		for _, agentInfo in pairs(AGENT_POOLS) do
			if agentInfo.agent == agent then
				agentInfo.userCnt = agentInfo.userCnt - 1
			end
		end
		skynet.send(agent, "lua", "disconnect", id, conn.userId)
	end
	CONNECTION[id] = nil
	print("gate ws error from: " .. tostring(id))
end

function CMD.open(source, conf)
	skynet.error(string.format("gate Listen on %s:%d", conf.address or "0.0.0.0", conf.port))
	local fd = socket.listen(conf.address or "0.0.0.0", conf.port)
	local addr = string.format("%s:%s", conf.address or "127.0.0.1", conf.port)
	socket.start(fd, function (fd, addr)
		websocket.accept(fd, handle, PROTOCOL, addr)
	end)
	for _ = 1, AGENT_INIT_CNT do
		local agent = {
			userCnt = 0,
			agent = skynet.newservice("agent")
		}
		table.insert(AGENT_POOLS, agent)
	end
	skynet.send(".logind", "lua", "registerGate", skynet.self(), conf.serverId, addr)
end

function CMD.login(source, token, loginInfo, addr)
	skynet.error("login step 2-gate", token)
	assert(not TKOEN_TBL[token])
	TKOEN_TBL[token] = {
		userId = loginInfo.userId,
		serverId = loginInfo.serverId,
		account = loginInfo.account,
	}
end

function CMD.sendClientPack(source, fd, packet)
	websocket.write(fd, packet)
end

function CMD.kick(source, fd)

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
				skynet.ret(f(address, ...))
			else
				f(address, ...)
			end
		end
	end)
end)