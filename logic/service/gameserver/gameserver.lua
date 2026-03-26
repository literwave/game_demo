local skynet = require "skynet"
require "skynet.manager"

local CMD = {}
local RPC_CMD = {}

function CMD.shutdown()
	skynet.exit()
end

function CMD.onUserLogin(userId, fd, gateSrv, isFirstLogin)
	skynet.error("gameserver login success", userId, gateSrv, isFirstLogin)
	USER_MGR.refLogin(userId, fd, gateSrv)
end

function CMD.onUserLogout(userId, fd)
	skynet.error("gameserver logout success", userId, fd)
	USER_MGR.disconnect(userId, fd)
end

skynet.register_protocol {
	name = "rpc",
	id = skynet.PTYPE_RPC,
	unpack = skynet.unpack
}

function RPC_CMD.subItemList(id, ret, userId)
	return GLOBAL_FUNC.subItemList(id, ret, userId)
end

skynet.start(function()
	skynet.error("boot gameserver success")
	dofile "../logic/service/gameserver/preload.lua"
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
	skynet.dispatch("rpc", function (session, address, cmd, ...)
		local f = RPC_CMD[cmd]
		if f then
			if session ~= 0 then
				skynet.ret(f(address, ...))
			else
				f(address, ...)
			end
		end
	end)
	skynet.register(".gameserver")
end)
