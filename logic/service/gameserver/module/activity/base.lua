local save_field_tbl = {
	_id = function ()
		return nil
	end,
	_start_time = function ()
		return nil
	end,
	_end_time = function ()
		return nil
	end,
}

cls_act = cls_object:Inherit()

function cls_act:__init__(oci)
	Super(cls_act).__init__(self, oci)
	for k, func in pairs(save_field_tbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
end

function cls_act:save_field(field, val)
	assert(type(field) == "string", "saveField only accepts string field name")
	self[field] = val
	MONGO_SLAVE.save_doc_field(MONGO_SLAVE.COL.USER_INFO, self._user_id, field, val)
end

function cls_act:get_user_id()
	return self._user_id
end
function cls_act:is_online()
	return self:get_vfd() ~= nil
end

function cls_act:get_birth_time()
	return self._birth_time
end

function cls_act:get_name()
	return self._name
end

function cls_act:set_name(name)
	self._name = name
	self:save_field("_name", name)
end

function cls_act:get_sex()
	return self._sex
end

function cls_act:set_sex(sex)
	self._sex = sex
	self:save_field("_sex", sex)
end

function cls_act:get_res_num(res_type)
	return self._res_tbl[res_type] or 0
end

function cls_act:add_res(res_type, num)
	local res_num = self:get_res_num(res_type)
	self._res_tbl[res_type] = num + res_num
end

function cls_act:serialize(tbl)
	for key, _ in pairs(save_field_tbl) do
		tbl[key] = self[key]
	end
end

function cls_act:save_to_db()
	local info = {}
	self:serialize(info)
	MONGO_SLAVE.save_doc(MONGO_SLAVE.COL.USER_INFO, self._user_id, info)
end

function cls_act:set_sdk_param_tbl(param_tbl)
	self._sdk_param_tbl = param_tbl
	self:save_field("_sdk_param_tbl", self._sdk_param_tbl)
end

function cls_act:update_by_login_param_tbl(param_tbl)
	self:set_device_id(param_tbl.loginInfo.deviceId)
	self:set_client_platform(param_tbl.loginInfo.platform)
	if param_tbl.sdk_param_tbl then
		self:set_sdk_param_tbl(param_tbl.sdk_param_tbl)
	end
end

function cls_act:get_account()
	return self._account
end

function cls_act:set_account(account)
	self._account = account
end

function cls_act:get_login_addr()
	return self._login_addr
end

function cls_act:set_login_addr(addr)
	self._login_addr = addr
end

function cls_act:get_gate_srv()
	return self._gate_srv
end

function cls_act:set_gate_srv(gate_srv)
	self._gate_srv = gate_srv
end

function cls_act:get_fd()
	return self._fd
end

function cls_act:set_fd(fd)
	self._fd = fd
end

function cls_act:get_heart_beat_time()
	return self._heart_beat_time
end

function cls_act:set_and_sync_heart_beat_time(time)
	local fd = self:get_fd()
	local pto_tbl = {
		heartBeatTime = time
	}
	for_caller.s2c_heart_beat(fd, pto_tbl)
end

function cls_act:on_login()
	self:set_login_time(TIME.os_bj_sec())
end

function cls_act:set_login_time(time)
	self:save_field("_login_time", time)
end

function cls_act:set_born_server_id(server_id)
	self:save_field("_born_server_id", server_id)
end

function cls_act:get_diamond()
	return self._real_diamond + self._gift_diamond
end

function cls_act:get_real_diamond()
	return self._real_diamond
end

function cls_act:get_gift_diamond()
	return self._gift_diamond
end

function cls_act:add_sum_recharge_diamond(add_cnt)
	self._sum_recharge_diamond = self._sum_recharge_diamond + add_cnt
	self:save_field("_sum_recharge_diamond", self._sum_recharge_diamond)
end

function cls_act:get_sum_recharge_diamond()
	return self._sum_recharge_diamond
end

function cls_act:add_real_diamond(add_cnt, reason_list)
	assert(add_cnt >= 0)
	assert(reason_list[1] == CONST.FLOW_REASON.RECHARGE or reason_list[1] == CONST.FLOW_REASON.WIZ)
	self._real_diamond = self._real_diamond + add_cnt
	self:save_field("_real_diamond", self._real_diamond)
end

function cls_act:add_gift_diamond(add_cnt, reason_list)
	assert(add_cnt >= 0)
	self._gift_diamond = self._gift_diamond + add_cnt
	self:save_field("_gift_diamond", self._gift_diamond)
end

function cls_act:add_real_diamond_and_sync(add_cnt, reason_list)
	self:add_real_diamond(add_cnt, reason_list)
	self:sync_diamond()
end

function cls_act:add_gift_diamond_and_sync(add_cnt, reason_list)
	self:add_gift_diamond(add_cnt, reason_list)
	self:sync_diamond()
end

function cls_act:sync_diamond()
	local pto_tbl = {
		diamond = self:get_diamond()
	}
	local fd = self:get_fd()
	if fd then
		for_caller.s2c_sync_user_diamond(fd, pto_tbl)	
	end
end

function cls_act:add_diamond(add_cnt, reason_list)
	assert(add_cnt >= 0)
	self._real_diamond = self._real_diamond + add_cnt
	self:save_field("_real_diamond", self._real_diamond)
end

function cls_act:sub_diamond(sum_sub_cnt, reason_list)
	assert(sum_sub_cnt > 0)
	assert(self:get_diamond() >= sum_sub_cnt)
	local sub_real, sub_gift = 0, 0
	if self._real_diamond >= sum_sub_cnt then
		sub_real = sum_sub_cnt
		self._real_diamond = self._real_diamond - sum_sub_cnt
	else
		sub_real = self._real_diamond
		self._real_diamond = 0
		sub_gift = sum_sub_cnt - sub_real
		self._gift_diamond = self._gift_diamond - sub_gift
	end
	if sub_real > 0 then
		self:save_field("_real_diamond", self._real_diamond)
	end
	if sub_gift > 0 then
		self:save_field("_gift_diamond", self._gift_diamond)
	end
	-- afterSubDiamond(self, subReal, subGift, extTbl, reasonList)
end

function cls_act:set_and_sync_verify_login(token)
	self._token = token
	local fd = self:get_fd()
	local pto_tbl = {
		token = token
	}
	for_caller.s2c_verify_login(fd, pto_tbl)	
end

function cls_act:get_head_icon()
	return self._head_icon
end

function cls_act:set_head_icon(head_icon)
	self._head_icon = head_icon
	self:save_field("_head_icon", head_icon)
end

function cls_act:get_client_pto_info()
	return {
		name = self:get_name(),
		headIcon = self:get_head_icon(),
		sex = self:get_sex(),
		birthTime = self:get_birth_time(),
	}
end

function cls_act:sync_user_base_info()
	local pto_tbl = self:get_client_pto_info()
	for_caller.s2c_user_base_info(self:get_fd(), pto_tbl)
end

function cls_act:get_lottery_times()
	return self._lottery_times
end

function cls_act:set_lottery_times(lottery_times)
	self._lottery_times = lottery_times
	self:save_field("_lottery_times", lottery_times)
end
