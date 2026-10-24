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
	local doc, is_loaded = ORM.load(MONGO_SLAVE.COL.USER_TROOP, user_id, ORM.CLS_USER_TROOP_DOC)
	if is_loaded then
		all_user_troop_tbl[user_id] = {}
		for _, troop_data in pairs(doc._troops) do
			create_troop(troop_data)
		end
	end
	return all_user_troop_tbl[user_id]
end

function get_user_troops(user_id)
	return try_init_user_troops(user_id)
end

function get_troop(user_id, troop_idx)
	local troop_tbl = try_init_user_troops(user_id)
	return troop_tbl[troop_idx]
end

function deployed_soldier(user_id)
	local sum = 0
	for _, troop in pairs(try_init_user_troops(user_id)) do
		sum = sum + troop:get_soldier_sum()
	end
	return sum
end

function on_user_logout(user_id)
	if ORM.get(MONGO_SLAVE.COL.USER_TROOP, user_id) then
		MONGO_SLAVE.flush()
		all_user_troop_tbl[user_id] = nil
		ORM.unbind(MONGO_SLAVE.COL.USER_TROOP, user_id)
	end
end

local function parse_pos_list(pos_map)
	local list = {}
	if not pos_map then
		return list
	end
	local first = pos_map[1]
	if first and first.key ~= nil then
		for _, entry in ipairs(pos_map) do
			local value = entry.value or {}
			local soldier = value.soldier or {}
			list[#list + 1] = {
				pos = entry.key,
				hero_idx = value.heroIdx,
				count = soldier.count or 0,
				hurt = soldier.hurtCount or 0,
			}
		end
		return list
	end
	for pos, value in pairs(pos_map) do
		local soldier = value.soldier or {}
		list[#list + 1] = {
			pos = pos,
			hero_idx = value.heroIdx,
			count = soldier.count or 0,
			hurt = soldier.hurtCount or 0,
		}
	end
	return list
end

local function check_edit(user_id, troop_idx, pos_list)
	if not troop_idx or troop_idx < 1 or troop_idx > DATA_COMMON.get_troop_max_cnt() then
		return
	end
	local troop = get_troop(user_id, troop_idx)
	if troop and troop:is_marching() then
		return
	end
	local used_hero = {}
	local used_pos = {}
	local pos_cnt = DATA_COMMON.get_troop_pos_cnt()
	for _, info in ipairs(pos_list) do
		local pos = info.pos
		local hero_idx = info.hero_idx
		if not hero_idx or not pos or pos < 1 or pos > pos_cnt then
			return
		end
		if info.count < 0 or info.hurt < 0 or info.hurt > info.count then
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

local function sync_all_troop(fd, user_id)
	local troop_list = {}
	for _, troop in pairs(get_user_troops(user_id)) do
		troop_list[#troop_list + 1] = troop:get_pto_info()
	end
	for_caller.s2c_req_troop(fd, {
		troopList = troop_list,
	})
end

local function on_req_troop(fd)
	local user_id = USER_MGR.get_user_id_by_fd(fd)
	if not user_id then
		return
	end
	sync_all_troop(fd, user_id)
end

local function on_edit_troop(fd, packet)
	local user = USER_MGR.get_user_by_fd(fd)
	if not user then
		return
	end
	local troop_info = packet.troopInfo
	if not troop_info then
		return
	end
	local user_id = user:get_user_id()
	local troop_idx = troop_info.troopIdx
	local pos_list = parse_pos_list(troop_info.posMap)
	if not check_edit(user_id, troop_idx, pos_list) then
		return
	end
	try_init_user_troops(user_id)
	local troop = get_troop(user_id, troop_idx)
	local old_sum = 0
	if troop then
		old_sum = troop:get_soldier_sum()
	end
	local new_sum = 0
	local old_hurt = {}
	if troop then
		for _, info in pairs(troop:get_pos_tbl()) do
			old_hurt[info._hero_idx] = info._hurt_cnt
		end
	end
	for _, info in ipairs(pos_list) do
		new_sum = new_sum + info.count
		local kept = old_hurt[info.hero_idx] or 0
		if info.hurt > kept then
			info.hurt = kept
		end
		if info.hurt > info.count then
			info.hurt = info.count
		end
	end
	local strips = {}
	local back = 0
	for _, info in ipairs(pos_list) do
		for idx, other in pairs(get_user_troops(user_id)) do
			if idx ~= troop_idx then
				local pos, pinfo = other:find_hero(info.hero_idx)
				if pos then
					if other:is_marching() then
						return
					end
					back = back + pinfo._soldier_cnt
					strips[#strips + 1] = {idx = idx, pos = pos}
					break
				end
			end
		end
	end
	local city_after = user:get_soldier_cnt() + old_sum + back
	local keep = deployed_soldier(user_id) - old_sum - back
	if new_sum > city_after or new_sum + keep > DATA_COMMON.get_soldier_max() then
		return
	end
	for _, strip in ipairs(strips) do
		get_troop(user_id, strip.idx):set_pos(strip.pos, nil)
	end
	if not troop then
		troop = create_troop({
			_user_id = user_id,
			_troop_idx = troop_idx,
		})
	end
	troop:clear_pos()
	for _, info in ipairs(pos_list) do
		troop:set_pos(info.pos, info.hero_idx, info.count, info.hurt)
	end
	user:set_soldier_cnt(city_after - new_sum)
	user:sync_soldier()
	for_caller.s2c_edit_troop(fd, {
		troopInfo = troop:get_pto_info(),
	})
	if #strips > 0 then
		sync_all_troop(fd, user_id)
	end
end

function __init__()
	for_maker.c2s_req_troop = on_req_troop
	for_maker.c2s_edit_troop = on_edit_troop
	EVENT.listen(CONST.EVENT.ON_USER_LOGOUT)
end
