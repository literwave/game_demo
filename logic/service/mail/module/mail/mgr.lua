
all_mail_tbl = {}
--[[
	[mailId] = mail,
--]]

del_mail_id_tbl = {}
--[[
	[mailId] = true,
--]]

user_mail_info_tbl = {}
--[[
	[userId] = {
		mailTbl = {
			[mailKind] = {
				[mailId] = {
					isRead = *,
					isGotReward = *,
					isLock = *,
					lv = *,
				},
			},
		},
		fetchSvrIdx = *,
	}
--]]

svr_mail_info = {}
--[[
	globalIdx = *,
	svrMailTbl = {
		[idx] = mailId,
	}
--]]

mail_ref_tbl = {}
--[[
	[mailId] = cnt,
--]]

local SVR_MAIL_DOC_KEY = "1"

local function dump_user_mail_info(info)
	local mail_tbl = {}
	for mail_kind, id_map in pairs(info.mail_tbl or {}) do
		mail_tbl[mail_kind] = {}
		for mail_id, st in pairs(id_map) do
			mail_tbl[mail_kind][tostring(mail_id)] = {
				isRead = st.isRead and true or false,
				isGotReward = st.isGotReward and true or false,
				isLock = st.isLock and true or false,
				lv = st.lv or 0,
			}
		end
	end
	local doc = ORM.create(ORM.CLS_USER_MAIL_DOC, {
		mail_tbl = mail_tbl,
		fetch_svr_idx = info.fetch_svr_idx or 0,
	})
	return ORM.dump(doc)
end

local function persist_user_mail(user_id)
	local info = user_mail_info_tbl[user_id]
	if not info then
		return
	end
	MONGO_SLAVE.save_doc(MONGO_SLAVE.COL.USER_MAIL, user_id, dump_user_mail_info(info))
end

local function persist_svr_mail()
	local doc = ORM.create(ORM.CLS_SVR_MAIL_DOC, {
		global_idx = svr_mail_info.global_idx or 0,
		svr_mail_tbl = svr_mail_info.svr_mail_tbl or {},
	})
	MONGO_SLAVE.save_doc(MONGO_SLAVE.COL.SVR_MAIL, SVR_MAIL_DOC_KEY, ORM.dump(doc))
end

function save_data()
	local save_mail_tbl = {}
	for mail_id, mail in pairs(all_mail_tbl) do
		local info = {}
		mail:serialize(info)
		save_mail_tbl[mail_id] = info
	end
	MONGO_SLAVE.common_save_many(MONGO_SLAVE.COL.MAIL, save_mail_tbl)
	local del_mail_tbl = {}
	for mail_id in pairs(del_mail_id_tbl) do
		if not save_mail_tbl[mail_id] then
			del_mail_tbl[mail_id] = true
		end
	end
	MONGO_SLAVE.common_del_many(MONGO_SLAVE.COL.MAIL, del_mail_tbl)
	for user_id, info in pairs(user_mail_info_tbl) do
		MONGO_SLAVE.save_doc(MONGO_SLAVE.COL.USER_MAIL, user_id, dump_user_mail_info(info))
	end
	persist_svr_mail()
end

local function create_mail(oci)
	if oci._is_battle_mail then
		return MAIL_BATTLE.cls_mail:New(oci)
	end
	return MAIL_BASE.cls_mail:New(oci)
end

function load_data()
	user_mail_info_tbl = {}
	local raw_user_tbl = MONGO_SLAVE.common_load_tbl(MONGO_SLAVE.COL.USER_MAIL) or {}
	for user_id, raw in pairs(raw_user_tbl) do
		local doc = ORM.create(ORM.CLS_USER_MAIL_DOC, raw)
		local info = {
			mail_tbl = {},
			fetch_svr_idx = doc.fetch_svr_idx,
		}
		for mail_kind, id_map in pairs(doc.mail_tbl) do
			info.mail_tbl[mail_kind] = {}
			for mail_id, st in pairs(id_map) do
				if type(st) == "table" then
					info.mail_tbl[mail_kind][mail_id] = {
						isRead = st.isRead,
						isGotReward = st.isGotReward,
						isLock = st.isLock,
						lv = st.lv,
					}
				end
			end
		end
		user_mail_info_tbl[user_id] = info
	end

	local raw_svr = MONGO_SLAVE.common_load_single(MONGO_SLAVE.COL.SVR_MAIL, SVR_MAIL_DOC_KEY) or {}
	local svr_doc = ORM.create(ORM.CLS_SVR_MAIL_DOC, raw_svr)
	svr_mail_info = {
		global_idx = svr_doc.global_idx or 0,
		svr_mail_tbl = {},
	}
	for idx, mail_id in pairs(svr_doc.svr_mail_tbl) do
		svr_mail_info.svr_mail_tbl[idx] = mail_id
	end

	for _, mail_id in pairs(svr_mail_info.svr_mail_tbl) do
		mail_ref_tbl[mail_id] = (mail_ref_tbl[mail_id] or 0) + 1
	end
	for _, user_info in pairs(user_mail_info_tbl) do
		for _, mail_tbl in pairs(user_info.mail_tbl) do
			for mail_id, _ in pairs(mail_tbl) do
				mail_ref_tbl[mail_id] = (mail_ref_tbl[mail_id] or 0) + 1
			end
		end
	end
end

local function try_init_user_mail_info(user_id)
	if not user_mail_info_tbl[user_id] then
		user_mail_info_tbl[user_id] = {
			mail_tbl = {},
			fetch_svr_idx = svr_mail_info.global_idx,
		}
		persist_user_mail(user_id)
	end
end

local function try_init_mail_tbl(mail_id_list)
	local ret = {}
	local query_list = {}
	for _, mail_id in pairs(mail_id_list) do
		local mail = all_mail_tbl[mail_id]
		if mail then
			ret[mail_id] = mail
		else
			table.insert(query_list, mail_id)
		end
	end
	if #query_list > 0 then
		local data_tbl = MONGO_SLAVE.common_load_many(MONGO_SLAVE.COL.MAIL, query_list)
		for mail_id, data in pairs(data_tbl) do
			local mail = create_mail(data)
			all_mail_tbl[mail_id] = mail
			ret[mail_id] = mail
		end
	end
	return ret
end

function try_init_mail(mail_id)
	if not all_mail_tbl[mail_id] then
		local save_tbl = MONGO_SLAVE.common_load_single(MONGO_SLAVE.COL.MAIL, mail_id)
		if not save_tbl or not next(save_tbl) then
			return
		end
		all_mail_tbl[mail_id] = create_mail(save_tbl)
	end
	return all_mail_tbl[mail_id]
end

local function get_user_mail_tbl(user_id)
	try_init_user_mail_info(user_id)
	return user_mail_info_tbl[user_id].mail_tbl
end

local function get_user_mail_by_kind(user_id, mail_kind)
	local mail_tbl = get_user_mail_tbl(user_id)
	return mail_tbl[mail_kind]
end

local function get_user_mail_info(user_id, mail_kind, mail_id)
	local mail_tbl = get_user_mail_by_kind(user_id, mail_kind)
	return mail_tbl and mail_tbl[mail_id]
end

local function set_mail_readed(user_id, mail_kind, mail_id)
	local user_mail_info = get_user_mail_info(user_id, mail_kind, mail_id)
	if not user_mail_info.isRead then
		user_mail_info.isRead = true
		persist_user_mail(user_id)
	end
end

local function set_mail_rewarded(user_id, mail_kind, mail_id)
	local user_mail_info = get_user_mail_info(user_id, mail_kind, mail_id)
	user_mail_info.isGotReward = true
	persist_user_mail(user_id)
end

local function set_mail_lock(user_id, mail_kind, mail_id, is_lock)
	local user_mail_info = get_user_mail_info(user_id, mail_kind, mail_id)
	user_mail_info.isLock = is_lock
	persist_user_mail(user_id)
end

local function del_mail(mail_id)
	assert(not del_mail_id_tbl[mail_id])
	local mail = all_mail_tbl[mail_id]
	if mail then
		del_mail_id_tbl[mail_id] = true
		mail:release()
		all_mail_tbl[mail_id] = nil
	end
end

local function incr_mail_ref_cnt(mail_id)
	mail_ref_tbl[mail_id] = (mail_ref_tbl[mail_id] or 0) + 1
end

local function desc_mail_ref_cnt(mail_id)
	mail_ref_tbl[mail_id] = mail_ref_tbl[mail_id] - 1
	if mail_ref_tbl[mail_id] <= 0 then
		del_mail(mail_id)
		mail_ref_tbl[mail_id] = nil
	end
end

local function del_user_mail(user_id, mail_kind, mail_id)
	local mail_tbl = user_mail_info_tbl[user_id].mail_tbl
	if mail_tbl[mail_kind] and mail_tbl[mail_kind][mail_id] then
		mail_tbl[mail_kind][mail_id] = nil
		persist_user_mail(user_id)
		desc_mail_ref_cnt(mail_id)
	end
end

local function add_user_mail_info(user_id, mail_kind, mail_id, user_mail_info)
	local mail_tbl = get_user_mail_tbl(user_id)
	if not mail_tbl[mail_kind] then
		mail_tbl[mail_kind] = {}
	end
	assert(not mail_tbl[mail_kind][mail_id])
	mail_tbl[mail_kind][mail_id] = user_mail_info
	persist_user_mail(user_id)
	incr_mail_ref_cnt(mail_id)
end

local function set_user_fetch_svr_idx(user_id, idx)
	user_mail_info_tbl[user_id].fetch_svr_idx = idx
	persist_user_mail(user_id)
end

local function add_svr_mail(mail_id)
	local idx = svr_mail_info.global_idx + 1
	incr_mail_ref_cnt(mail_id)
	svr_mail_info.global_idx = idx
	svr_mail_info.svr_mail_tbl[idx] = mail_id
	persist_svr_mail()
end

local function del_svr_mail(idx)
	local mail_id = svr_mail_info.svr_mail_tbl[idx]
	svr_mail_info.svr_mail_tbl[idx] = nil
	persist_svr_mail()
	desc_mail_ref_cnt(mail_id)
end

local function try_clear_svr_mail()
	for idx, mail_id in pairs(svr_mail_info.svr_mail_tbl) do
		local mail = try_init_mail(mail_id)
		if mail:is_timeout() then
			del_svr_mail(idx)
		end
	end
end

local function gen_mail_sim_pto(user_id, mail_kind, mail_id)
	local user_mail_info = get_user_mail_info(user_id, mail_kind, mail_id)
	local mail = try_init_mail(mail_id)
	local ret = {
		mailId = mail_id,
		title = mail:get_title(),
		content = mail:gen_content_str(),
		startTime = mail:get_start_time(),
		endTime = mail:get_end_time(),
		mailType = mail:get_mail_type(),
		mail_avatar_type = mail:get_mail_avatar_type(),
		isRead = user_mail_info.isRead,
		isLock = user_mail_info.isLock,
		isGotReward = user_mail_info.isGotReward,
	}
	return ret
end

local function put_mail_to_user(user_id, mail_kind, mail_id)
	local user_mail_info = {
		isRead = false,
		isGotReward = true,
		isLock = false,
	}
	local mail = try_init_mail(mail_id)
	if COMMON_FUNC.has_element(mail:get_reward_list()) then
		user_mail_info.isGotReward = false
	end
	add_user_mail_info(user_id, mail_kind, mail_id, user_mail_info)
end

local function put_mail_to_user_and_sync(user_id, mail_kind, mail_id)
	put_mail_to_user(user_id, mail_kind, mail_id)
	local vfd = USER_MGR.get_vfd_by_user_id(user_id)
	if vfd then
		local info = gen_mail_sim_pto(user_id, mail_kind, mail_id)
		for_caller.c_sync_new_mail(vfd, mail_kind, info)
	end
end

local function try_get_svr_mail(user_id)
	try_init_user_mail_info(user_id)
	local last_fetch_idx = user_mail_info_tbl[user_id].fetch_svr_idx
	local all_svr_mail_tbl = svr_mail_info.svr_mail_tbl
	for idx = last_fetch_idx+1, svr_mail_info.global_idx do
		set_user_fetch_svr_idx(user_id, idx)
		local mail_id = all_svr_mail_tbl[idx]
		local mail = mail_id and try_init_mail(mail_id)
		if mail and not mail:is_timeout() then
			put_mail_to_user_and_sync(user_id, mail:get_mail_kind(), mail_id)
		end
	end
end

local function create_new_mail(mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec, mail_avatar_type)
	assert(life_sec)
	local mail_id = get_id_by_srv_id_and_timestamp()
	local start_time = TIME.os_bj_sec()
	local end_time = -1
	if life_sec > 0 then
		end_time = start_time + life_sec
	end
	local oci = {
		_mail_id = mail_id,
		_mail_kind = mail_kind,
		_mail_type = mail_type,
		_title = title,
		_content_tbl = content_tbl,
		_detail_tbl = detail_tbl,
		_reward_list = reward_list,
		_start_time = start_time,
		_end_time = end_time,
	}
	local mail = create_mail(oci)
	mail:save_to_db()
	all_mail_tbl[mail_id] = mail
	return mail_id
end

local function create_new_battle_mail(mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, mail_battle_rec, life_sec, mail_avatar_type)
	assert(life_sec)
	local mail_id = get_id_by_srv_id_and_timestamp()
	local start_time = TIME.os_bj_sec()
	local end_time = -1
	if life_sec > 0 then
		end_time = start_time + life_sec
	end
	local oci = {
		_mail_id = mail_id,
		_mail_kind = mail_kind,
		_mail_type = mail_type,
		_title = title,
		_content_tbl = content_tbl,
		_detail_tbl = detail_tbl,
		_reward_list = reward_list,
		_start_time = start_time,
		_end_time = end_time,
		_mail_avatar_type = mail_avatar_type,
		_result = mail_battle_rec.result,
		_camp_rec_tbl = mail_battle_rec.camp_rec_tbl,
		_user_rec_tbl = mail_battle_rec.user_rec_tbl,
		_soldier_rec_list = mail_battle_rec.soldier_rec_list,
		_hero_info_list = mail_battle_rec.heroInfoList,
		_battle_attr_rate_list = mail_battle_rec.battle_attr_rate_list,
		_is_battle_mail = true,
	}
	local mail = create_mail(oci)
	mail:save_to_db()
	all_mail_tbl[mail_id] = mail
	loaded_tbl[mail_id] = true
	return mail_id
end

function slice_get_svr_mail(ulist, pro, param_tbl)
	local user_id = ulist[pro]
	try_get_svr_mail(user_id)
end

function on_user_login(user)
	local user_id = user:get_user_id()
	try_init_user_mail_info(user_id)
	try_get_svr_mail(user_id)
end

local function check_mail_reward_over_limit(user_id, mail_kind, mail_id)
	local user_mail_info = get_user_mail_info(user_id, mail_kind, mail_id)
	if not user_mail_info then
		return false
	end
	local mail = try_init_mail(mail_id)
	if not mail then
		return false
	end
	local reward_item_tbl = {}
	for _, reward_info in pairs(mail:get_reward_list()) do
		if reward_info.reward_type == CONST.REWARD_TYPE_ITEM then
			local item_type = reward_info.item_type
			reward_item_tbl[item_type] = (reward_item_tbl[item_type] or 0) + reward_info.item_count
		end
	end
	for item_type, reward_item_cnt in pairs(reward_item_tbl) do
		local limit_add_cnt = ITEM_MGR.get_limit_add_cnt(user_id, item_type)
		if limit_add_cnt and reward_item_cnt > limit_add_cnt then
			return true
		end
	end
	return false
end

local function try_get_mail_reward(user_id, mail_kind, mail_id)
	local user_mail_info = get_user_mail_info(user_id, mail_kind, mail_id)
	if not user_mail_info then
		return false
	end
	if not user_mail_info.isRead then
		set_mail_readed(user_id, mail_kind, mail_id)
	end
	if user_mail_info.isGotReward then
		return false
	end
	local mail = try_init_mail(mail_id)
	if not mail then
		return false
	end
	set_mail_rewarded(user_id, mail_kind, mail_id)
	local actual_rwd_list = REWARD_MGR.reward_user(user_id, mail:get_reward_list(), {CONST.FLOW_REASON.MAIL, mail:get_mail_type()})
	return true, actual_rwd_list
end

local function try_del_user_mail_by_kind(user_id, mail_kind)
	local mail_tbl = get_user_mail_by_kind(user_id, mail_kind)
	if not mail_tbl then
		return
	end
	local del_mail_tbl = {}
	local mail_list = {}
	local query_mail_id_list = {}
	for mail_id, info in pairs(mail_tbl) do
		if not info.isLock then
			table.insert(query_mail_id_list, mail_id)
		end
	end
	local query_mail_tbl = try_init_mail_tbl(query_mail_id_list)
	for mail_id, mail in pairs(query_mail_tbl) do
		if mail:is_timeout(mail_id) then
			del_mail_tbl[mail_id] = true
		else
			table.insert(mail_list, mail)
		end
	end
	local limit_cnt = DATA_COMMON.get_value_by_key(3)
	local need_del_cnt = #mail_list - limit_cnt
	if need_del_cnt <= 0 then
		return
	end
	table.sort(mail_list, function(mail1, mail2)
		return mail1:get_start_time() < mail2:get_start_time()
	end)
	for _, mail in ipairs(mail_list) do
		local mail_id = mail:get_mail_id()
		del_mail_tbl[mail_id] = true
		need_del_cnt = need_del_cnt - 1
		if need_del_cnt <= 0 then
			break
		end
	end
	local del_list = {}
	for mail_id in pairs(del_mail_tbl) do
		try_get_mail_reward(user_id, mail_kind, mail_id)
		del_user_mail(user_id, mail_kind, mail_id)
		table.insert(del_list, mail_id)
	end
	local vfd = USER_MGR.get_vfd_by_user_id(user_id)
	if vfd then
		for_caller.s2c_del_mail_list(vfd, mail_kind, del_list)
	end
end

function try_del_mail_by_id(del_mail_id)
	if not mail_ref_tbl[del_mail_id] then
		return
	end
	for idx, mail_id in pairs(svr_mail_info.svr_mail_tbl) do
		if mail_id == del_mail_id then
			del_svr_mail(idx)
			if not mail_ref_tbl[del_mail_id] then
				return
			end
		end
	end
	for user_id, user_info in pairs(user_mail_info_tbl) do
		for mail_kind, mail_tbl in pairs(user_info.mail_tbl) do
			if mail_tbl[del_mail_id] then
				del_user_mail(user_id, mail_kind, del_mail_id)
				local vfd = USER_MGR.get_vfd_by_user_id(user_id)
				if vfd then
					for_caller.c_del_mail_list(vfd, mail_kind, {del_mail_id})
				end
				if not mail_ref_tbl[del_mail_id] then
					return
				end
			end
		end
	end
end

function send_user_mail(user_id, mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec, mail_avatar_type)
	local mail_id = create_new_mail(mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec, mail_avatar_type)
	put_mail_to_user_and_sync(user_id, mail_kind, mail_id)
	try_del_user_mail_by_kind(user_id, mail_kind)
	return mail_id
end

function send_srv_mail(mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec, mail_avatar_type)
	local mail_id = create_new_mail(mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec, mail_avatar_type)
	add_svr_mail(mail_id)
	local user_id_list = COMMON_FUNC.get_tbl_value_list(USER_MGR.get_vfd_user_id_tbl())
	SLICE_TASK.slice_func_no_save("MAIL_MGR", "slice_get_svr_mail", user_id_list, 30)
	try_clear_svr_mail()
	return mail_id
end

function send_group_mail(user_id_tbl, mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec, mail_avatar_type)
	local mail_id = create_new_mail(mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec, mail_avatar_type)
	for user_id, _ in pairs(user_id_tbl) do
		put_mail_to_user_and_sync(user_id, mail_kind, mail_id)
		try_del_user_mail_by_kind(user_id, mail_kind)
	end
	return mail_id
end

function send_battle_mail(user_id_tbl, mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, mail_battle_rec, life_sec, mail_avatar_type)
	local mail_id = create_new_battle_mail(mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, mail_battle_rec, life_sec, mail_avatar_type)
	for user_id, _ in pairs(user_id_tbl) do
		put_mail_to_user_and_sync(user_id, mail_kind, mail_id)
		try_del_user_mail_by_kind(user_id, mail_kind)
	end
end

local function on_req_mail_list(vfd, mail_kind)
	local user_id = USER_MGR.get_user_id_by_vfd(vfd)
	try_del_user_mail_by_kind(user_id, mail_kind)
	local list = {}
	local tbl = get_user_mail_by_kind(user_id, mail_kind)
	if tbl then
		for mail_id, _ in pairs(tbl) do
			table.insert(list, gen_mail_sim_pto(user_id, mail_kind, mail_id))
		end
	end
	for_caller.c_req_mail_list(vfd, mail_kind, list)
end

local function on_req_mail_detail(vfd, mail_kind, mail_id)
	local user_id = USER_MGR.get_user_id_by_vfd(vfd)
	local tbl = get_user_mail_by_kind(user_id, mail_kind)
	if tbl and tbl[mail_id] then
		set_mail_readed(user_id, mail_kind, mail_id)
		local mail = try_init_mail(mail_id)
		mail:sync_detail(vfd, user_id)
	end
end

local function on_req_unread_cnt_list(vfd)
	local user_id = USER_MGR.get_user_id_by_vfd(vfd)
	local mail_tbl = get_user_mail_tbl(user_id)
	local list = {}
	for mail_kind, tbl in pairs(mail_tbl) do
		local unread_cnt = 0
		for _, info in pairs(tbl) do
			if not info.isRead then
				unread_cnt = unread_cnt + 1
			end
		end
		table.insert(list, { k = mail_kind, v = unread_cnt, })
	end
	for_caller.c_req_unread_mail_cnt_list(vfd, list)
end

local function try_del_mail(user_id, mail_kind, mail_id, info)
	if info.isLock then
		return false
	end
	if not info.isGotReward then
		return false
	end
	try_init_mail(mail_id)
	del_user_mail(user_id, mail_kind, mail_id)
	return true
end

local function on_del_mail_list(vfd, mail_kind, mail_id_list)
	local user_id = USER_MGR.get_user_id_by_vfd(vfd)
	local tbl = get_user_mail_by_kind(user_id, mail_kind)
	if not tbl then
		return
	end
	local del_mail_id_list = {}
	for _, mail_id in pairs(mail_id_list) do
		local info = tbl[mail_id]
		if info then
			if try_del_mail(user_id, mail_kind, mail_id, info) then
				table.insert(del_mail_id_list, mail_id)
			end
		end
	end
	for_caller.s2c_del_mail_list(vfd, mail_kind, del_mail_id_list)
end

local function on_set_mail_lock(vfd, mail_kind, mail_id, is_lock)
	local user_id = USER_MGR.get_user_id_by_vfd(vfd)
	local tbl = get_user_mail_by_kind(user_id, mail_kind)
	local info = tbl and tbl[mail_id]
	if info and info.isLock ~= is_lock then
		if is_lock then
			local mail = try_init_mail(mail_id)
			if not mail:can_lock() then
				return
			end
		end
		set_mail_lock(user_id, mail_kind, mail_id, is_lock)
		for_caller.c_set_mail_lock(vfd, mail_kind, mail_id, is_lock)
	end
end

local function on_get_mail_reward(vfd, mail_kind_id_list)
	local user_id = USER_MGR.get_user_id_by_vfd(vfd)
	local all_reward_list = {}
	local reward_mail_id_list = {}
	for _, info in pairs(mail_kind_id_list) do
		local mail_kind = info.k
		local mail_id = info.v
		if check_mail_reward_over_limit(user_id, mail_kind, mail_id) then
			USER_MGR.tell_me_by_language_id(user_id, 110277)
		else
			local ret, reward_list = try_get_mail_reward(user_id, mail_kind, mail_id)
			if ret then
				table.insert(all_reward_list, reward_list)
				table.insert(reward_mail_id_list, mail_id)
			end
		end
	end
	local show_reward_list = FUNCLIB.merge_reward_list(table.unpack(all_reward_list))
	REWARD_MGR.show_reward(user_id, show_reward_list)
	for_caller.c_get_mail_reward(vfd, reward_mail_id_list)
end

function __init__()
	for_maker.c2s_req_mail_list = on_req_mail_list
	for_maker.c2s_req_mail_detail = on_req_mail_detail
	for_maker.c2s_req_unread_mail_cnt_list = on_req_unread_cnt_list
	for_maker.c2s_del_mail_list = on_del_mail_list
	for_maker.c2s_set_mail_lock = on_set_mail_lock
	for_maker.c2s_get_mail_reward = on_get_mail_reward
end