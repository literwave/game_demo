local skynet = require "skynet"
local queue = require "skynet.queue"
local protobuf = require "protobuf"

local CMD = {}

local userQueues = {
	-- [userId] = queue(),
}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.unpack
}

local function decodePack(packet)
	local id, pos = string.unpack(">I2", packet, 3)
	skynet.error(id, pos)
	local ptoName = ID_TO_PTONAME[id]
	local packName = ID_TO_PACK_NAME[id]
	return protobuf.decode(packName, packet:sub(pos)), ptoName
end

function CMD.login(gateSrv, fd, userId, addr, account, serverId, token)
	skynet.error("login step 3-agent", fd, userId, addr, account)
	local user = false
	local isFirstLogin = false
	if USER_MGR.isNewUser(userId) then
		user = USER_MGR.createNewUser(gateSrv, fd, userId, serverId)
		isFirstLogin = true
	else
		user = USER_MGR.tryInitUser(userId)
		USER_MGR.refLogin(userId, fd, user)
		user:setFd(fd)
		user:setGateSrv(gateSrv)
	end
	user:setAndSyncVerifyLogin(token)
	user:setAccount(account)
	user:setLoginAddr(addr)
	user:setAndSyncHeartBeatTime(TIME.osBJSec())
	CALL_OUT.callFre("USER_MGR", "detectUserHeartBeat", CONST.USER_HEART_BEAT_TIMEOUT, userId)
	USER_MGR.moduleOnUserLogin(user, isFirstLogin)
	skynet.send(".gameserver", "lua", "onUserLogin", userId, gateSrv)
end

function CMD.disconnect(fd, userId)
	userQueues[userId] = nil
	USER_MGR.disconnect(fd, userId)
end

local function errorHandler(err)
	skynet.error("agent error：", err)
	skynet.error("stack: ", debug.traceback())
	return err
end

skynet.start(function()
	dofile "../logic/service/agent/preload.lua"
	skynet.dispatch("lua", function(seesion, _ , command, ...)
		local f = CMD[command]
		if seesion ~= 0 then
			skynet.ret(skynet.pack(f(...)))
		else
			f(...)
		end
	end)

	skynet.dispatch("client", function(seesion, address, fd, packet, userId)
		if not userQueues[userId] then
			userQueues[userId] = queue()
		end
		local userQueue = userQueues[userId]
		local msg, ptoName = decodePack(packet)
		skynet.error("fd", fd, ptoName, userId)
		assert(fd)
		if not for_maker[ptoName] then
			LOG._debug("ptoName: %s not register", ptoName)
			return
		end
		skynet.error(table2str(msg))
		if not msg then
			return
		end
		-- 分发数据
		local ok, err = xpcall(userQueue, errorHandler, for_maker[ptoName], fd, msg)
		if not ok then
			LOG._error("userQueue error: %s", err)
		end
	end)
end)