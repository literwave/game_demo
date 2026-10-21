all_user_build_tbl = {
--[[
	[userId] = {
		[bid] = build,
	}
]]
}

function ref_build(build)
	local user_id = build:get_user_id()
	local bid = build:get_bid()
	if not all_user_build_tbl[user_id] then
		all_user_build_tbl[user_id] = {}
	end
	all_user_build_tbl[user_id][bid] = build
end

function unref_build(build)
	local user_id = build:get_user_id()
	local bid = build:get_bid()
	if all_user_build_tbl[user_id] then
		all_user_build_tbl[user_id][bid] = nil
		if table.is_empty(all_user_build_tbl[user_id]) then
			all_user_build_tbl[user_id] = nil
		end
	end
end

local function create_build(oci)
	return BUILD_BASE.cls_build:New(oci)
end

local function try_init_user_builds(user_id)
	if not ORM.get(MONGO_SLAVE.COL.USER_BUILD, user_id) then
		local raw = MONGO_SLAVE.common_load_single(MONGO_SLAVE.COL.USER_BUILD, user_id) or {}
		local doc = ORM.create(ORM.CLS_USER_BUILD_DOC, raw)
		ORM.hold(doc, MONGO_SLAVE.COL.USER_BUILD, user_id)
		all_user_build_tbl[user_id] = {}
		for _, build_data in pairs(doc._builds) do
			if ORM.is_cls(build_data, ORM.CLS_BUILD_DATA) then
				create_build(build_data)
			end
		end
	end
	return all_user_build_tbl[user_id]
end

function get_build_by_bid(user_id, bid)
	local build_tbl = try_init_user_builds(user_id)
	return build_tbl[bid]
end

function get_user_build_tbl(user_id)
	return try_init_user_builds(user_id)
end

local function init_user_builds(user_id)
	try_init_user_builds(user_id)
	if next(all_user_build_tbl[user_id]) then
		return
	end
	for _, init_lev in ipairs(DATA_COMMON.get_initial_build_list()) do
		if type(init_lev) == "table" then
			for bid, level in pairs(init_lev) do
				create_build({
					_user_id = user_id,
					_bid = bid,
					_level = level,
				})
			end
		end
	end
end

function on_user_login(user, is_first_login)
	local user_id = user:get_user_id()
	-- 无建筑时补初始建筑（含首次创角中途失败、未 persist 的号）
	init_user_builds(user_id)
	sync_all_build_to_client(user_id)
end

function on_user_logout(user_id)
	if ORM.get(MONGO_SLAVE.COL.USER_BUILD, user_id) then
		MONGO_SLAVE.flush()
		all_user_build_tbl[user_id] = nil
		ORM.forget(MONGO_SLAVE.COL.USER_BUILD, user_id)
	end
end

function sync_all_build_to_client(user_id)
	local fd = USER_MGR.get_fd_by_user_id(user_id)
	if not fd then
		return
	end
	local build_tbl = try_init_user_builds(user_id)
	for _, build in pairs(build_tbl) do
		build:sync_to_client()
	end
	for_caller.s2c_req_all_build_end(fd, {})
end

local function on_create_build(fd, packet)
	local user_id = USER_MGR.get_user_id_by_fd(fd)
	local bid = packet.bid
	if get_build_by_bid(user_id, bid) then
		return
	end
	if not DATA_COMMON.get_build_type_by_id(bid) then
		return
	end
	if not packet.isInstant then
		local ok = QUEUE_MGR.try_add_new_work(user_id, bid)
		if not ok then
			return
		end
	end
	local build = create_build({
		_user_id = user_id,
		_bid = bid,
		_level = 1,
	})
	build:sync_to_client()
end

local function on_up_build(fd, packet)
	local user_id = USER_MGR.get_user_id_by_fd(fd)
	local build = get_build_by_bid(user_id, packet.bid)
	if not build then
		return
	end
	local max_lv = DATA_COMMON.get_build_max_level(build:get_build_type())
	if build:get_level() >= max_lv then
		return
	end
	if not packet.isInstant then
		local ok = QUEUE_MGR.try_add_new_work(user_id, packet.bid)
		if not ok then
			return
		end
	end
	build:set_level(build:get_level() + 1)
	build:sync_to_client()
end

function __init__()
	for_maker.c2s_create_build = on_create_build
	for_maker.c2s_up_build = on_up_build
end
