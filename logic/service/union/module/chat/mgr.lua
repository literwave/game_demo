-- 聊天：世界、联盟、私聊。历史只存内存，每个频道（私聊按会话）保留 Global.Id=9 条，重启清空

world_hist = {}
-- [alliance_id] = {msg, ...}
alliance_hist = {}
-- ["小uid:大uid"] = {msg, ...}
private_hist = {}
-- [user_id] = 上次发言时间
last_chat_time = {}
-- [user_id] = true，确认过存在的私聊对象
known_user = {}
msg_seq = 0

local function private_key(a, b)
	if a > b then
		a, b = b, a
	end
	return a .. ":" .. b
end

local function push(list, msg)
	list[#list + 1] = msg
	local over = #list - DATA_COMMON.get_chat_history_max()
	if over > 0 then
		table.move(list, over + 1, #list, 1)
		for i = #list - over + 1, #list do
			list[i] = nil
		end
	end
end

local function user_exists(user_id)
	if known_user[user_id] or USER_MGR.get_brief(user_id) then
		return true
	end
	if MONGO_SLAVE.common_load_single(MONGO_SLAVE.COL.USER_INFO, user_id) then
		known_user[user_id] = true
		return true
	end
	return false
end

local function history_of(user_id, channel, target_id, create)
	if channel == DATA_COMMON.CHAT_CHANNEL.WORLD then
		return world_hist
	end
	if channel == DATA_COMMON.CHAT_CHANNEL.ALLIANCE then
		local alliance_id = ALLIANCE_MGR.user_alliance[user_id]
		if not alliance_id then
			return
		end
		if create and not alliance_hist[alliance_id] then
			alliance_hist[alliance_id] = {}
		end
		return alliance_hist[alliance_id] or EMPTY_TABLE
	end
	if channel == DATA_COMMON.CHAT_CHANNEL.PRIVATE then
		if target_id <= 0 or target_id == user_id then
			return
		end
		local key = private_key(user_id, target_id)
		if create and not private_hist[key] then
			private_hist[key] = {}
		end
		return private_hist[key] or EMPTY_TABLE
	end
end

local function deliver(user_id, msg)
	if msg.channel == DATA_COMMON.CHAT_CHANNEL.WORLD then
		for uid in pairs(USER_MGR.user_id_to_fd) do
			if uid ~= user_id then
				USER_MGR.send(uid, "s2c_sync_chat", {msg = msg})
			end
		end
	elseif msg.channel == DATA_COMMON.CHAT_CHANNEL.ALLIANCE then
		local doc = ALLIANCE_MGR.get_user_alliance(user_id)
		for uid in pairs(doc._members) do
			if uid ~= user_id then
				USER_MGR.send(uid, "s2c_sync_chat", {msg = msg})
			end
		end
	elseif msg.channel == DATA_COMMON.CHAT_CHANNEL.PRIVATE then
		USER_MGR.send(msg.targetId, "s2c_sync_chat", {msg = msg})
	end
end

local function on_chat(user_id, packet)
	local channel = packet.channel or 0
	local content = packet.content or ""
	local target_id = packet.targetId or 0
	if not DATA_COMMON.get_chat_channel_conf(channel) then
		return
	end
	local len = utf8.len(content)
	if not len or len < 1 or len > CONST.CHAT_CONTENT_MAX_LEN then
		USER_MGR.tell_me(user_id, "聊天内容长度不合法")
		return
	end
	local now = TIME.os_bj_sec()
	if now < (last_chat_time[user_id] or 0) + CONST.CHAT_INTERVAL then
		USER_MGR.tell_me(user_id, "发言太快了")
		return
	end
	if channel ~= DATA_COMMON.CHAT_CHANNEL.PRIVATE then
		target_id = 0
	elseif not user_exists(target_id) then
		USER_MGR.tell_me(user_id, "玩家不存在")
		return
	end
	local hist = history_of(user_id, channel, target_id, true)
	if not hist then
		if channel == DATA_COMMON.CHAT_CHANNEL.ALLIANCE then
			USER_MGR.tell_me(user_id, "还没有加入联盟")
		end
		return
	end
	last_chat_time[user_id] = now
	msg_seq = msg_seq + 1
	local brief = USER_MGR.get_brief(user_id)
	local msg = {
		msgId = msg_seq,
		channel = channel,
		senderId = user_id,
		senderName = brief.name,
		headIcon = brief.head_icon,
		content = content,
		time = now,
		targetId = target_id,
	}
	push(hist, msg)
	USER_MGR.send(user_id, "s2c_chat", {msg = msg})
	deliver(user_id, msg)
end

local function on_req_chat_list(user_id, packet)
	local channel = packet.channel or 0
	local target_id = packet.targetId or 0
	if channel ~= DATA_COMMON.CHAT_CHANNEL.PRIVATE then
		target_id = 0
	end
	local hist = history_of(user_id, channel, target_id, false)
	USER_MGR.send(user_id, "s2c_req_chat_list", {
		channel = channel,
		targetId = target_id,
		msgList = hist or {},
	})
end

function on_alliance_dissolve(alliance_id)
	alliance_hist[alliance_id] = nil
end

function __init__()
	for_maker.c2s_chat = on_chat
	for_maker.c2s_req_chat_list = on_req_chat_list
end
