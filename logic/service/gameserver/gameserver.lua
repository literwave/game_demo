local skynet = require "skynet"
require "skynet.manager"

local CMD = {}
local RPC_CMD = {}

function CMD.shutdown()
	skynet.exit()
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
	skynet.dispatch("lua", function (session, _, cmd, ...)
		local f = CMD[cmd]
		if f then
			if session ~= 0 then
				skynet.ret(skynet.pack(f(...)))
			else
				f(...)
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
