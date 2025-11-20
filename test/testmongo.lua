local skynet = require "skynet"

skynet.call(mongo, "lua", "insert",{
	database = "testdb",
	collection = "role",
	doc = {test = "haha", num = 100}
})