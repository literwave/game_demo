local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.shutdown()
	skynet.fork(skynet.exit)
end

function CMD.hot_update(_, path_list)
	return hot_update(path_list)
end

function CMD.sync_to_map(oci)
	ENTITY_MGR.sync_to_map(oci)
end

function CMD.alloc_birth_pos()
	return MAP_MGR.alloc_birth_pos()
end

skynet.start(function()
	skynet.error("boot world success")
	dofile "../logic/service/world/preload.lua"
	skynet.dispatch("lua", function (session, address, cmd, ...)
		local f = CMD[cmd]
		if f then
			if session ~= 0 then
				skynet.ret(skynet.pack(f(address, ...)))
			else
				f(address, ...)
			end
		end
	end)
	skynet.register(".world")
end)
