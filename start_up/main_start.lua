---        filename main_start
-------    @author  xiaobo
---        date 2022/03/30/22/17/11


local skynet = require "skynet"

local function startUpNameSrv()
	for _, service_name in ipairs(START_NAME_SVER) do
		skynet.newservice(service_name)
	end
	
end

skynet.start(function()
	skynet.error("Server start")

	-- 
	-- if not skynet.getenv "daemon" then
	-- 	local console = skynet.newservice("console")
	-- end
	dofile "../common/namesrv.lua"
	startUpNameSrv()
	-- skynet.newservice("debug_console",8000)
	-- local watchdog = skynet.newservice("watchdog")
	-- skynet.error(watchdog)
	-- skynet.call(watchdog, "lua", "start", {
	-- 	port = 8888,
	-- 	maxclient = max_client,
	-- 	nodelay = true,
	-- })

	-- 启动网关服务
	local gate = skynet.newservice("gate")
	skynet.call(gate, "lua", "open" , {
			port = skynet.getenv("gate_port") or 8888,
			maxclient = skynet.getenv("maxonline") or 2000,
			nodelay = true,
		})
	skynet.error("gate_port start: ", skynet.getenv("gate_port"))
	skynet.exit()
end)
