union_tbl = {
	-- [union_id] = union
}

function on_user_login(user_id, fd, gate_srv, is_first_login)
end

function on_user_logout(user_id, fd)
end

function kick_user(fd, user_id)
end

function __init__()
	EVENT.register(CONST.EVENT.ON_USER_LOGIN)
	EVENT.register(CONST.EVENT.ON_USER_LOGOUT)
	EVENT.register(CONST.EVENT.KICK_USER)
end
