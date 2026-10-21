local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.shutdown()
	skynet.exit()
end

function CMD.on_user_login(user_id, fd, gate_srv, is_first_login)
	skynet.error("world login success", user_id, gate_srv, is_first_login)
	USER_MGR.ref_login(user_id, fd, gate_srv)
end

function CMD.on_user_logout(user_id, fd)
	skynet.error("world logout success", user_id, fd)
	USER_MGR.disconnect(user_id, fd)
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
