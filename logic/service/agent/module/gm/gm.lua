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
	{ "add_item", "增加道具 [add_item itemType,cnt]" },
	{ "del_item", "删除道具 [del_item itemType,cnt]" },
	{ "add_hero", "添加武将 [add_hero heroType]" },
	{ "full_hero", "获得全部武将 [full_hero]" },
}

local function tell(vfd, msg)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	if userId then
		USER_MGR.tellMe(userId, msg)
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

function CMD.code(vfd, codeString)
	assert(type(codeString) == "string" and codeString ~= "", "empty code")
	local fn, err = load(codeString, "gmcode")
	assert(fn, err)
	fn()
end

function CMD.update(vfd, file)
	assert(type(file) == "string" and file ~= "", "empty file")
	assert(updateLuaFile(file))
end

function CMD.full_build(vfd)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	local buildTbl = BUILD_MGR.getUserBuildTbl(userId)
	for _, build in pairs(buildTbl) do
		build:setLevel(DATA_COMMON.getBuildMaxLevel(build:getBuildType()))
		build:syncToClient()
	end
end

function CMD.add_time(vfd, hour, min, sec)
	hour = hour or 0
	min = min or 0
	sec = sec or 0
	TIME.addOffset(hour * CONST.ONE_HOUR_SEC + min * 60 + sec)
	tell(vfd, os.date("%Y-%m-%d %H:%M:%S", TIME.osBJSec()))
end

function CMD.reset_time(vfd)
	TIME.resetOffset()
	tell(vfd, os.date("%Y-%m-%d %H:%M:%S", TIME.osBJSec()))
end

function CMD.show_time(vfd)
	tell(vfd, os.date("%Y-%m-%d %H:%M:%S", TIME.osBJSec()))
end

function CMD.add_item(vfd, itemType, cnt)
	assert(itemType and cnt and cnt > 0)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	REWARD_MGR.rewardUserAndShow(userId, {
		GLOBAL_FUNC.genRewardInfo(CONST.REWARD_TYPE_ITEM, itemType, cnt),
	}, {})
end

function CMD.del_item(vfd, itemType, cnt)
	assert(itemType and cnt and cnt > 0)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	assert(ITEM_MGR.delCostList(userId, {
		{
			costType = CONST.COST_TYPE.ITEM,
			itemId = itemType,
			count = cnt,
		},
	}))
end

function CMD.add_hero(vfd, heroType)
	assert(heroType)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	HERO_MGR.addHero(userId, heroType, {})
end

function CMD.full_hero(vfd)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	for _, heroType in ipairs(DATA_COMMON.getAllHeroTypes()) do
		HERO_MGR.addHero(userId, heroType, {})
	end
end

local function onGmCommand(fd, packet)
	local cmd = packet and packet.cmd
	if type(cmd) ~= "string" or cmd == "" then
		return
	end
	local userId = USER_MGR.getUserIdByVfd(fd)
	if not userId then
		return
	end
	local cmdTbl = string.split(cmd, " ")
	local funcName = cmdTbl[1]
	local func = CMD[funcName]
	if not func then
		USER_MGR.tellMe(userId, "没有这个指令")
		return
	end
	skynet.error(string.format("gmcmd:%s %s", userId, cmd))
	local args = {}
	if funcName == "code" then
		table.insert(args, string.match(cmd, "^%S+%s+(.*)$"))
	elseif cmdTbl[2] then
		for _, v in ipairs(string.split(cmdTbl[2], ",")) do
			table.insert(args, tonumber(v) or v)
		end
	end
	local ok = xpcall(function()
		func(fd, table.unpack(args))
	end, __G__TRACKBACK__)
	if ok then
		USER_MGR.tellMe(userId, "指令使用成功")
	else
		USER_MGR.tellMe(userId, "指令使用失败报错")
	end
end

function __init__()
	for_maker.c2s_gm_command = onGmCommand
end
