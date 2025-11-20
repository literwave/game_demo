---        filename main_start
-------    @author  xiaobo
---        date 2022/03/30/22/17/11


local skynet = require "skynet"

skynet.start(function()
	skynet.error("Server start")
	skynet.newservice("gamelog") -- save file not save db
	skynet.newservice("logind") -- login service
	skynet.newservice("main_mongodb")
	skynet.call(".mongodb", "lua", "start")
	skynet.newservice("game_sid")
	-- skynet.newservice("load_xls")
	local gate = skynet.newservice("gated")
	skynet.call(gate, "lua", "open", {
		port = skynet.getenv("gate_port") or 8888,
		maxclient = tonumber(skynet.getenv("maxonline") or 2000),
		nodelay = true,
		serverId = skynet.getenv("host_id")
	})
	-- -- control hot update or stop srv
	local mcs = skynet.newservice("mcs") -- http服务
	skynet.call(mcs, "lua", "start", {
		port = skynet.getenv("http_port"),
		nodelay = true,
		protocol = "http",
	})
	skynet.newservice("gameserver") -- game server can get all userId
	-- 作为启动成功的logo
	skynet.error("***       *******   *******   *******   ***********   ***     ***       ***     ***   ***    ********")
	skynet.error("***         ***       ***     ***           ***       ***     ***      *****    ***   ***    ***     ")
	skynet.error("***         ***       ***     *******       ***       ***     ***     *** ***   ***   ***    ******  ")
	skynet.error("***         ***       ***     ***           ***       ***  *  ***    *********  ***   ***    ***     ")
	skynet.error("***         ***       ***     ***           ***       *** *** ***   ***     ***  ***  ***    ***     ")
	skynet.error("*******   *******     ***     *******       ***        ***   ***   ****     ****   ***       ********")
	skynet.exit()
end)