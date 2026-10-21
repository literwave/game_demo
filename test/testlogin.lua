local skynet = require "skynet"
local socket = require "skynet.socket"
local protobuf = require"protobuf"
local netpack = require "skynet.netpack"
local websocket = require "http.websocket"

local function decode_pack(msg, name)
	local _, pos = string.unpack(">I4", msg)
	local login_info = protobuf.decode(name, msg:sub(pos))
	return login_info
end

local function encode_pack(msg, id, name)
	local pack_data = string.pack(">I2", id) .. protobuf.encode(name, msg)
	pack_data = string.pack(">I2", #pack_data) .. pack_data
	return pack_data
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
	local pack_data = encode_pack(data, 258, "Login.c2s_user_login")
	print("size1", #pack_data)
	-- packData = string.pack(">H", #packData)..packData
	-- print(packData)
	-- packData = string.pack(">Hc13", 13, "login,101,134")
	websocket.write(fd, pack_data)
	local res = websocket.read(fd)
	print("size2", #res)
	local packet = decode_pack(res, "Login.s2c_user_login")
	-- websocket.close(fd)
	print(table2str(packet))
	local login_url = string.format("%s://%s", "ws", packet.gateAddr)
	-- local loginUrl = string.format("%s://127.0.0.1:33022", "ws")
	data = {
		token = packet.token,
		userId = packet.userId,
		passwd = packet.passwd,
	}
	print(login_url)
	-- xpcall(websocket.connect, debug.traceback, loginUrl)
	local new_fd = websocket.connect(login_url)
	pack_data = encode_pack(data, 258, "Login.c2s_verify_login")
	print(table2str(pack_data))
	print("size3", #pack_data)
	websocket.write(new_fd, pack_data)
	res = websocket.read(new_fd)
	print("size4", #res)
	packet = decode_pack(res, "Login.s2c_user_login_ok")
	print(table2str(packet))
	-- skynet.newservice("debug_console",8000)
	-- skynet.sleep(300)
end)
