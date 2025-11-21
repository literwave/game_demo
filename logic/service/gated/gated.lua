local skynet = require "skynet"
local socket = require "skynet.socket"

local CMD = {}

CONNECTION = {
	-- [vfd] = {

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

local function decodePack(fd)
	local sz = socket.read(fd, 2)
	sz = string.unpack(">I2", sz)
	local packMsg = socket.read(fd, sz)
	local _, pos = string.unpack(">I2", packMsg, 1)
	local payload_data = packMsg:sub(pos)
	local loginInfo = protobuf.decode("Login.c2splaylogin", payload_data)
	return loginInfo
end

local function doRequest(fd)
	socket.start(fd)
	while true do
		local sz = socket.read(fd, 2)
		sz = string.unpack(">I2", sz)
		local packMsg = socket.read(fd, sz)
		local agent = CONNECTION[fd].agent
		local userId = CONNECTION[fd].userId
		skynet.send(agent, "client", fd, packMsg, userId)
	end
end

local function getBalanceAgentInfo()
	for _, agentInfo in ipairs(AGENT_POOLS) do
		if agentInfo.userCnt < AGENT_MAX_USER_CNT then
			return agentInfo
		end
	end
end

function CMD.open(source, conf)
	for _ = 1, AGENT_INIT_CNT do
		local agent = {
			userCnt = 0,
			agent = skynet.newservice("agent")
		}
		table.insert(AGENT_POOLS, agent)
	end
	skynet.send(".logind", "lua", "registerGate", skynet.self(), conf.serverId)
end

function CMD.login(source, fd, account, userId, addr)
	assert(not CONNECTION[fd])
	local agentInfo = getBalanceAgentInfo()
	skynet.error("step3: gate login")
	if not agentInfo then
		skynet.error("get agent failed", account, userId)
		return
	end
	local agent = agentInfo.agent
	local agentUserId = skynet.call(agent, "lua", "login", fd, account, userId, addr)
	local c = {
		agent = agent,
		userId = userId,
		source = source,
		addr = addr,
		
	}
	CONNECTION[fd] = c
	if agentUserId ~= userId then
		skynet.send(source, "lua", "createUserOk", account, agentUserId)
	end
	doRequest(fd)
end

function CMD.kick(source, fd)

end

skynet.start(function()
	skynet.dispatch("lua", function (session, address, cmd, ...)
		local f = CMD[cmd]
		if f then
			if session ~= 0 then
				skynet.ret(skynet.pack(f(address, ...)))
			else
				f(address, ...)
			end
		end
	end)
end)