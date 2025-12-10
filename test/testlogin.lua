local skynet = require "skynet"
local socket = require "skynet.socket"
local protobuf = require"protobuf"
local netpack = require "skynet.netpack"
local websocket = require "http.websocket"

local function decodePack(msg, name)
	local _, pos = string.unpack(">I4", msg)
	local loginInfo = protobuf.decode(name, msg:sub(pos))
	return loginInfo
end

local function encodePack(msg, id, name)
	local packData = string.pack(">I2", id) .. protobuf.encode(name, msg)
	packData = string.pack(">I2", #packData) .. packData
	return packData
end

local function table2str(obj, indent)
	indent = indent or 0 
	local str = ""
	local indent_str = string.rep("\t", indent) 
	if type(obj) ~= "table" then
		return tostring(obj)
	end
	str = str .. "{\n"
	for k, v in pairs(obj) do
		str = str .. indent_str .. "\t[" .. tostring(k) .. "] = "
		if type(v) == "table" then
			str = str .. table2str(v, indent + 1) .. ",\n"
		else
			str = str .. tostring(v) .. ",\n"
		end
	end
	str = str .. indent_str .. "}"
	
	return str
end

local url = string.format("%s://127.0.0.1:33021", "ws")

skynet.start(function()
	local fd = websocket.connect(url)
	protobuf.register_file("../proto/pb/login.pb")
	local data = {
	    accountType = "1",
	    appId = "2",
	    cchid = "1",
	    account = "123",
	    passwd = "456",
	    serverId = "120",
	    userId = ""
	}
	local packData = encodePack(data, 258, "Login.c2s_user_login")
	print("size1", #packData)
	-- packData = string.pack(">H", #packData)..packData
	-- print(packData)
	-- packData = string.pack(">Hc13", 13, "login,101,134")
	websocket.write(fd, packData)
	local res = websocket.read(fd)
	print("size2", #res)
	local packet = decodePack(res, "Login.s2c_user_login")
	-- websocket.close(fd)
	print(table2str(packet))
	local loginUrl = string.format("%s://%s", "ws", packet.gateAddr)
	-- local loginUrl = string.format("%s://127.0.0.1:33022", "ws")
	data = {
		token = packet.token,
		userId = packet.userId,
		passwd = packet.passwd,
	}
	print(loginUrl)
	-- xpcall(websocket.connect, debug.traceback, loginUrl)
	local newFd = websocket.connect(loginUrl)
	packData = encodePack(data, 258, "Login.c2s_verify_login")
	print(table2str(packData))
	print("size3", #packData)
	websocket.write(newFd, packData)
	res = websocket.read(newFd)
	print("size4", #res)
	packet = decodePack(res, "Login.s2c_user_login_ok")
	print(table2str(packet))
	-- skynet.newservice("debug_console",8000)
	-- skynet.sleep(300)
end)
