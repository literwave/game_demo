local skynet = require "skynet"
local socket = require "skynet.socket"

local CMD = {}
local SOCKET = {}
local gate
local agent_pools = {}
local vfd_to_agent = {}
local STOP_SERVICE_LIST ={
	".watchdog",
	".agent",
	".load_xls",
	".mongodb",
}

local HTTP_AGENT_CNT = skynet.getenv("http_agent_cnt")
local http_agent_pools = {}

function SOCKET.open(fd, addr)
	LOG._debug("New client from : " .. addr)
	-- 随机分配一个agent池子
	local agent = agent_pools[1]
	vfd_to_agent[fd] = agent
	skynet.call(agent, "lua", "start", {gate = gate, client = fd, watchdog = skynet.self() })
end

local function send_vfd_agent_disconnect(fd)
	-- 这里采取不关闭服务的做法
	skynet.call(gate, "lua", "kick", fd)
	-- disconnect never return
	skynet.send(vfd_to_agent[fd], "lua", "disconnect", fd)
end

function SOCKET.close(fd)
	print("socket close",fd)
	send_vfd_agent_disconnect(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	send_vfd_agent_disconnect(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
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
	local fd = socket.listen("0.0.0.0", skynet.getenv("http_port"))
	socket.start(fd, function(fd, addr)
		local http_agent = http_agent_pools[balance]
		skynet.send(http_agent, "lua", fd)
		balance = balance + 1
		if balance > #http_agent_pools then
			balance = 1
		end
	end)
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)
end)
