local skynet = require "skynet"

if SERVICE_NAME ~= "agent" then
local CALL_NO = 1
local CALL_TBL = {}
RPC_MOD = {}
local function add_call_back_tbl(mod_name, cb, ...)
	CALL_TBL[CALL_NO] = {mod_name = mod_name, cb = cb, args = {...}}
	CALL_NO = CALL_NO % 10000000
end

local function get_call_back_tbl(id)
	return CALL_TBL[id]
end
function sub_item_list(user_id, cb, item_list, reason_list)
	local t_addr = USER_MGR.get_agent_by_user_id(user_id)
	local s_addr = SERVICE_NAME
	local tbl = {
		args = item_list,
		s_addr = s_addr,
	}
	local id = CALL_NO
	add_call_back_tbl(getfenv(2), cb, item_list, reason_list)
	skynet.send(t_addr, "rpc", "sub_item_list", id, skynet.self(),user_id,tbl)
end

function sub_item_list(id, ok, user_id)
	local tbl = get_call_back_tbl(id)
	local mod_name = tbl.mod_name
	local func_name = tbl.func
	local ret = _G[mod_name][func_name](ok, user_id)
	return ret
end

end

function gen_reward_info(reward_type, item_id, item_count)
	return {reward_type = reward_type, item_id = item_id, item_count = item_count}
end