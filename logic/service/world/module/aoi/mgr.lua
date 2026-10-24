local skynet = require "skynet"

local entities = {}
local focus_tbl = {}
local march_token = {}
local agent_list
local RADIUS2 = CONST.AOI_RADIUS * CONST.AOI_RADIUS

local function agent_of(user_id)
	if not agent_list then
		agent_list = skynet.call(".gated", "lua", "get_agent_list")
	end
	local n = #agent_list
	if n < 1 then
		return
	end
	return agent_list[user_id % n + 1]
end

local function entity_pto(e)
	local pto = {
		entityId = e.id,
		entityType = e.entity_type,
		pos = {x = math.floor(e.x), y = math.floor(e.y)},
		ownerId = e.owner_id or 0,
		cfgId = e.cfg_id or 0,
	}
	if e.moving then
		pto.path = MARCH_PATH.to_pto(e.path)
		pto.startTime = e.start_time
		pto.endTime = e.end_time
	end
	return pto
end

local function in_view(f, e)
	local dx = e.x - f.x
	local dy = e.y - f.y
	return dx * dx + dy * dy <= RADIUS2
end

local function push(user_id, enter, leave, update)
	if #enter == 0 and #leave == 0 and #update == 0 then
		return
	end
	local agent = agent_of(user_id)
	if not agent then
		return
	end
	skynet.send(agent, "lua", "aoi_push", user_id, {
		enter = enter,
		leave = leave,
		update = update,
	})
end

local function refresh_entity(e)
	for user_id, f in pairs(focus_tbl) do
		local seen = f.seen[e.id]
		local inside = in_view(f, e)
		if inside and not seen then
			f.seen[e.id] = true
			push(user_id, {entity_pto(e)}, {}, {})
		elseif inside and seen then
			push(user_id, {}, {}, {entity_pto(e)})
		elseif seen and not inside then
			f.seen[e.id] = nil
			push(user_id, {}, {e.id}, {})
		end
	end
end

local function leave_all(e)
	for user_id, f in pairs(focus_tbl) do
		if f.seen[e.id] then
			f.seen[e.id] = nil
			push(user_id, {}, {e.id}, {})
		end
	end
end

local function place_group(group_id)
	local conf = DATA_COMMON.get_monster_group(group_id)
	if not conf then
		return
	end
	local eid = CONST.monster_entity_id(group_id)
	if entities[eid] then
		return
	end
	local idx = MAP_MGR.get_map():alloc_birth_idx()
	if not idx then
		skynet.timeout(6000, function()
			place_group(group_id)
		end)
		return
	end
	local pos = MAP_MGR.pos_of_idx(idx)
	local e = {
		id = eid,
		entity_type = DATA_COMMON.ENTITY_TYPE.MONSTER_GROUP,
		x = pos.x,
		y = pos.y,
		owner_id = 0,
		cfg_id = group_id,
		birth_idx = idx,
	}
	entities[eid] = e
	refresh_entity(e)
end

function upsert_city(user_id, x, y)
	local id = CONST.city_entity_id(user_id)
	local e = entities[id]
	if not e then
		e = {
			id = id,
			entity_type = DATA_COMMON.ENTITY_TYPE.CITY,
			owner_id = user_id,
			cfg_id = 0,
			user_id = user_id,
		}
		entities[id] = e
	end
	e.x = x
	e.y = y
	refresh_entity(e)
end

function start_march(info)
	local id = CONST.troop_entity_id(info.user_id, info.troop_idx)
	local x, y = MARCH_PATH.pos_at(info.path, info.start_time, info.end_time, TIME.os_bj_sec())
	local e = {
		id = id,
		entity_type = DATA_COMMON.ENTITY_TYPE.TROOP,
		owner_id = info.user_id,
		cfg_id = 0,
		user_id = info.user_id,
		troop_idx = info.troop_idx,
		moving = true,
		path = info.path,
		start_time = info.start_time,
		end_time = info.end_time,
		x = x,
		y = y,
	}
	entities[id] = e
	local token = {}
	local key = info.user_id .. ":" .. info.troop_idx
	march_token[key] = token
	local delay = math.max(1, (info.end_time - TIME.os_bj_sec()) * 100)
	skynet.timeout(delay, function()
		if march_token[key] ~= token then
			return
		end
		march_token[key] = nil
		local cur = entities[id]
		if cur then
			cur.moving = false
			cur.x, cur.y = MARCH_PATH.last_pos(cur.path)
			refresh_entity(cur)
		end
		local agent = agent_of(info.user_id)
		if agent then
			skynet.send(agent, "lua", "march_arrive", info.user_id, info.troop_idx, info.end_time)
		end
	end)
	refresh_entity(e)
	return true
end

function remove_troop(user_id, troop_idx)
	march_token[user_id .. ":" .. troop_idx] = nil
	local id = CONST.troop_entity_id(user_id, troop_idx)
	local e = entities[id]
	if not e then
		return
	end
	entities[id] = nil
	leave_all(e)
end

function monster_pos(entity_id)
	local e = entities[entity_id]
	if not e or e.entity_type ~= DATA_COMMON.ENTITY_TYPE.MONSTER_GROUP then
		return
	end
	return {x = e.x, y = e.y, cfg_id = e.cfg_id}
end

function kill_monster(entity_id)
	local e = entities[entity_id]
	if not e or e.entity_type ~= DATA_COMMON.ENTITY_TYPE.MONSTER_GROUP then
		return
	end
	local cfg_id = e.cfg_id
	entities[entity_id] = nil
	if e.birth_idx then
		MAP_MGR.get_map():release_birth_idx(e.birth_idx)
	end
	leave_all(e)
	local conf = DATA_COMMON.get_monster_group(cfg_id)
	local wait = 60
	if conf and conf.Refresh and conf.Refresh > 0 then
		wait = conf.Refresh
	end
	skynet.timeout(wait * 100, function()
		place_group(cfg_id)
	end)
	return cfg_id
end

function focus(user_id, x, y)
	local f = focus_tbl[user_id]
	if not f then
		f = {seen = {}}
		focus_tbl[user_id] = f
	end
	f.x = x
	f.y = y
	local now_seen = {}
	local enter = {}
	local leave = {}
	for id, e in pairs(entities) do
		if in_view(f, e) then
			now_seen[id] = true
			if not f.seen[id] then
				enter[#enter + 1] = entity_pto(e)
			end
		end
	end
	for id in pairs(f.seen) do
		if not now_seen[id] then
			leave[#leave + 1] = id
		end
	end
	f.seen = now_seen
	return {enter = enter, leave = leave}
end

function clear_focus(user_id)
	focus_tbl[user_id] = nil
end

local function tick()
	local now = TIME.os_bj_sec()
	for _, e in pairs(entities) do
		if e.moving then
			local x, y = MARCH_PATH.pos_at(e.path, e.start_time, e.end_time, now)
			if x ~= e.x or y ~= e.y then
				e.x = x
				e.y = y
				refresh_entity(e)
			end
		end
	end
	skynet.timeout(100, tick)
end

local function restore_marches()
	local troops = MONGO_SLAVE.common_load_tbl(MONGO_SLAVE.COL.USER_TROOP)
	local now = TIME.os_bj_sec()
	for _, doc in pairs(troops) do
		for _, troop in pairs(doc._troops or {}) do
			if troop._march_state == CONST.MARCH_STATE.MOVING and troop._user_id and troop._troop_idx then
				if troop._end_time and now >= troop._end_time then
					local agent = agent_of(troop._user_id)
					if agent then
						skynet.send(agent, "lua", "march_arrive", troop._user_id, troop._troop_idx, troop._end_time)
					end
				else
					start_march({
						user_id = troop._user_id,
						troop_idx = troop._troop_idx,
						target_type = troop._target_type,
						target_id = troop._target_id,
						path = troop._path or {},
						start_time = troop._start_time,
						end_time = troop._end_time,
					})
				end
			end
		end
	end
end

function init()
	for group_id in pairs(DATA_COMMON.get_monster_group_tbl()) do
		place_group(group_id)
	end
	local users = MONGO_SLAVE.common_load_tbl(MONGO_SLAVE.COL.USER_INFO)
	for _, dat in pairs(users) do
		if dat._has_birth and dat._user_id then
			upsert_city(dat._user_id, dat._birth_x, dat._birth_y)
		end
	end
	restore_marches()
	skynet.timeout(100, tick)
end
