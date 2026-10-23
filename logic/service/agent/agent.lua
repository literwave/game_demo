local skynet = require "skynet"
local queue = require "skynet.queue"
local protobuf = require "protobuf"

local CMD = {}
local RPC_CMD = {}

local user_queues = {
	-- [userId] = queue(),
}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.unpack
}

skynet.register_protocol {
	name = "rpc",
	id = skynet.PTYPE_RPC,
	unpack = skynet.unpack
}

local function decode_pack(packet)
	local id, pos = string.unpack(">I2", packet, 3)
	local pto_name = ID_TO_PTONAME[id]
	local pack_name = ID_TO_PACK_NAME[id]
	if pto_name ~= "c2s_heart_beat" then
		skynet.error(id, pos)
	end
	return protobuf.decode(pack_name, packet:sub(pos)), pto_name
end

local function get_user_queue(user_id)
	local user_queue = user_queues[user_id]
	if not user_queue then
		user_queue = queue()
		user_queues[user_id] = user_queue
	end
	return user_queue
end

-- 顶号：旧连接可能在另一个 gate_worker 上，先解绑旧 fd 再踢，之后旧 fd 的 disconnect 会被忽略
local function kick_old_conn(user_id, new_fd)
	local old_fd = USER_MGR.get_fd_by_user_id(user_id)
	if not old_fd or old_fd == new_fd then
		return
	end
	local user = USER_MGR.get_user_by_id(user_id)
	local old_gate_srv = user and user:get_gate_srv()
	USER_MGR.del_user_id_by_vfd(old_fd)
	if old_gate_srv then
		skynet.send(old_gate_srv, "lua", "kick", old_fd)
	end
	skynet.error("relogin kick old conn", user_id, old_fd, new_fd)
end

local function do_login(gate_srv, fd, user_id, addr, account, server_id, token)
	skynet.error("login step 3-agent", fd, user_id, addr, account)
	kick_old_conn(user_id, fd)
	local user = false
	local is_first_login = false
	local last_login_time = TIME.os_bj_sec()
	if USER_MGR.is_new_user(user_id) then
		user = USER_MGR.create_new_user(gate_srv, fd, user_id, server_id)
		is_first_login = true
	else
		user = USER_MGR.try_init_user(user_id)
		USER_MGR.ref_login(user_id, fd, user)
		user:set_fd(fd)
		user:set_gate_srv(gate_srv)
		last_login_time = user:get_login_time()
	end
	user:set_token(token)
	user:set_account(account)
	user:set_login_addr(addr)
	USER_MGR.module_on_user_login(user, is_first_login)
	local times = TIME.get_diff_day(TIME.os_bj_sec(), last_login_time)
	if times > 1 then
		USER_MGR.module_on_user_next_day(user, times)
	end
	CALL_OUT.call_once("USER_MGR", "module_on_user_next_day", 24, user_id)
	EVENT.emit(CONST.EVENT.ON_USER_LOGIN, user_id, fd, gate_srv, is_first_login)
end

local is_closing = false

-- 和协议、下线走同一个玩家队列，避免登录和旧连接下线交错
function CMD.login(gate_srv, fd, user_id, addr, account, server_id, token)
	assert(not is_closing, "server is closing")
	return get_user_queue(user_id)(do_login, gate_srv, fd, user_id, addr, account, server_id, token)
end

local function do_disconnect(fd, user_id)
	-- 顶号后旧连接的断开：玩家已经在新 fd 上，只清旧 fd
	if USER_MGR.get_fd_by_user_id(user_id) ~= fd then
		if USER_MGR.get_user_id_by_fd(fd) == user_id then
			USER_MGR.del_user_id_by_vfd(fd)
		end
		return
	end
	USER_MGR.disconnect(fd, user_id)
	EVENT.emit(CONST.EVENT.ON_USER_LOGOUT, user_id, fd)
	-- 新连接的消息要等 login 返回后 worker 才会转发，这里删掉不会和新登录并发
	user_queues[user_id] = nil
end

-- 进玩家的消息队列里下线，等正在处理的协议跑完再存盘
function CMD.disconnect(fd, user_id)
	get_user_queue(user_id)(do_disconnect, fd, user_id)
end

function CMD.hot_update(path_list)
	return hot_update(path_list)
end

function CMD.shutdown()
	is_closing = true
	local online = {}
	for user_id, fd in pairs(USER_MGR.user_id_to_fd) do
		online[user_id] = fd
	end
	for user_id, fd in pairs(online) do
		CMD.disconnect(fd, user_id)
	end
	MONGO_SLAVE.flush_sync()
	skynet.fork(skynet.exit)
end

local function sub_item_list_recv(id, taddr, user_id, item_list, reason_list)
	if not ITEM_MGR.check_cost_enough(user_id, item_list) then
		skynet.send(taddr, "rpc", id, false)
		return
	end
	local ok = skynet.call(taddr, "rpc", id, true)
	if not ok then
		return
	end
	assert(ITEM_MGR.del_cost_list(user_id, item_list, reason_list))
end

function RPC_CMD.sub_item_list(id, user_id, taddr, item_list, reason_list)
	if not ITEM_MGR.check_cost_enough(user_id, item_list) then
		skynet.send(taddr, "rpc", id, false)
		return
	end
	local q = queue()
	local ok = q(sub_item_list_recv, id, taddr, user_id, item_list, reason_list)
end

local function error_handler(err)
	skynet.error("agent error：", err)
	skynet.error("stack: ", debug.traceback())
	return err
end

skynet.start(function()
	dofile "../logic/service/agent/preload.lua"
	skynet.dispatch("lua", function(seesion, _ , command, ...)
		local f = CMD[command]
		if seesion ~= 0 then
			skynet.ret(skynet.pack(f(...)))
		else
			f(...)
		end
	end)

	skynet.dispatch("client", function(seesion, address, fd, packet, user_id)
		if is_closing then
			return
		end
		local msg, pto_name = decode_pack(packet)
		if pto_name ~= "c2s_heart_beat" then
			skynet.error("fd", fd, pto_name, user_id)
		end
		assert(fd)
		if not for_maker[pto_name] then
			skynet.error("ptoName not registerptoName", pto_name)
			return
		end
		if pto_name ~= "c2s_heart_beat" then
			skynet.error(table2str(msg))
		end
		if not msg then
			return
		end
		-- 分发数据；执行时再确认 fd 仍是当前连接，顶号后旧连接残留的包丢掉
		local handler = for_maker[pto_name]
		local ok, err = xpcall(get_user_queue(user_id), error_handler, function()
			if USER_MGR.get_fd_by_user_id(user_id) ~= fd then
				return
			end
			handler(fd, msg)
		end)
		if not ok then
			LOG._error("userQueue error: %s", err)
		end
	end)

		skynet.dispatch("rpc", function(seesion, address, command,...)
			local f = RPC_CMD[command]
			if seesion ~= 0 then
				skynet.ret(skynet.pack(f(...)))
			else
				f(...)
			end
	end)
end)