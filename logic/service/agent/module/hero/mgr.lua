user_hero_tbl = {}
--[[
	[userId] = {
		[heroType] = hero,
	}
--]]

local function ref_hero(hero)
	local user_id = hero:get_user_id()
	if not user_hero_tbl[user_id] then
		user_hero_tbl[user_id] = {}
	end
	local hero_type = hero:get_hero_type()
	user_hero_tbl[user_id][hero_type] = hero
end

function create_hero(oci)
	local hero = CLS_HERO.cls_hero:New(oci)
	ref_hero(hero)
	return hero
end

local function try_init_user_hero_data(user_id)
	if not ORM.get(MONGO_SLAVE.COL.USER_HERO, user_id) then
		local raw = MONGO_SLAVE.common_load_single(MONGO_SLAVE.COL.USER_HERO, user_id) or {}
		local doc = ORM.create(ORM.CLS_USER_HERO_DOC, raw)
		ORM.hold(doc, MONGO_SLAVE.COL.USER_HERO, user_id)
		user_hero_tbl[user_id] = {}
		for _, hero_data in pairs(doc._heroes) do
			if ORM.is_cls(hero_data, ORM.CLS_HERO_DATA) then
				create_hero(hero_data)
			end
		end
	end
	return user_hero_tbl[user_id]
end

function get_hero_tbl_by_user_id(user_id)
	return try_init_user_hero_data(user_id)
end

function get_hero_by_type(user_id, hero_type)
	local hero_tbl = try_init_user_hero_data(user_id)
	return hero_tbl[hero_type]
end

function save_data()
	MONGO_SLAVE.flush()
end

function add_hero(user_id, hero_type, reason_list)
	assert(user_id)
	local hero_info = DATA_COMMON.get_hero_info_by_type(hero_type)
	assert(hero_info)
	local exist = get_hero_by_type(user_id, hero_type)
	if exist then
		return exist
	end
	try_init_user_hero_data(user_id)
	local skill_tbl = {}
	local skill_id = hero_info.SkillId
	if skill_id then
		skill_tbl[skill_id] = 1
	end
	local oci = {
		_user_id = user_id,
		_hero_type = hero_type,
		_new_tag = true,
		_level = 1,
		_star = 1,
		_skill_tbl = skill_tbl,
	}
	local hero = create_hero(oci)
	hero:sync_to_client()
	return hero
end

local function on_req_all_hero_base_info(fd)
	local hero_tbl = get_hero_tbl_by_user_id(USER_MGR.get_user_id_by_fd(fd))
	local hero_info_list = {}
	for _, hero in pairs(hero_tbl) do
		table.insert(hero_info_list, hero:get_hero_pto_base_info())
	end
	for_caller.s2c_req_all_hero_base_info(fd, {heroInfoList = hero_info_list})
end

function __init__()
	for_maker.c2s_req_all_hero_base_info = on_req_all_hero_base_info
end
