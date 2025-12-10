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

function CMD.login(gateSrv, fd, userId, addr, account, serverId)
	skynet.error("login step 3-agent", fd, userId, addr, account)
	local user = false
	if USER_MGR.isNewUser(userId) then
		user = USER_MGR.createNewUser(gateSrv, fd, userId, serverId)
	else
		user = USER_MGR.tryInitUser(userId)
		USER_MGR.refLogin(userId, fd, user)
		user:setFd(fd)
		user:setGateSrv(gateSrv)
	end
	user:setAccount(account)
	user:setLoginAddr(addr)
	user:setAndSyncHeartBeatTime(TIME.osBJSec())
	CALL_OUT.callFre("USER_MGR", "detectUserHeartBeat", CONST.USER_HEART_BEAT_TIMEOUT, userId)
	USER_MGR.moduleOnUserLogin(user)
	return user:getUserId()
end

function CMD.disconnect(fd, userId)
	userQueues[userId] = nil
	USER_MGR.disconnect(fd, userId)
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

	skynet.dispatch("client", function(fd, addr, packet, userId)
		if not userQueues[userId] then
			userQueues[userId] = queue()
		end
		local userQueue = userQueues[userId]
		local id = string.unpack(">I2", packet, 1)
		assert(fd)
		local decodeMsg = string.sub(packet, 3)
		local ptoName = ID_TO_PTONAME[id]
		if not for_maker[ptoName] then
			LOG._debug("ptoName: %s not register", ptoName)
			return
		end
		local packName = ID_TO_PACK_NAME[id]
		local msg = protobuf.decode(packName, decodeMsg)
		if not msg then
			if not msg then
				LOG._debug("packName: %s not exist", packName)
			end
			return
		end
		-- 分发数据
		local ok, err = xpcall(userQueue, for_maker[ptoName], userId, msg)
		if not ok then
			LOG._error("userQueue error: %s", err)
		end
	end)
end)