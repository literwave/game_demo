-- 在线玩家（登录事件里拿到 fd 和 gate）和玩家名片缓存
-- 名片 brief = {uid, name, head_icon, level, power}，由 agent 转发协议或刷新时带过来

local skynet = require "skynet"

local agent_list

fd_to_user_id = {}
user_id_to_fd = {}
fd_to_gate_srv = {}
-- [user_id] = brief，只缓存启动以来上报过的玩家
brief_tbl = {}

function get_fd_by_user_id(user_id)
	return user_id_to_fd[user_id]
end

function get_user_id_by_fd(fd)
	return fd_to_user_id[fd]
end

function get_gate_srv_by_fd(fd)
	return fd_to_gate_srv[fd]
end

function is_online(user_id)
	return user_id_to_fd[user_id] ~= nil
end

function get_brief(user_id)
	return brief_tbl[user_id]
end

function update_brief(brief)
	brief_tbl[brief.uid] = brief
end

function send(user_id, pto_name, msg)
	local fd = user_id_to_fd[user_id]
	if fd then
		for_caller[pto_name](fd, msg)
	end
end

function tell_me(user_id, msg)
	send(user_id, "s2c_tell_me", {msg = msg})
end

local function agent_of(user_id)
	if not agent_list then
		agent_list = skynet.call(".gated", "lua", "get_agent_list")
	end
	local n = #agent_list
	if n < 1 then
		return
	end
	return agent_list[user_id % n + 1]
end

-- 回 agent 扣玩家的消耗，会让出协程；扣不了（不够或不在线）返回 false
function cost_items(user_id, cost_list, reason_list)
	local agent = agent_of(user_id)
	if not agent then
		return false
	end
	return skynet.call(agent, "lua", "cost_items", user_id, cost_list, reason_list)
end

local function disconnect(fd, user_id)
	if user_id_to_fd[user_id] == fd then
		user_id_to_fd[user_id] = nil
	end
	fd_to_user_id[fd] = nil
	fd_to_gate_srv[fd] = nil
end

function on_user_login(user_id, fd, gate_srv)
	local old_fd = user_id_to_fd[user_id]
	if old_fd and old_fd ~= fd then
		disconnect(old_fd, user_id)
	end
	user_id_to_fd[user_id] = fd
	fd_to_user_id[fd] = user_id
	fd_to_gate_srv[fd] = gate_srv
end

function on_user_logout(user_id, fd)
	disconnect(fd, user_id)
end

function kick_user(fd, user_id)
	disconnect(fd, user_id)
end

function __init__()
	EVENT.register(CONST.EVENT.ON_USER_LOGIN)
	EVENT.register(CONST.EVENT.ON_USER_LOGOUT)
	EVENT.register(CONST.EVENT.KICK_USER)
end
