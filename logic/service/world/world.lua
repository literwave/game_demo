local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.shutdown()
	skynet.exit()
end

function CMD.onUserLogin(userId, fd, gateSrv, isFirstLogin)
	skynet.error("world login success", userId, gateSrv, isFirstLogin)
	USER_MGR.refLogin(userId, fd, gateSrv)
end

function CMD.onUserLogout(userId, fd)
	skynet.error("world logout success", userId, fd)
	USER_MGR.disconnect(userId, fd)
end

function CMD.syncToMap(oci)
	ENTITY_MGR.syncToMap(oci)
end

skynet.start(function()
	skynet.error("boot world success")
	dofile "../logic/service/world/preload.lua"
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
	skynet.register(".world")
end)
