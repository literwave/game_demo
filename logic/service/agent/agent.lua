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

function CMD.login(gate_srv, fd, user_id, addr, account, server_id, token)
	skynet.error("login step 3-agent", fd, user_id, addr, account)
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
	user:set_and_sync_verify_login(token)
	user:set_account(account)
	user:set_login_addr(addr)
	user:set_and_sync_heart_beat_time(TIME.os_bj_sec())
	USER_MGR.module_on_user_login(user, is_first_login)
	local times = TIME.get_diff_day(TIME.os_bj_sec(), last_login_time)
	if times > 1 then
		USER_MGR.module_on_user_next_day(user, times)
	end
	CALL_OUT.call_once("USER_MGR", "module_on_user_next_day", 24, user_id)
	EVENT.emit(CONST.EVENT.ON_USER_LOGIN, user_id, fd, gate_srv, is_first_login)
end

function CMD.disconnect(fd, user_id)
	user_queues[user_id] = nil
	USER_MGR.disconnect(fd, user_id)
	EVENT.emit(CONST.EVENT.ON_USER_LOGOUT, user_id, fd)
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
	assert(ITEM_MGR.del_cost_list(user_id, item_list))
end

function RPC_CMD.sub_item_list(id, user_id, taddr, item_list, reason_list)
	if not ITEM_MGR.check_cost_enough(user_id, item_list) then
		skynet.send(taddr, "rpc", id, false)
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
		if not user_queues[user_id] then
			user_queues[user_id] = queue()
		end
		local user_queue = user_queues[user_id]
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
		-- 分发数据
		local ok, err = xpcall(user_queue, error_handler, for_maker[pto_name], fd, msg)
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