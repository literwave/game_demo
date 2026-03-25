local skynet = require "skynet"
local queue = require "skynet.queue"
local protobuf = require "protobuf"

local CMD = {}
local RPC_CMD = {}

local userQueues = {
	-- [userId] = queue(),
}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.unpack
}

skynet.register_protocol {
	name = "rpc",
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
	local lastLoginTime = TIME.osBJSec()
	if USER_MGR.isNewUser(userId) then
		user = USER_MGR.createNewUser(gateSrv, fd, userId, serverId)
		isFirstLogin = true
	else
		user = USER_MGR.tryInitUser(userId)
		USER_MGR.refLogin(userId, fd, user)
		user:setFd(fd)
		user:setGateSrv(gateSrv)
		lastLoginTime = user:getLoginTime()
	end
	user:setAndSyncVerifyLogin(token)
	user:setAccount(account)
	user:setLoginAddr(addr)
	user:setAndSyncHeartBeatTime(TIME.osBJSec())
	CALL_OUT.callFre("USER_MGR", "detectUserHeartBeat", CONST.USER_HEART_BEAT_TIMEOUT, userId)
	USER_MGR.moduleOnUserLogin(user, isFirstLogin)
	local times = TIME.getDiffDay(TIME.osBJSec(), lastLoginTime)
	if times > 1 then
		USER_MGR.moduleOnUserNextDay(user, times)
	end
	CALL_OUT.callOnce("USER_MGR", "moduleOnUserNextDay", 24, userId)
	skynet.send(".gameserver", "lua", "onUserLogin", userId, fd, gateSrv, isFirstLogin)
	skynet.send(".mail", "lua", "onUserLogin", userId, fd, gateSrv, isFirstLogin)
end

function CMD.disconnect(fd, userId)
	userQueues[userId] = nil
	USER_MGR.disconnect(fd, userId)
	skynet.send(".gameserver", "lua", "onUserLogout", userId, fd)
end

local function subItemListRecv(id, taddr, userId, itemList, reasonList)
	if not ITEM_MGR.checkCostEnough(userId, itemList) then
		skynet.send(taddr, "rpc", id, false)
		return
	end
	local ok = skynet.call(taddr, "rpc", id, true)
	if not ok then
		return
	end
	assert(ITEM_MGR.delCostList(userId, itemList))
end

function RPC_CMD.subItemList(id, userId, taddr, itemList, reasonList)
	if not ITEM_MGR.checkCostEnough(userId, itemList) then
		skynet.send(taddr, "rpc", id, false)
	end
	local q = queue()
	local ok = q(subItemListRecv, id, taddr, userId, itemList, reasonList)
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
			skynet.error("ptoName not registerptoName", ptoName)
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

		skynet.dispatch("rpc", function(seesion, address)
		RPC_CMD.subItemList
	end)
end)