clsQueue = clsObject:Inherit()

function clsQueue:__init__(oci)
	Super(clsQueue).__init__(self, oci)
	if ORM.is_cls(oci, ORM.CLS_QUEUE_DATA) then
		self._data = oci
	else
		self._data = ORM.create(ORM.CLS_QUEUE_DATA, oci)
	end
	QUEUE_MGR.refQueue(self)
end

function clsQueue:release()
	QUEUE_MGR.unrefQueue(self)
	QUEUE_MGR.persistUserQueues(self:getUserId())
	Super(clsQueue).release(self)
end

function clsQueue:saveField(field)
	assert(type(field) == "string", "saveField only accepts string field name")
	QUEUE_MGR.persistUserQueues(self:getUserId())
end

function clsQueue:saveToDB()
	QUEUE_MGR.persistUserQueues(self:getUserId())
end

function clsQueue:getUserId()
	return self._data._userId
end

function clsQueue:getQueueIdx()
	return self._data._queueIdx
end

function clsQueue:getQueueTbl()
	return self._data._queueTbl
end

function clsQueue:getWorkIdx()
	local v = self._data._workIdx
	if v == 0 then
		return nil
	end
	return v
end

function clsQueue:getExpireTime()
	local v = self._data._expireTime
	if v == 0 then
		return nil
	end
	return v
end

function clsQueue:getWorkTargetId()
	if not self:getWorkIdx() then
		return
	end
	local work = self._data._queueTbl[self:getWorkIdx()]
	return work and work.targetId
end

function clsQueue:setWorkIdx(workIdx)
	self._data._workIdx = workIdx or 0
	self:saveField("_workIdx")
end

function clsQueue:setExpireTime(expireTime)
	self._data._expireTime = expireTime or 0
	self:saveField("_expireTime")
end

function clsQueue:checkIsExpired()
	local expireTime = self:getExpireTime()
	return expireTime and expireTime < TIME.osBJSec()
end

function clsQueue:removeQueueData(queueIdx)
	self._data._queueTbl[queueIdx] = nil
	self:saveField("_queueTbl")
end

function clsQueue:addNewWork(targetId, cancelRewardList)
	local nextQueueIdx = 1
	local queueTbl = self:getQueueTbl()
	for queueIdx, _ in pairs(queueTbl) do
		if nextQueueIdx < queueIdx + 1 then
			nextQueueIdx = queueIdx + 1
		end
	end
	queueTbl[nextQueueIdx] = {
		targetId = targetId,
	}
	self:saveField("_queueTbl")
end

function clsQueue:getQueueFrontData()
	local frontIdx = nil
	local queueTbl = self:getQueueTbl()
	for queueIdx, _ in pairs(queueTbl) do
		if not frontIdx or queueIdx < frontIdx then
			frontIdx = queueIdx
		end
	end
	return frontIdx, queueTbl[frontIdx]
end

function clsQueue:getQueueCapacity()
	return DATA_COMMON.getQueueCapacity()
end

function clsQueue:onExpired()
	local tbl = self:getQueueTbl()
	local workIdx = self:getWorkIdx()
	if not workIdx or table.size(tbl) == 0 then
		self:release()
		return true
	end
	if table.size(tbl) == 1 then
		return false
	end
	for queueIdx, _ in pairs(tbl) do
		if queueIdx ~= workIdx then
			tbl[queueIdx] = nil
		end
	end
	self:saveField("_queueTbl")
	return true
end

function clsQueue:checkCanAddNewWork()
	if self:checkIsExpired() then
		return false
	end
	if table.size(self:getQueueTbl()) >= self:getQueueCapacity() then
		return false
	end
	return true
end

function clsQueue:checkTargetIsInQueue(targetId)
	for queueIdx, info in pairs(self:getQueueTbl()) do
		if info.targetId == targetId then
			return true, queueIdx
		end
	end
	return false
end

function clsQueue:systemStartup(offsetTime)
end

function clsQueue:genClientPTOInfo()
	local queueInfoList = {}
	for queueIdx, info in pairs(self:getQueueTbl()) do
		table.insert(queueInfoList, {k = queueIdx, v = info.targetId})
	end
	return {
		QueueType = self:getQueueType(),
		QueueIdx = self:getQueueIdx(),
		queueInfoList = queueInfoList,
		targetId = self:getWorkTargetId() or CONST.BUILD_WORK_QUEUE_BUSY_NONE,
		expireTime = self:getExpireTime() or -1,
	}
end

function clsQueue:tryStartWork()
	if self:getWorkIdx() then
		return
	end
	local startQueueIdx, startTargetInfo = self:getQueueFrontData()
	if not startQueueIdx then
		return
	end
	self:setWorkIdx(startQueueIdx)
	return startQueueIdx, startTargetInfo.targetId
end

function clsQueue:afterStartWork()
end

function clsQueue:onWorkFinish(targetId)
	local nowWorkTargetId = self:getWorkTargetId()
	assert(nowWorkTargetId == targetId)
	local workIdx = self:getWorkIdx()
	self._data._queueTbl[workIdx] = nil
	self:saveField("_queueTbl")
	self:setWorkIdx(nil)
end

function clsQueue:getTimerKey(targetId)
	assert(false)
end

function clsQueue:onCancel(workIdx)
	if workIdx == self:getWorkIdx() then
		return false
	end
	local targetInfo = self._data._queueTbl[workIdx]
	if not targetInfo then
		return false
	end
	self:removeQueueData(workIdx)
	return true, targetInfo
end

function clsQueue:getQueueType()
	return CONST.WORK_QUEUE_TYPE.BUILD
end
