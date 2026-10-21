all_item_tbl = {
--[[
	[userId] = {
		[itemId] = {
			[itemUid] = item,
		},
	},
--]]
}

all_item_uid_tbl = {
--[[
	[userId] = {
		[itemUid] = item,
	}
--]]
}

all_item_kind_tbl = {
--[[
	[userId] = {
		[itemKind] = {
			[itemUid] = item,
		},
	}
--]]
}

local function ref_item(item)
	local user_id = item:get_user_id()
	local item_id = item:get_item_id()
	local item_uid = item:get_item_uid()
	local item_kind = item:get_item_kind()
	if not all_item_tbl[user_id] then
		all_item_tbl[user_id] = {}
	end
	if not all_item_tbl[user_id][item_id] then
		all_item_tbl[user_id][item_id] = {}
	end
	all_item_tbl[user_id][item_id][item_uid] = item
	if not all_item_uid_tbl[user_id] then
		all_item_uid_tbl[user_id] = {}
	end
	all_item_uid_tbl[user_id][item_uid] = item
	if not all_item_kind_tbl[user_id] then
		all_item_kind_tbl[user_id] = {}
	end
	if not all_item_kind_tbl[user_id][item_kind] then
		all_item_kind_tbl[user_id][item_kind] = {}
	end
	all_item_kind_tbl[user_id][item_kind][item_uid] = item
end

local check_enough_func = {
	[CONST.COST_TYPE.DIAMOND] = function(user_id, cost_info)
		local user = USER_MGR.try_init_user(user_id)
		return user:check_diamond_enough(user_id, cost_info.count)
	end,
	[CONST.COST_TYPE.RES] = function(user_id, cost_info)
		return RESOURCE.check_res_enough(user_id, cost_info.count)
	end,
	[CONST.COST_TYPE.ITEM] = function(user_id, cost_info)
		local item_info = ITEM_MGR.get_item_info(cost_info.itemId)
		if not item_info then
			return false
		end
		local item_count = ITEM_MGR.get_item_count(user_id, item_info.itemId)
		if item_count < cost_info.count then
			return false
		end
		return true
	end,
}

local sub_func = {
	[CONST.COST_TYPE.DIAMOND] = function(user_id, cost_info)
		local user = USER_MGR.try_init_user(user_id)
		user:sub_diamond(cost_info.count)
	end,
	[CONST.COST_TYPE.RES] = function(user_id, cost_info)
		return RESOURCE.check_res_enough(user_id, cost_info.count)
	end,
	[CONST.COST_TYPE.ITEM] = function(user_id, cost_info)
		local item_info = ITEM_MGR.get_item_info(cost_info.itemId)
		if not item_info then
			return false
		end
		local item_count = ITEM_MGR.get_item_count(user_id, item_info.itemId)
		if item_count < cost_info.count then
			return false
		end
		return true
	end,
}

function check_cost_enough(user_id, cost_list)
	if not next(cost_list) then
		return false
	end
	for _, const_info in ipairs(cost_list) do
		local func = check_enough_func[const_info.cost_type]
		if not func then
			return false
		end
		local is_enough = func(user_id, const_info)
		if not is_enough then
			return false
		end
	end
	return true
end

function del_cost_list(user_id, cost_list)
	for _, const_info in ipairs(cost_list) do
		local func = sub_func[const_info.cost_type]
		func(user_id, const_info)
	end
	return true
end

function get_item_max_add_cnt(item_id)
	return DATA_COMMON.get_item_overlap(item_id)
end

local ITEM_KIND_TO_MOD = {
	[CONST.ITEM_KIND.HERO_EQUIP] = CLS_HERO_EQUIP_ITEM,
}

local function create_item(oci)
	local item_id = oci._item_id
	assert(item_id)
	local kind = DATA_COMMON.get_item_kind(item_id)
	local mod = ITEM_KIND_TO_MOD[kind] or CLS_BASE_ITEM
	local item = mod.cls_item:New(oci)
	ref_item(item)
	return item
end

function unref_item(item)
	local user_id = item:get_user_id()
	local item_id = item:get_item_id()
	local item_uid = item:get_item_uid()
	local item_kind = item:get_item_kind()
	if all_item_tbl[user_id] and all_item_tbl[user_id][item_id] then
		all_item_tbl[user_id][item_id][item_uid] = nil
	end
	if all_item_uid_tbl[user_id] then
		all_item_uid_tbl[user_id][item_uid] = nil
	end
	if all_item_kind_tbl[user_id] and all_item_kind_tbl[user_id][item_kind] then
		all_item_kind_tbl[user_id][item_kind][item_uid] = nil
	end
end

local function try_init_user_data(user_id)
	if not ORM.get(MONGO_SLAVE.COL.USER_ITEM, user_id) then
		local raw = MONGO_SLAVE.common_load_single(MONGO_SLAVE.COL.USER_ITEM, user_id) or {}
		local doc = ORM.create(ORM.CLS_USER_ITEM_DOC, raw)
		ORM.hold(doc, MONGO_SLAVE.COL.USER_ITEM, user_id)
		all_item_uid_tbl[user_id] = {}
		for _, item_data in pairs(doc._items) do
			if ORM.is_cls(item_data, ORM.CLS_ITEM_DATA) then
				create_item(item_data)
			end
		end
	end
	return all_item_uid_tbl[user_id]
end

local function generate_item(user_id, item_id, cnt)
	local item_uid = get_id_by_user_id_and_timestamp(user_id)
	local oci = {
		_item_uid = item_uid,
		_item_id = item_id,
		_user_id = user_id,
		_item_cnt = cnt or 1,
	}
	try_init_user_data(user_id)
	local item = create_item(oci)
	item:after_generate()
	return item
end


local function do_add_item_cnt(user_id, item_id, cnt, need_sync, reason_list, new_item_list)
	assert(cnt > 0)
	try_init_user_data(user_id)
	local user_item_tbl = all_item_tbl[user_id] or {}
	local item_tbl = user_item_tbl[item_id] or {}
	if DATA_COMMON.can_overlap(item_id) then
		local _, item = next(item_tbl)
		if not item then
			item = generate_item(user_id, item_id, cnt)
		else
			item:add_cnt(cnt)
		end
		if need_sync then
			item:sync_to_client()
		end
	else
		assert(cnt < 10000000)
		for _ = 1, cnt do
			local item = generate_item(user_id, item_id)
			if need_sync then
				item:sync_to_client()
			end
			if new_item_list then
				table.insert(new_item_list, item)
			end
		end
	end
end

function add_item_cnt(user_id, item_id, cnt, reason_list)
	do_add_item_cnt(user_id, item_id, cnt, true, reason_list)
end

function add_item_cnt_no_sync(user_id, item_id, cnt, reason_list, new_item_list)
	return do_add_item_cnt(user_id, item_id, cnt, false, reason_list, new_item_list)
end

local function reward_resource_base(user_id, item_id, cnt, reason_list)
	add_item_cnt(user_id, item_id, cnt, reason_list)
end

local ITEM_KIND_REWARD_FUNC = {
	[CONST.ITEM_KIND.RES] = reward_resource_base,
	[CONST.ITEM_KIND.HERO_CHIP] = reward_resource_base,
	[CONST.ITEM_KIND.HERO_EQUIP] = reward_resource_base,
	[CONST.ITEM_KIND.RANDOM_REWARD] = reward_resource_base,
	[CONST.ITEM_KIND.SOLDIER] = reward_resource_base,
	[CONST.ITEM_KIND.VIP] = reward_resource_base,
}

function add_item(user_id, item_id, cnt, reason_list)
	local item_kind = DATA_COMMON.get_item_kind(item_id)
	local func = ITEM_KIND_REWARD_FUNC[item_kind]
	if func then
		func(user_id, item_id, cnt, reason_list)
	else
		add_item_cnt(user_id, item_id, cnt, reason_list)
	end
end