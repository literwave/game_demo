local CMD = {}

function CMD.help(vfd, cmd)
	local cmdDescTbl = {
		["code"] = "执行服务端代码[code codeString]",
		["update"] = "重新加载lua文件: [update file]",
		["full_build"] = "所有建筑升至满级 [full_build]",
		["add_time"] = "增加时间 [add_time hour,min,sec]",
		["reset_time"] = "重置时间 [reset_time]",
		["show_time"] = "显示时间 [show_time]",
		["add_item"] = "增加道具[add_item itemType,cnt]",
		["del_item"] = "删除道具[del_item itemType,cnt]",
		["add_hero"] = "添加武将[add_hero heroType]",
		["full_hero"] = "满武将[full_hero]",
	}
	local ret = {}
	if cmd then
		local desc = cmdDescTbl[cmd] or ""
		table.insert(ret, makeCommonPtoTbl(cmd, desc))
		for_caller.s2c_gm_command_help(vfd, {ret = ret})
	end
end

CMD.h = CMD.help

local function onGmCommand(vfd, cmd)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	local cmdTbl = string.split(cmd, " ")
	local funcName = cmdTbl[1]
	local func = CMD[funcName]
	if not func then
		USER_MGR.tellMe(userId, "没有这个指令")
		return
	end
	skynet.error(string.format("gmcmd:%s %s", userId, cmd))
	local args = {}
	if cmdTbl[1] == "code" then
		table.insert(args, cmdTbl[2])
	elseif cmdTbl[2] then
		local list = string.split(cmdTbl[2], ",")
		for k, v in ipairs(list) do
			local arg = tonumber(v)
			if arg == nil then
				arg = v
			end
			table.insert(args, arg)
		end
	end
	local ret = xpcall(function()
		func(vfd, unpack(args))
	end, __G__TRACKBACK__)
	if ret then
		USER_MGR.tellMe(userId, "指令使用成功")
	else
		USER_MGR.tellMe(userId, "指令使用失败报错")
	end
end

function __init__()
	for_maker.c2s_gm_command = onGmCommand
end