local skynet = require "skynet"
local socket = require "skynet.socket"
local protobuf = require"protobuf"
local netpack = require "skynet.netpack"

local function pack_package(...)
	local message = skynet.packstring(...)
	local size = #message
	assert(size <= 255 , "too long")
	return string.char(size) .. message
end

skynet.start(function()
	protobuf.register_file("../proto/pb/login.pb")
	local data = {
	    accountType = "1",
	    appId = "2",
	    cchid = "1",
	    account = "123",
	    passwd = "456",
	    serverId = "120"
	}
	local fd = assert(socket.open("127.0.0.1", 33021))
	local packData = string.pack(">I2", 258) .. protobuf.encode("Login.c2s_user_login",data)
	print("size", #packData)
	-- packData = string.pack(">H", #packData)..packData
	-- print(packData)
	-- packData = string.pack(">Hc13", 13, "login,101,134")
	print(fd)
	socket.write(fd, netpack.pack(packData))
	-- skynet.newservice("debug_console",8000)
	-- skynet.sleep(300)
end)
