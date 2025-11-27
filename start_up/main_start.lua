local skynet = require "skynet"

skynet.start(function()
	skynet.error("server start")
	skynet.newservice("gamelog") -- save file not save db
	skynet.newservice("logind") -- login service
	skynet.newservice("main_mongodb")
	skynet.call(".mongodb", "lua", "start")
	skynet.newservice("game_sid")
	skynet.newservice("load_xls")
	for _ = 1, tonumber(skynet.getenv("gate_cnt")) do
		local gate = skynet.newservice("gated")
		skynet.call(gate, "lua", "open", {
			serverId = skynet.getenv("host_id")
		})
	end
	-- -- control hot update or stop srv
	local mcs = skynet.newservice("mcs") -- http服务
	skynet.call(mcs, "lua", "open", {
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