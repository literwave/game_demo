cls_queue = cls_object:Inherit()

function cls_queue:__init__(oci)
	Super(cls_queue).__init__(self, oci)
	self._data = ORM.new(ORM.CLS_QUEUE_DATA, oci)
	ORM.get(MONGO_SLAVE.COL.QUEUE, self._data._user_id)._queues[self._data._queue_idx] = self._data
	QUEUE_MGR.ref_queue(self)
end

function cls_queue:release()
	ORM.get(MONGO_SLAVE.COL.QUEUE, self:get_user_id())._queues[self:get_queue_idx()] = nil
	QUEUE_MGR.unref_queue(self)
	Super(cls_queue).release(self)
end

function cls_queue:get_user_id()
	return self._data._user_id
end

function cls_queue:get_queue_idx()
	return self._data._queue_idx
end

function cls_queue:get_queue_tbl()
	return self._data._queue_tbl
end

function cls_queue:get_work_idx()
	local v = self._data._work_idx
	if v == 0 then
		return nil
	end
	return v
end

function cls_queue:get_expire_time()
	local v = self._data._expire_time
	if v == 0 then
		return nil
	end
	return v
end

function cls_queue:get_work_target_id()
	if not self:get_work_idx() then
		return
	end
	local work = self._data._queue_tbl[self:get_work_idx()]
	return work and work.target_id
end

function cls_queue:set_work_idx(work_idx)
	self._data._work_idx = work_idx or 0
end

function cls_queue:set_expire_time(expire_time)
	self._data._expire_time = expire_time or 0
end

function cls_queue:check_is_expired()
	local expire_time = self:get_expire_time()
	return expire_time and expire_time < TIME.os_bj_sec()
end

function cls_queue:remove_queue_data(queue_idx)
	self._data._queue_tbl[queue_idx] = nil
end

function cls_queue:add_new_work(target_id, cancel_reward_list)
	local next_queue_idx = 1
	local queue_tbl = self:get_queue_tbl()
	for queue_idx, _ in pairs(queue_tbl) do
		if next_queue_idx < queue_idx + 1 then
			next_queue_idx = queue_idx + 1
		end
	end
	queue_tbl[next_queue_idx] = {
		target_id = target_id,
	}
end

function cls_queue:get_queue_front_data()
	local front_idx = nil
	local queue_tbl = self:get_queue_tbl()
	for queue_idx, _ in pairs(queue_tbl) do
		if not front_idx or queue_idx < front_idx then
			front_idx = queue_idx
		end
	end
	return front_idx, queue_tbl[front_idx]
end

function cls_queue:get_queue_capacity()
	return DATA_COMMON.get_queue_capacity()
end

function cls_queue:on_expired()
	local tbl = self:get_queue_tbl()
	local work_idx = self:get_work_idx()
	if not work_idx or table.size(tbl) == 0 then
		self:release()
		return true
	end
	if table.size(tbl) == 1 then
		return false
	end
	for queue_idx, _ in pairs(tbl) do
		if queue_idx ~= work_idx then
			tbl[queue_idx] = nil
		end
	end
	return true
end

function cls_queue:check_can_add_new_work()
	if self:check_is_expired() then
		return false
	end
	if table.size(self:get_queue_tbl()) >= self:get_queue_capacity() then
		return false
	end
	return true
end

function cls_queue:check_target_is_in_queue(target_id)
	for queue_idx, info in pairs(self:get_queue_tbl()) do
		if info.target_id == target_id then
			return true, queue_idx
		end
	end
	return false
end

function cls_queue:system_startup(offset_time)
end

function cls_queue:gen_client_pto_info()
	local queue_info_list = {}
	for queue_idx, info in pairs(self:get_queue_tbl()) do
		table.insert(queue_info_list, {k = queue_idx, v = info.target_id})
	end
	return {
		queue_type = self:get_queue_type(),
		queue_idx = self:get_queue_idx(),
		queue_info_list = queue_info_list,
		target_id = self:get_work_target_id() or CONST.BUILD_WORK_QUEUE_BUSY_NONE,
		expire_time = self:get_expire_time() or -1,
	}
end

function cls_queue:try_start_work()
	if self:get_work_idx() then
		return
	end
	local start_queue_idx, start_target_info = self:get_queue_front_data()
	if not start_queue_idx then
		return
	end
	self:set_work_idx(start_queue_idx)
	return start_queue_idx, start_target_info.target_id
end

function cls_queue:after_start_work()
end

function cls_queue:on_work_finish(target_id)
	local now_work_target_id = self:get_work_target_id()
	assert(now_work_target_id == target_id)
	local work_idx = self:get_work_idx()
	self._data._queue_tbl[work_idx] = nil
	self:set_work_idx(nil)
end

function cls_queue:get_timer_key(target_id)
	assert(false)
end

function cls_queue:on_cancel(work_idx)
	if work_idx == self:get_work_idx() then
		return false
	end
	local target_info = self._data._queue_tbl[work_idx]
	if not target_info then
		return false
	end
	self:remove_queue_data(work_idx)
	return true, target_info
end

function cls_queue:get_queue_type()
	return CONST.WORK_QUEUE_TYPE.BUILD
end
