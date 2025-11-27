local skynet = require "skynet"

skynet.start(function()
	skynet.error("server start")
	skynet.newservice("gamelog") -- save file not save db
	skynet.newservice("logind") -- login service
	skynet.newservice("main_mongodb")
	skynet.call(".mongodb", "lua", "start")
	skynet.newservice("game_sid")
	skynet.newservice("load_xls")
	local gate = skynet.newservice("gated")
	skynet.call(gate, "lua", "open", {
		serverId = skynet.getenv("host_id")
	})
	-- -- control hot update or stop srv
	skynet.newservice("mcs") -- http服务
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