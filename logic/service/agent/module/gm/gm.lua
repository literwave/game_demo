local skynet = require "skynet"

local CMD = {}

local CMD_DESC = {
	{ "help", "查看指令 [help] 或 [help 指令名]" },
	{ "code", "执行服务端代码 [code codeString]" },
	{ "update", "重新加载 lua 文件 [update file]" },
	{ "full_build", "所有建筑升至满级 [full_build]" },
	{ "add_time", "增加时间 [add_time hour,min,sec]" },
	{ "reset_time", "重置时间 [reset_time]" },
	{ "show_time", "显示时间 [show_time]" },
	{ "add_item", "增加道具 [add_item itemId,cnt]" },
	{ "del_item", "删除道具 [del_item itemId,cnt]" },
	{ "add_hero", "添加武将 [add_hero heroType]" },
	{ "full_hero", "获得全部武将 [full_hero]" },
	{ "add_exp", "增加主角经验 [add_exp exp]" },
	{ "open_system", "解锁系统 [open_system systemId]，0为全部" },
}

local function tell(vfd, msg)
	local user_id = USER_MGR.get_user_id_by_vfd(vfd)
	if user_id then
		USER_MGR.tell_me(user_id, msg)
	end
end

function CMD.help(vfd, cmd)
	if cmd then
		local desc = "没有这个指令"
		for _, item in ipairs(CMD_DESC) do
			if item[1] == cmd then
				desc = item[2]
				break
			end
		end
		tell(vfd, desc)
	else
		for _, item in ipairs(CMD_DESC) do
			tell(vfd, item[2])
		end
	end
	for_caller.s2c_gm_command_help(vfd, { ret = {} })
end

CMD.h = CMD.help

function CMD.code(vfd, code_string)
	assert(type(code_string) == "string" and code_string ~= "", "empty code")
	local fn, err = load(code_string, "gmcode")
	assert(fn, err)
	fn()
end

function CMD.update(vfd, file)
	assert(type(file) == "string" and file ~= "", "empty file")
	assert(update_lua_file(file))
end

function CMD.full_build(vfd)
	local user_id = USER_MGR.get_user_id_by_vfd(vfd)
	local build_tbl = BUILD_MGR.get_user_build_tbl(user_id)
	for _, build in pairs(build_tbl) do
		build:set_level(DATA_COMMON.get_build_max_level(build:get_build_type()))
		build:sync_to_client()
	end
end

function CMD.add_time(vfd, hour, min, sec)
	hour = hour or 0
	min = min or 0
	sec = sec or 0
	TIME.add_offset(hour * CONST.ONE_HOUR_SEC + min * 60 + sec)
	tell(vfd, os.date("%Y-%m-%d %H:%M:%S", TIME.os_bj_sec()))
end

function CMD.reset_time(vfd)
	TIME.reset_offset()
	tell(vfd, os.date("%Y-%m-%d %H:%M:%S", TIME.os_bj_sec()))
end

function CMD.show_time(vfd)
	tell(vfd, os.date("%Y-%m-%d %H:%M:%S", TIME.os_bj_sec()))
end

function CMD.add_item(vfd, item_id, cnt)
	assert(item_id and cnt and cnt > 0)
	local user_id = USER_MGR.get_user_id_by_vfd(vfd)
	REWARD_MGR.reward_user_and_show(user_id, {
		GLOBAL_FUNC.gen_reward_info(CONST.REWARD_TYPE_ITEM, item_id, cnt),
	}, {})
end

function CMD.del_item(vfd, item_id, cnt)
	assert(item_id and cnt and cnt > 0)
	local user_id = USER_MGR.get_user_id_by_vfd(vfd)
	assert(ITEM_MGR.del_cost_list(user_id, {
		{
			cost_type = CONST.COST_TYPE.ITEM,
			itemId = item_id,
			count = cnt,
		},
	}))
end

function CMD.add_hero(vfd, hero_type)
	assert(hero_type)
	local user_id = USER_MGR.get_user_id_by_vfd(vfd)
	HERO_MGR.add_hero(user_id, hero_type, {})
end

function CMD.full_hero(vfd)
	local user_id = USER_MGR.get_user_id_by_vfd(vfd)
	for _, hero_type in ipairs(DATA_COMMON.get_all_hero_types()) do
		HERO_MGR.add_hero(user_id, hero_type, {})
	end
end

function CMD.add_exp(vfd, exp)
	assert(exp and exp > 0)
	local user = USER_MGR.get_user_by_fd(vfd)
	assert(user)
	user:add_exp(exp)
end

function CMD.open_system(vfd, system_id)
	assert(system_id)
	local user = USER_MGR.get_user_by_fd(vfd)
	assert(user)
	if system_id == 0 then
		SYSTEM_OPEN.open_all(user)
		return
	end
	assert(DATA_COMMON.get_system_open_tbl()[system_id], system_id)
	SYSTEM_OPEN.open_system(user, system_id)
end

local function on_gm_command(fd, packet)
	local cmd = packet and packet.cmd
	if type(cmd) ~= "string" or cmd == "" then
		return
	end
	local user_id = USER_MGR.get_user_id_by_vfd(fd)
	if not user_id then
		return
	end
	local cmd_tbl = string.split(cmd, " ")
	local func_name = cmd_tbl[1]
	local func = CMD[func_name]
	if not func then
		USER_MGR.tell_me(user_id, "没有这个指令")
		return
	end
	skynet.error(string.format("gmcmd:%s %s", user_id, cmd))
	local args = {}
	if func_name == "code" then
		table.insert(args, string.match(cmd, "^%S+%s+(.*)$"))
	elseif cmd_tbl[2] then
		for _, v in ipairs(string.split(cmd_tbl[2], ",")) do
			table.insert(args, tonumber(v) or v)
		end
	end
	local ok = xpcall(function()
		func(fd, table.unpack(args))
	end, __G__TRACKBACK__)
	if ok then
		USER_MGR.tell_me(user_id, "指令使用成功")
	else
		USER_MGR.tell_me(user_id, "指令使用失败报错")
	end
end

function __init__()
	for_maker.c2s_gm_command = on_gm_command
end
