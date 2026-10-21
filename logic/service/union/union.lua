local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.shutdown()
	skynet.exit()
end

function CMD.on_user_login(user_id, fd, gate_srv, is_first_login)
	skynet.error("union login success", user_id, gate_srv, is_first_login)
	USER_MGR.ref_login(user_id, fd, gate_srv)
	UNION_MGR.on_user_login(user_id, is_first_login)
end

function CMD.on_user_logout(user_id, fd)
	skynet.error("union logout success", user_id, fd)
	USER_MGR.disconnect(fd, user_id)
	UNION_MGR.on_user_logout(user_id)
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
