
local save_field_tbl = {
	_mail_id = function()
		return nil
	end,
	_mail_kind = function()
		return nil
	end,
	_mail_type = function()
		return nil
	end,
	_start_time = function()
		return nil
	end,
	_end_time = function()
		return nil
	end,
	_title = function()
		return nil
	end,
	_content_tbl = function()
		return nil
	end,
	_detail_list = function()
		return {}
	end,
	_reward_list = function()
		return {}
	end,
	_is_battle_mail = function()
		return false
	end,
}

cls_mail = cls_object:Inherit()

function cls_mail:__init__(oci)
	Super(cls_mail).__init__(self, oci)
	for k, func in pairs(save_field_tbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
	assert(self._mail_kind)
	assert(self._mail_type)
end

function cls_mail:release()
	MONGO_SLAVE.del_doc(MONGO_SLAVE.COL.MAIL, self._mail_id)
	Super(cls_mail).release(self)
end

function cls_mail:serialize(tbl)
	for key, _ in pairs(save_field_tbl) do
		tbl[key] = self[key]
	end
end

function cls_mail:save_field(field, val)
	assert(type(field) == "string")
	self[field] = val
	self:save_to_db()
end

function cls_mail:save_to_db()
	local info = {}
	self:serialize(info)
	MONGO_SLAVE.save_doc(MONGO_SLAVE.COL.MAIL, self._mail_id, info)
end

function cls_mail:get_detail()
	return self._detail_tbl
end

function cls_mail:get_end_time()
	return self._end_time
end

function cls_mail:get_reward_list()
	return self._reward_list
end

function cls_mail:get_mail_id()
	return self._mail_id
end

function cls_mail:get_mail_avatar_type()
	return self._mail_avatar_type or 0
end

function cls_mail:gen_content_str()
	return COMMON_FUNC.serialize(self._content_tbl)
end

function cls_mail:gen_share_content_str()
	local share_content_tbl = COMMON_FUNC.table_deepcopy(self._content_tbl)
	local mail_info = DATA_COMMON.get_mail_info(self._mail_type)
	if share_content_tbl.text and mail_info and mail_info.share_des then
		share_content_tbl.text[1] = mail_info.share_des
	end
	return COMMON_FUNC.serialize(share_content_tbl)
end

function cls_mail:get_detail_list()
	return self._detail_list
end

function cls_mail:get_mail_kind()
	return self._mail_kind
end

function cls_mail:get_mail_type()
	return self._mail_type
end

function cls_mail:get_start_time()
	return self._start_time
end

function cls_mail:is_timeout()
	if self._end_time == -1 then
		return false
	end
	return self._end_time < TIME.os_bj_sec()
end

function cls_mail:get_title()
	return self._title
end

function cls_mail:sync_detail(vfd)
	local pto_tbl = {
		mailId = self:get_mail_id(),
		rewardList = self:get_reward_list(),
		detailList = self:get_detail_list(),
	}
	for_caller.c_req_mail_detail(vfd, pto_tbl)
end

function cls_mail:can_lock()
	return DATA_COMMON.can_lock_mail(self:get_mail_type())
end
