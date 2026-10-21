local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.shutdown()
	skynet.exit()
end

function CMD.on_user_login(user_id, fd, gate_srv, is_first_login)
	skynet.error("activity login success", user_id, gate_srv, is_first_login)
	USER_MGR.ref_login(user_id, fd, gate_srv)
	ACT_MGR.on_user_login(user_id, is_first_login)
end

function CMD.on_user_logout(user_id, fd)
	skynet.error("activity logout success", user_id, fd)
	USER_MGR.disconnect(fd, user_id)
	ACT_MGR.on_user_logout(user_id)
end

skynet.start(function()
	skynet.error("boot activity success")
	dofile "../logic/service/activity/preload.lua"
	skynet.dispatch("lua", function(session, _, cmd, ...)
		local f = CMD[cmd]
		if not f then
			skynet.error("activity no callback", cmd)
			return
		end
		if session ~= 0 then
			skynet.ret(skynet.pack(f(...)))
		else
			f(...)
		end
	end)
	skynet.register(".activity")
end)
