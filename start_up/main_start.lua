local skynet = require "skynet"
local cluster = require "skynet.cluster"

skynet.start(function()
	skynet.error("server start")
	local nodename = (skynet.getenv("nodename") or "game") .. skynet.getenv("host_id")
	cluster.open(nodename)
	skynet.error("cluster open", nodename)

	skynet.newservice("debug_console", skynet.getenv("console_port") or 8000)
	skynet.newservice("gamelog") -- save file not save db
	skynet.newservice("load_xls") -- 配置进 sharedata，须先于业务服务
	skynet.newservice("logind") -- login service
	skynet.newservice("main_mongodb")
	skynet.call(".mongodb", "lua", "start")
	skynet.newservice("game_sid")
	local gate = skynet.newservice("gated")
	skynet.call(gate, "lua", "open", {
		serverId = skynet.getenv("host_id"),
		port = skynet.getenv("gate_port"),
	})
	-- -- control hot update or stop srv
	skynet.newservice("mcs") -- http服务
	skynet.newservice("gameserver") -- gameserver can get all userId
	skynet.newservice("mail")
	skynet.newservice("world")
	-- skynet.newservice("battleserver")
	-- 作为启动成功的logo
	skynet.error("***       *******   *******   *******   *******     ***     ***       ***     ***   ***    ********")
	skynet.error("***         ***       ***     ***       ***   **    ***     ***      *****    ***   ***    ***     ")
	skynet.error("***         ***       ***     *******   ***    **   ***     ***     *** ***   ***   ***    ******  ")
	skynet.error("***         ***       ***     ***       *******     ***  *  ***    *********  ***   ***    ***     ")
	skynet.error("***         ***       ***     ***       ***   **    *** *** ***   ***     ***  ***  ***    ***     ")
	skynet.error("*******   *******     ***     *******   ***    **    ***   ***   ****     ****   ***       ********")
	skynet.exit()
end)