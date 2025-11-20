---        filename master_handle
-------    @author  xiaobo
---        date 2022/08/27/13/51/11

local skynet = require "skynet"
CMD = {}
SOCKET = {}
skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		-- 第一种消息预留，暂且不管
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)


