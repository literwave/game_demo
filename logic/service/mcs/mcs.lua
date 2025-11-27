local skynet = require "skynet"
local socket = require "skynet.socket"

local CMD = {}
local SOCKET = {}
local gate
local agent_pools = {}
local vfd_to_agent = {}
local STOP_SERVICE_TBL ={
	-- [SERVER_NAME] = sortId
}

local HTTP_AGENT_CNT = skynet.getenv("http_agent_cnt")
local http_agent_pools = {}

local LISTEN_FD = nil

local CAN_OP_ADDR_TBL = {
	["172.21.192.1"] = true
}

function CMD.shutdown()
	socket.close(LISTEN_FD)
	skynet.exit()
end

function CMD.start(conf)
	-- skynet.call(gate, "lua", "open" , conf)
end

function CMD.stop()
	for _, service_name in ipairs(STOP_SERVICE_LIST) do
		skynet.call(service_name, "lua", "close")
	end
	skynet.exit()
end

function CMD.hotUpdate()
	-- 先更新配置，不然逻辑服更新取新配置会报错
	skynet.call(".load_xls", "lua", "hotUpdate")
	-- todo agent热更
	skynet.call(".agent", "lua", "hotUpdate")
end

skynet.start(function()
	for _ = 1, HTTP_AGENT_CNT do
		table.insert(http_agent_pools, skynet.newservice("http_agent"))
	end
	local balance = 1
	LISTEN_FD = socket.listen("0.0.0.0", skynet.getenv("http_port"))
	socket.start(LISTEN_FD, function(fd, addr)
		addr = string.split(addr, ":")[1]
		skynet.error("mcs op addr", addr)
		if not CAN_OP_ADDR_TBL[addr] then
			return
		end
		local http_agent = http_agent_pools[balance]
		skynet.send(http_agent, "lua", fd)
		balance = balance + 1
		if balance > #http_agent_pools then
			balance = 1
		end
	end)
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
end)
