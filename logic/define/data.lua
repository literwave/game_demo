local sharedata = require "skynet.sharedata"

local DATA_HERO = sharedata.query("Hero")
local DATA_REPORT = sharedata.query("ReportInfo")
local DATA_SERVER_GROUP = sharedata.query("ServerGroup")
local DATA_GLOBAL = sharedata.query("Global")
local DATA_BUILD_DETAIL = sharedata.query("BuildingDetail")
local DATA_BUILD_LEVEL = sharedata.query("BuildingLv")
local DATA_BUILD_CONF = sharedata.query("innerCity")
local DATA_HEAD_ICON = sharedata.query("HeadIcon")
local DATA_LOTTERY = sharedata.query("Lottery")
local DATA_ITEM = sharedata.query("Item")
local DATA_SYSTEM_OPEN = sharedata.query("SystemOpen")
-- local DATA_NAME_CN = sharedata.query("NameCn")

-- local conf = {
-- 	[CONST.LANGUAGE.CHINESE] = function()
-- 		return DATA_NAME_CN
-- 	end,
-- }

-- 二次处理配置表的内容。放在 __init__ 里：热更 / 重载配置时会先恢复旧模块变量再调 __init__，这里才能重算
local function init_config_data()
	init_build_list = {}
	for _, conf in pairs(DATA_BUILD_DETAIL) do
		table.insert(init_build_list, conf.InitLev)
	end
	-- [build_type] = { [lv] = conf }，build_max_level_tbl[build_type] = 配置里的最高等级
	build_lv_tbl = {}
	build_max_level_tbl = {}
	for _, conf in pairs(DATA_BUILD_LEVEL) do
		local b_type = conf.BuildingType
		build_lv_tbl[b_type] = build_lv_tbl[b_type] or {}
		build_lv_tbl[b_type][conf.Lv] = conf
		build_max_level_tbl[b_type] = math.max(build_max_level_tbl[b_type] or 0, conf.Lv)
	end
end

local function init_system_open_enum()
	for system_id, conf in pairs(DATA_SYSTEM_OPEN) do
		local enum_name = conf.Enum
		local value = conf.Id or system_id
		assert(_G[enum_name] == nil or _G[enum_name] == value, enum_name)
		_G[enum_name] = value
	end
end

function __init__()
	init_config_data()
	init_system_open_enum()
end

function get_value_by_key(key)
	return DATA_GLOBAL[key].value1 or DATA_GLOBAL[key].value2 or DATA_GLOBAL[key].value3
end

function get_user_level_up_exp()
	return get_value_by_key(5)
end

function get_troop_max_cnt()
	return get_value_by_key(6)
end

function get_troop_pos_cnt()
	return get_value_by_key(7)
end

local function get_report_info(report_id)
	return DATA_REPORT[report_id]
end

local function get_report_info_by_srv_group(group_id)
	local report_id = DATA_SERVER_GROUP[group_id].reportId
	return get_report_info(report_id)
end

function get_login_address_by_srv_group(group_id)
	local info = get_report_info_by_srv_group(group_id)
	return info.LoginDomain, info.HttpPort, info.HttpsPort
end

function get_first_name_list(language)
	local name_tbl = conf[language]()
	return name_tbl[1]
end

function get_hero_info_by_type(hero_type)
	return DATA_HERO[hero_type]
end

function get_head_icon_info(head_icon)
	return DATA_HEAD_ICON[head_icon]
end

function get_all_hero_types()
	local list = {}
	for hero_type in pairs(DATA_HERO) do
		table.insert(list, hero_type)
	end
	return list
end

function get_item_kind(item_id)
	local item_kind = DATA_ITEM[item_id].item_kind
	return item_kind
end

function get_initial_build_list()
	return init_build_list
end

function get_build_type_by_id(bid)
	return DATA_BUILD_CONF.builds[bid].build_type
end

-- Lottery 表的 Id 就是一次抽几发；没配的抽数不允许
-- 奖池每项 {reward_type, item_id, item_count, weight}
function get_lottery_conf(use_lottery_times)
	return DATA_LOTTERY[use_lottery_times]
end

function can_overlap(item_id)
	return (DATA_ITEM[item_id].Overlap or 1) > 1
end

function get_item_overlap(item_id)
	return DATA_ITEM[item_id].Overlap
end

function get_item_kind(item_id)
	return DATA_ITEM[item_id].Kind
end

function can_lock_mail()
end

function get_queue_capacity()
	return 5
end

function get_build_level_up_limit()
	return {}
end

function get_build_create_limit()
	return {}
end

function get_build_max_level(b_type)
	return build_max_level_tbl[b_type] or 0
end

function get_build_level_conf(b_type, lv)
	return build_lv_tbl[b_type] and build_lv_tbl[b_type][lv]
end

function get_system_open_tbl()
	return DATA_SYSTEM_OPEN
end