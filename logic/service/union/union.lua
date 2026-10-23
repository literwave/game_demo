local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.shutdown()
	skynet.fork(skynet.exit)
end

function CMD.hot_update(path_list)
	return hot_update(path_list)
end

skynet.start(function()
	skynet.error("boot union success")
	dofile "../logic/service/union/preload.lua"
	skynet.dispatch("lua", function(session, _, cmd, ...)
		local f = CMD[cmd]
		if not f then
			skynet.error("union no callback", cmd)
			return
		end
		if session ~= 0 then
			skynet.ret(skynet.pack(f(...)))
		else
			f(...)
		end
	end)
	skynet.register(".union")
end)
