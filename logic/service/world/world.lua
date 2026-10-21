local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.shutdown()
	skynet.exit()
end

function CMD.sync_to_map(oci)
	ENTITY_MGR.sync_to_map(oci)
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
