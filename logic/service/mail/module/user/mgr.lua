-- 在线玩家（登录事件里拿到 fd 和 gate），用来直接给客户端回包
-- 事件分发顺序不定，邮件模块的上下线由这里记好 fd 后再调

fd_to_user_id = {}
user_id_to_fd = {}
fd_to_gate_srv = {}

function get_fd_by_user_id(user_id)
	return user_id_to_fd[user_id]
end

function get_gate_srv_by_fd(fd)
	return fd_to_gate_srv[fd]
end

function is_online(user_id)
	return user_id_to_fd[user_id] ~= nil
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

local function disconnect(fd, user_id)
	if user_id_to_fd[user_id] ~= fd then
		return
	end
	user_id_to_fd[user_id] = nil
	fd_to_user_id[fd] = nil
	fd_to_gate_srv[fd] = nil
	MAIL_MGR.on_user_logout(user_id)
end

function on_user_login(user_id, fd, gate_srv)
	local old_fd = user_id_to_fd[user_id]
	if old_fd and old_fd ~= fd then
		fd_to_user_id[old_fd] = nil
		fd_to_gate_srv[old_fd] = nil
	end
	user_id_to_fd[user_id] = fd
	fd_to_user_id[fd] = user_id
	fd_to_gate_srv[fd] = gate_srv
	MAIL_MGR.on_user_login(user_id)
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
