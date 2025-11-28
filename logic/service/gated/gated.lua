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

local function doRequest(fd)
	local conn = CONNECTION[fd]
	if not conn then
		return
	end
	
	local buffer = ""
	local function onMessage(data)
		if not data then
			if CONNECTION[fd] then
				CONNECTION[fd] = nil
			end
			return
		end
		buffer = buffer .. data
		while true do
			if #buffer < 2 then
				break
			end
			local sz = string.unpack(">I2", buffer:sub(1, 2))
			if #buffer < 2 + sz then
				break
			end
			local packMsg = buffer:sub(3, 2 + sz)
			buffer = buffer:sub(3 + sz)
			conn = CONNECTION[fd]
			if not conn then
				return
			end
			local agent = conn.agent
			local userId = conn.userId
			skynet.send(agent, "client", fd, packMsg, userId)
		end
	end
	socket.start(fd, onMessage)
end

local function getBalanceAgentInfo()
	table.sort(AGENT_POOLS, function(a, b)
		return a.userCnt < b.userCnt
	end)
	return AGENT_POOLS[1]
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
	skynet.error("login step 3-gate", account, userId)
	if not agentInfo then
		skynet.error("get agent failed", account, userId)
		return
	end
	local agent = agentInfo.agent
	local agentUserId = skynet.call(agent, "lua", "login", fd, account, userId, addr)
	agentInfo.userCnt = agentInfo.userCnt + 1
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

function CMD.shutdown()
	skynet.exit()
end

skynet.start(function()
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