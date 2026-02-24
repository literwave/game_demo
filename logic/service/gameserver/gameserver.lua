local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.shutdown()
	skynet.exit()
end

function CMD.onUserLogin(userId, fd, gateSrv)
	skynet.error("sync gameserver success", userId, gateSrv)
	USER_MGR.refLogin(userId, fd, gateSrv)
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
	skynet.register(".gameserver")
end)
