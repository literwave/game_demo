local skynet = require "skynet"

-- 邮件协议转给 .mail；领奖要在 agent 发，先让 .mail 标记已领并拿回奖励
local FORWARD_LIST = {
	"c2s_req_mail_list",
	"c2s_req_mail_detail",
	"c2s_del_mail_list",
	"c2s_set_mail_lock",
}

local function forward(pto_name)
	return function(fd, packet)
		local user_id = USER_MGR.get_user_id_by_fd(fd)
		if not user_id then
			return
		end
		skynet.send(".mail", "lua", "client", pto_name, user_id, packet)
	end
end

local function on_get_mail_reward(fd, packet)
	local user_id = USER_MGR.get_user_id_by_fd(fd)
	if not user_id then
		return
	end
	local ret = skynet.call(".mail", "lua", "take_rewards", user_id, packet.mailKindUidList or {})
	if #ret.rewards > 0 then
		REWARD_MGR.reward_user_and_show(user_id, ret.rewards, {CONST.FLOW_REASON.MAIL})
	end
	for_caller.s2c_get_mail_reward(fd, {mailKindUidList = ret.kind_uid_list})
end

function on_user_login(user_id, fd, gate_srv, is_first_login)
	if is_first_login then
		MAIL.send_user_mail(user_id, CONST.MAIL_ID.WELCOME)
	end
end

function __init__()
	for _, pto_name in ipairs(FORWARD_LIST) do
		for_maker[pto_name] = forward(pto_name)
	end
	for_maker.c2s_get_mail_reward = on_get_mail_reward
	EVENT.listen(CONST.EVENT.ON_USER_LOGIN)
end
