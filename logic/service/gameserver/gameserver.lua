local skynet = require "skynet"

local CMD = {}

function CMD.shutdown()
	skynet.exit()
end

skynet.start(function()
	skynet.error("boot gameserver success")
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
