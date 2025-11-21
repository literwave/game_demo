local skynet = require "skynet"
local socket = require "skynet.socket"
CMD = MASTER_HANDLE.CMD

SERVER_TBL = {
	-- [serverId] =
	-- {gate = *}
}

local function getServerInfo(serverId)
	return SERVER_TBL[serverId]
end

function CMD.registerGate(gate, serverId)
	assert(not SERVER_TBL[serverId])
	local serverInfo = {
		gate = gate
	}
	SERVER_TBL[serverId] = serverInfo
end

function createUserOk(slaveService, account, userId)
	skynet.call(slaveService, "lua", "createUserOk", account, userId)
end

function accept(slaveService, fd, addr)
	local account, userId, serverId = skynet.call(slaveService, "lua", "auth", fd, addr)
	if not account then
		return
	end
	local serverInfo = getServerInfo(serverId)
	if not serverInfo then
		skynet.error("serverInfo error", serverId)
	end
	skynet.error("login step 2", account)
	-- 然后网关服务玩家随机分配到agent，map[vfd] = {agent = agent, userId = userId, vfd = vfd}
	-- gate发送到agent，拿到userId, 去查数据库，然后new一个user对象
	skynet.send(serverInfo.gate, "lua", "login", fd, account, userId, addr)
end