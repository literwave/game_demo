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

-- 二次处理配置表的内容
init_build_list = {}
local function init_config_data()
	for _, conf in pairs(DATA_BUILD_DETAIL) do
		table.insert(init_build_list, conf.InitLev)
	end
end

local function init_system_open_enum()
	for system_id, conf in pairs(DATA_SYSTEM_OPEN) do
		local enum_name = conf.Enum
		assert(not _G[enum_name], enum_name)
		_G[enum_name] = conf.Id or system_id
	end
end

init_config_data()
init_system_open_enum()

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

function get_lottery_common_pools(use_lottery_times)
end

function get_lottery_hero_pools(use_lottery_times)
end

function get_up_hero_item_lottery_times(use_lottery_times)
end

function get_lottery_cost(use_lottery_times)
end

function can_overlap(item_id)
	return DATA_ITEM[item_id].can_overlap == 1
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
	return 1
end

function get_system_open_tbl()
	return DATA_SYSTEM_OPEN
end