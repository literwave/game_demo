local skynet = require "skynet"
local socket = require "skynet.socket"
CMD = MASTER_HANDLE.CMD

SERVER_TBL = {
	-- [serverId] =
	-- 	{gate, ...}
}

local function tryGetGate(serverId)
	local gateList = SERVER_TBL[serverId]
	if not gateList then
		return nil
	end
	return gateList[math.random(1, #gateList)]
end

function CMD.registerGate(gate, serverId)
	if not SERVER_TBL[serverId] then
		SERVER_TBL[serverId] = {}
	end
	table.insert(SERVER_TBL[serverId], gate)
end

function createUserOk(slaveService, account, userId)
	skynet.call(slaveService, "lua", "createUserOk", account, userId)
end

function accept(slaveService, fd, addr)
	local account, userId, serverId = skynet.call(slaveService, "lua", "auth", fd, addr)
	if not account then
		return
	end
	local gate = tryGetGate(serverId)
	if not gate then
		skynet.error("serverInfo error", serverId)
	end
	skynet.error("login step 2-accept", account)
	-- 然后网关服务玩家随机分配到agent，map[vfd] = {agent = agent, userId = userId, vfd = vfd}
	-- gate发送到agent，拿到userId, 去查数据库，然后new一个user对象
	skynet.send(gate, "lua", "login", fd, account, userId, addr)
end