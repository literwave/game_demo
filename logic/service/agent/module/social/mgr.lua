local skynet = require "skynet"

-- 联盟、聊天协议转给 .union，带上玩家名片；名片变化时也推一份，联盟成员列表用
local FORWARD_LIST = {
	"c2s_req_my_alliance",
	"c2s_req_alliance_info",
	"c2s_req_alliance_list",
	"c2s_create_alliance",
	"c2s_dissolve_alliance",
	"c2s_leave_alliance",
	"c2s_kick_member",
	"c2s_apply_alliance",
	"c2s_cancel_apply",
	"c2s_req_apply_list",
	"c2s_handle_apply",
	"c2s_invite_alliance",
	"c2s_handle_invite",
	"c2s_req_member_list",
	"c2s_set_alliance_info",
	"c2s_set_member_pos",
	"c2s_transfer_leader",
	"c2s_chat",
	"c2s_req_chat_list",
}

local function brief_of(user)
	return {
		uid = user:get_user_id(),
		name = user:get_name(),
		head_icon = user:get_head_icon(),
		level = user:get_level(),
		power = user:get_power(),
	}
end

-- 转发前在 agent 里先判断的条件，不满足就不转
local PRE_CHECK = {
	c2s_create_alliance = function(user)
		if not user:is_system_open(CREATE_ALLIANCE) then
			USER_MGR.tell_me(user:get_user_id(), "创建联盟未开放")
			return false
		end
		return true
	end,
}

local function forward(pto_name)
	return function(fd, packet)
		local user = USER_MGR.get_user_by_fd(fd)
		if not user then
			return
		end
		local check = PRE_CHECK[pto_name]
		if check and not check(user) then
			return
		end
		skynet.send(".union", "lua", "client", pto_name, brief_of(user), packet)
	end
end

local function push_brief(user_id)
	skynet.send(".union", "lua", "update_brief", brief_of(USER_MGR.try_init_user(user_id)))
end

function on_user_login(user_id)
	push_brief(user_id)
end

function on_hero_add(user_id)
	push_brief(user_id)
end

function on_head_icon(user_id)
	push_brief(user_id)
end

function on_user_level(user_id)
	push_brief(user_id)
end

function on_hero_level(user_id)
	push_brief(user_id)
end

function __init__()
	for _, pto_name in ipairs(FORWARD_LIST) do
		for_maker[pto_name] = forward(pto_name)
	end
	EVENT.listen(CONST.EVENT.ON_USER_LOGIN)
	EVENT.listen(CONST.EVENT.ON_HERO_ADD)
	EVENT.listen(CONST.EVENT.ON_HEAD_ICON)
	EVENT.listen(CONST.EVENT.ON_USER_LEVEL)
	EVENT.listen(CONST.EVENT.ON_HERO_LEVEL)
end
