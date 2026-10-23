-- 机器人和服务端之间的收发：包格式 len(2) + id(2) + protobuf
local websocket = require "http.websocket"
local socketdriver = require "skynet.socketdriver"
local protobuf = require "protobuf"

local M = {}

local ID = {}
local loaded = false

function M.init()
	if loaded then
		return
	end
	loaded = true
	dofile("../game_common/server/net_pb.lua")
	for name, id in pairs(PTONAME_TO_ID) do
		ID[name] = id
	end
	protobuf.register_file("../game_common/pb/login.pb")
end

function M.id(name)
	return assert(ID[name], name)
end

function M.send(ws, name, msg)
	local id = M.id(name)
	local body = ""
	if msg then
		body = protobuf.encode(ID_TO_PACK_NAME[id], msg)
	end
	local pack = string.pack(">I2", id) .. body
	websocket.write(ws, string.pack(">I2", #pack) .. pack, "binary")
end

-- 返回 id, body；连接关闭返回 nil, 原因
function M.recv(ws)
	local ok, data, reason = pcall(websocket.read, ws)
	if not ok then
		return nil, tostring(data)
	end
	if not data then
		return nil, reason or "closed"
	end
	if #data < 4 then
		return nil, "short pack"
	end
	return string.unpack(">I2", data, 3), data:sub(5)
end

-- 一直读到期望的协议号，中间的推送包跳过。只有登录相关的协议注册了 pb，其余只认协议号不解包
function M.recv_until(ws, name, is_decode)
	local want = M.id(name)
	while true do
		local id, body = M.recv(ws)
		if not id then
			return nil, body
		end
		if id == want then
			if is_decode then
				return protobuf.decode(ID_TO_PACK_NAME[id], body) or {}
			end
			return true
		end
	end
end

function M.connect(addr, timeout)
	local ok, ws = pcall(websocket.connect, "ws://" .. addr, nil, timeout)
	if not ok then
		return nil, tostring(ws)
	end
	socketdriver.nodelay(ws)
	return ws
end

function M.close(ws)
	pcall(websocket.close, ws)
end

-- 完整登录：登录服拿 token 和网关地址，再到网关验证。返回网关连接和 userId
-- on_conn(ws) 在每条连接建好时调用，调用方用它做超时看护
function M.login(login_addr, server_id, account, timeout, on_conn)
	on_conn = on_conn or function() end
	local ws, err = M.connect(login_addr, timeout)
	if not ws then
		return nil, "connect login: " .. err
	end
	on_conn(ws)
	M.send(ws, "c2s_user_login", {
		accountType = 1,
		appId = "bench",
		cchid = "bench",
		account = account,
		passwd = "bench",
		serverId = server_id,
	})
	local ret
	ret, err = M.recv_until(ws, "s2c_user_login", true)
	M.close(ws)
	if not ret then
		return nil, "login: " .. err
	end
	local gws
	gws, err = M.connect(ret.gateAddr, timeout)
	if not gws then
		return nil, "connect gate " .. tostring(ret.gateAddr) .. ": " .. err
	end
	on_conn(gws)
	M.send(gws, "c2s_verify_login", {
		userId = ret.userId,
		passwd = ret.passwd,
		token = ret.token,
	})
	local ok_msg
	ok_msg, err = M.recv_until(gws, "s2c_user_login_ok", true)
	if not ok_msg then
		M.close(gws)
		return nil, "verify: " .. err
	end
	return gws, ret.userId
end

return M
