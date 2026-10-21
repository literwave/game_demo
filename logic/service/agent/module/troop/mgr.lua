all_user_troop_tbl = {}

function ref_troop(troop)
	local user_id = troop:get_user_id()
	if not all_user_troop_tbl[user_id] then
		all_user_troop_tbl[user_id] = {}
	end
	all_user_troop_tbl[user_id][troop:get_troop_idx()] = troop
end

local function create_troop(oci)
	return TROOP_BASE.cls_troop:New(oci)
end

local function try_init_user_troops(user_id)
	if not ORM.get(MONGO_SLAVE.COL.USER_TROOP, user_id) then
		local raw = MONGO_SLAVE.common_load_single(MONGO_SLAVE.COL.USER_TROOP, user_id) or {}
		local doc = ORM.create(ORM.CLS_USER_TROOP_DOC, raw)
		ORM.hold(doc, MONGO_SLAVE.COL.USER_TROOP, user_id)
		all_user_troop_tbl[user_id] = {}
		for _, troop_data in pairs(doc._troops) do
			if ORM.is_cls(troop_data, ORM.CLS_TROOP_DATA) then
				create_troop(troop_data)
			end
		end
	end
	return all_user_troop_tbl[user_id]
end

function get_troop(user_id, troop_idx)
	local troop_tbl = try_init_user_troops(user_id)
	return troop_tbl[troop_idx]
end

function on_user_logout(user_id)
	if ORM.get(MONGO_SLAVE.COL.USER_TROOP, user_id) then
		MONGO_SLAVE.flush()
		all_user_troop_tbl[user_id] = nil
		ORM.forget(MONGO_SLAVE.COL.USER_TROOP, user_id)
	end
end

local function parse_pos_hero_list(pos_hero_map)
	local list = {}
	if not pos_hero_map then
		return list
	end
	if pos_hero_map[1] then
		for _, entry in ipairs(pos_hero_map) do
			list[#list + 1] = {
				pos = entry.key,
				hero_idx = entry.value,
			}
		end
		return list
	end
	for pos, hero_idx in pairs(pos_hero_map) do
		list[#list + 1] = {
			pos = pos,
			hero_idx = hero_idx,
		}
	end
	return list
end

local function check_edit(user_id, troop_idx, pos_hero_list)
	if not troop_idx or troop_idx < 1 or troop_idx > DATA_COMMON.get_troop_max_cnt() then
		return
	end
	local used_hero = {}
	local used_pos = {}
	local pos_cnt = DATA_COMMON.get_troop_pos_cnt()
	for _, info in ipairs(pos_hero_list) do
		local pos = info.pos
		local hero_idx = info.hero_idx
		if not hero_idx or not pos or pos < 1 or pos > pos_cnt then
			return
		end
		if used_hero[hero_idx] or used_pos[pos] then
			return
		end
		if not HERO_MGR.get_hero_by_type(user_id, hero_idx) then
			return
		end
		used_hero[hero_idx] = true
		used_pos[pos] = true
	end
	return true
end

local function take_hero_off_other_troops(user_id, troop_idx, hero_idx)
	local troop_tbl = try_init_user_troops(user_id)
	for idx, troop in pairs(troop_tbl) do
		if idx ~= troop_idx then
			local pos_list = {}
			for pos, hero in pairs(troop:get_pos_hero_tbl()) do
				if hero == hero_idx then
					pos_list[#pos_list + 1] = pos
				end
			end
			for _, pos in ipairs(pos_list) do
				troop:set_pos_hero(pos, nil)
			end
		end
	end
end

local function on_req_troop(fd)
	local user_id = USER_MGR.get_user_id_by_fd(fd)
	if not user_id then
		return
	end
	local troop_list = {}
	for _, troop in pairs(try_init_user_troops(user_id)) do
		troop_list[#troop_list + 1] = troop:get_pto_info()
	end
	for_caller.s2c_req_troop(fd, {
		troopList = troop_list,
	})
end

local function on_edit_troop(fd, packet)
	local user_id = USER_MGR.get_user_id_by_fd(fd)
	if not user_id then
		return
	end
	local troop_info = packet.troopInfo
	if not troop_info then
		return
	end
	local troop_idx = troop_info.troopIdx
	local pos_hero_list = parse_pos_hero_list(troop_info.pos2HeroMap)
	if not check_edit(user_id, troop_idx, pos_hero_list) then
		return
	end
	try_init_user_troops(user_id)
	local troop = get_troop(user_id, troop_idx)
	if not troop then
		troop = create_troop({
			_user_id = user_id,
			_troop_idx = troop_idx,
		})
	end
	for _, info in ipairs(pos_hero_list) do
		take_hero_off_other_troops(user_id, troop_idx, info.hero_idx)
	end
	troop:clear_pos_hero()
	for _, info in ipairs(pos_hero_list) do
		troop:set_pos_hero(info.pos, info.hero_idx)
	end
	for_caller.s2c_edit_troop(fd, {
		troopInfo = troop:get_pto_info(),
	})
end

function __init__()
	for_maker.c2s_req_troop = on_req_troop
	for_maker.c2s_edit_troop = on_edit_troop
end
