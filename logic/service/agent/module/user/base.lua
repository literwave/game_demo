cls_user = cls_object:Inherit()

function cls_user:__init__(oci)
	Super(cls_user).__init__(self, oci)
	self._data = ORM.new(ORM.CLS_USER_DATA, oci)
	ORM.bind(self._data, MONGO_SLAVE.COL.USER_INFO, self._data._user_id)
	-- 运行时字段，不落库
	self._login_addr = nil
	self._fd = nil
	self._heart_beat_time = nil
	self._gate_srv = nil
	self._token = nil
	self._account = nil
	self._client_load_ok = nil
end

function cls_user:get_user_id()
	return self._data._user_id
end

function cls_user:is_online()
	return self:get_fd() ~= nil
end

function cls_user:get_birth_time()
	return self._data._birth_time
end

function cls_user:get_name()
	return self._data._name
end

function cls_user:set_name(name)
	self._data._name = name
end

function cls_user:get_sex()
	return self._data._sex
end

function cls_user:set_sex(sex)
	self._data._sex = sex
end

function cls_user:get_res_tbl()
	return self._data._res_tbl
end

function cls_user:get_res_num(res_type)
	return self._data._res_tbl[res_type] or 0
end

function cls_user:add_res(res_type, num, reason_list)
	local res_num = self:get_res_num(res_type) + num
	self._data._res_tbl[res_type] = res_num
	LOG._flow("res", self:get_user_id(), res_type, num, res_num, reason_list)
end

function cls_user:sync_res(res_type_list)
	local res_list = {}
	for _, res_type in ipairs(res_type_list) do
		table.insert(res_list, make_common_pto_tbl(res_type, self:get_res_num(res_type)))
	end
	local fd = self:get_fd()
	if fd then
		for_caller.s2c_sync_user_res_list(fd, {resList = res_list})
	end
end

function cls_user:set_sdk_param_tbl(param_tbl)
	-- 归一成 <string,string>，与 SdkParamMap 一致
	local tbl = {}
	if param_tbl then
		for k, v in pairs(param_tbl) do
			tbl[tostring(k)] = tostring(v)
		end
	end
	self._data._sdk_param_tbl = tbl
end

function cls_user:update_by_login_param_tbl(param_tbl)
	self:set_device_id(param_tbl.loginInfo.deviceId)
	self:set_client_platform(param_tbl.loginInfo.platform)
	if param_tbl.sdk_param_tbl then
		self:set_sdk_param_tbl(param_tbl.sdk_param_tbl)
	end
end

function cls_user:get_account()
	return self._account
end

function cls_user:set_account(account)
	self._account = account
end

function cls_user:get_login_addr()
	return self._login_addr
end

function cls_user:set_login_addr(addr)
	self._login_addr = addr
end

function cls_user:get_gate_srv()
	return self._gate_srv
end

function cls_user:set_gate_srv(gate_srv)
	self._gate_srv = gate_srv
end

function cls_user:get_fd()
	return self._fd
end

function cls_user:set_fd(fd)
	self._fd = fd
	self._client_load_ok = nil
end

function cls_user:is_client_load_ok()
	return self._client_load_ok
end

function cls_user:set_client_load_ok()
	self._client_load_ok = true
end

function cls_user:get_heart_beat_time()
	return self._heart_beat_time
end

function cls_user:set_heart_beat_time(time)
	self._heart_beat_time = time
end

function cls_user:set_and_sync_heart_beat_time(time)
	self:set_heart_beat_time(time)
	local fd = self:get_fd()
	local pto_tbl = {
		heartBeatTime = time
	}
	for_caller.s2c_heart_beat(fd, pto_tbl)
end

function cls_user:on_login()
	self:set_login_time(TIME.os_bj_sec())
end

function cls_user:set_login_time(time)
	self._data._login_time = time
end

function cls_user:get_login_time()
	return self._data._login_time
end

function cls_user:set_born_server_id(server_id)
	self._data._born_server_id = server_id
end

function cls_user:has_birth_pos()
	return self._data._has_birth
end

function cls_user:get_birth_x()
	return self._data._birth_x
end

function cls_user:get_birth_y()
	return self._data._birth_y
end

function cls_user:set_birth_pos(x, y)
	self._data._birth_x = x
	self._data._birth_y = y
	self._data._has_birth = true
end

function cls_user:get_diamond()
	return self._data._real_diamond + self._data._gift_diamond
end

function cls_user:get_real_diamond()
	return self._data._real_diamond
end

function cls_user:get_gift_diamond()
	return self._data._gift_diamond
end

function cls_user:add_sum_recharge_diamond(add_cnt)
	self._data._sum_recharge_diamond = self._data._sum_recharge_diamond + add_cnt
end

function cls_user:get_sum_recharge_diamond()
	return self._data._sum_recharge_diamond
end

function cls_user:add_real_diamond(add_cnt, reason_list)
	assert(add_cnt >= 0)
	assert(reason_list[1] == CONST.FLOW_REASON.RECHARGE or reason_list[1] == CONST.FLOW_REASON.WIZ)
	self._data._real_diamond = self._data._real_diamond + add_cnt
	LOG._flow("diamond", self:get_user_id(), "real", add_cnt, self:get_diamond(), reason_list)
end

function cls_user:add_gift_diamond(add_cnt, reason_list)
	assert(add_cnt >= 0)
	self._data._gift_diamond = self._data._gift_diamond + add_cnt
	LOG._flow("diamond", self:get_user_id(), "gift", add_cnt, self:get_diamond(), reason_list)
end

function cls_user:add_real_diamond_and_sync(add_cnt, reason_list)
	self:add_real_diamond(add_cnt, reason_list)
	self:sync_diamond()
end

function cls_user:add_gift_diamond_and_sync(add_cnt, reason_list)
	self:add_gift_diamond(add_cnt, reason_list)
	self:sync_diamond()
end

function cls_user:sync_diamond()
	local pto_tbl = {
		diamond = self:get_diamond()
	}
	local fd = self:get_fd()
	if fd then
		for_caller.s2c_sync_user_diamond(fd, pto_tbl)
	end
end

function cls_user:add_diamond(add_cnt, reason_list)
	assert(add_cnt >= 0)
	self._data._real_diamond = self._data._real_diamond + add_cnt
	LOG._flow("diamond", self:get_user_id(), "real", add_cnt, self:get_diamond(), reason_list)
end

function cls_user:sub_diamond(sum_sub_cnt, reason_list)
	assert(sum_sub_cnt > 0)
	assert(self:get_diamond() >= sum_sub_cnt)
	local sub_real, sub_gift = 0, 0
	if self._data._real_diamond >= sum_sub_cnt then
		sub_real = sum_sub_cnt
		self._data._real_diamond = self._data._real_diamond - sum_sub_cnt
	else
		sub_real = self._data._real_diamond
		self._data._real_diamond = 0
		sub_gift = sum_sub_cnt - sub_real
		self._data._gift_diamond = self._data._gift_diamond - sub_gift
	end
	local user_id = self:get_user_id()
	if sub_real > 0 then
		LOG._flow("diamond", user_id, "real", -sub_real, self:get_diamond() + sub_gift, reason_list)
	end
	if sub_gift > 0 then
		LOG._flow("diamond", user_id, "gift", -sub_gift, self:get_diamond(), reason_list)
	end
end

function cls_user:check_can_use_diamond(cnt)
	return cnt > 0 and self:get_diamond() >= cnt
end

function cls_user:sub_diamond_and_sync(cnt, reason_list)
	self:sub_diamond(cnt, reason_list)
	self:sync_diamond()
end

function cls_user:set_token(token)
	self._token = token
end

function cls_user:get_head_icon()
	return self._data._head_icon
end

function cls_user:set_head_icon(head_icon)
	self._data._head_icon = head_icon
end

function cls_user:get_client_pto_info()
	return {
		name = self:get_name(),
		headIcon = self:get_head_icon(),
		sex = self:get_sex(),
		birthTime = self:get_birth_time(),
		level = self:get_level(),
		exp = self:get_exp(),
		birthX = self:get_birth_x(),
		birthY = self:get_birth_y(),
	}
end

function cls_user:sync_user_base_info()
	local pto_tbl = self:get_client_pto_info()
	for_caller.s2c_user_base_info(self:get_fd(), pto_tbl)
end

function cls_user:get_lottery_times()
	return self._data._lottery_times
end

function cls_user:set_lottery_times(lottery_times)
	self._data._lottery_times = lottery_times
end

function cls_user:get_level()
	return self._data._level
end

function cls_user:get_exp()
	return self._data._exp
end

function cls_user:add_exp(exp)
	local cur_exp = self:get_exp() + exp
	local need = DATA_COMMON.get_user_level_up_exp()
	local add_level = math.floor(cur_exp / need)
	self._data._exp = cur_exp % need
	if add_level > 0 then
		self._data._level = self:get_level() + add_level
	end
	self:sync_user_base_info()
end

function cls_user:get_system_open_tbl()
	return self._data._system_open_tbl
end

function cls_user:get_system_open_time(system_id)
	local open_tbl = self:get_system_open_tbl()
	if not open_tbl then
		return
	end
	return open_tbl[system_id]
end

function cls_user:is_system_open(system_id)
	return self:get_system_open_time(system_id) ~= nil
end

function cls_user:set_system_open(system_id)
	if not self._data._system_open_tbl then
		self._data._system_open_tbl = {}
	end
	self._data._system_open_tbl[system_id] = TIME.os_bj_sec()
end
