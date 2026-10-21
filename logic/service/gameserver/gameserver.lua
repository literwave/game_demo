local skynet = require "skynet"
require "skynet.manager"

local CMD = {}
local RPC_CMD = {}

function CMD.shutdown()
	skynet.exit()
end

function CMD.on_user_login(user_id, fd, gate_srv, is_first_login)
	skynet.error("gameserver login success", user_id, gate_srv, is_first_login)
	USER_MGR.ref_login(user_id, fd, gate_srv)
end

function CMD.on_user_logout(user_id, fd)
	skynet.error("gameserver logout success", user_id, fd)
	USER_MGR.disconnect(user_id, fd)
end

skynet.register_protocol {
	name = "rpc",
	id = skynet.PTYPE_RPC,
	unpack = skynet.unpack
}

function RPC_CMD.sub_item_list(id, ret, user_id)
	return GLOBAL_FUNC.sub_item_list(id, ret, user_id)
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
