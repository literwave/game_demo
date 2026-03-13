
local saveFieldTbl = {
	_userId = function ()
		return nil
	end,
	_queueIdx = function()
		return nil
	end,
	_queueTbl = function()
		return {}
		--[[
			[queueIdx] = {
				targetId = *,
				cancelRewardList = {},
			}
		]]
	end,
	_workIdx = function()
		return nil
	end,
	_expireTime = function()
		return nil
	end,
}

clsQueue = clsObject:Inherit()

function clsQueue:__init__(oci)
	Super(clsQueue).__init__(self, oci)
	for k, func in pairs(saveFieldTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
	QUEUE_MGR.refQueue(self)
end

function clsQueue:serialize(tbl)
	for key, _ in pairs(saveFieldTbl) do
		tbl[key] = self[key]
	end
end

function clsQueue:release()
	QUEUE_MGR.unrefQueue(self)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.QUEUE_COL, self._userId, self._queueIdx}, nil)
	Super(clsQueue).release(self)
end

function clsQueue:saveField(keyList, val)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.QUEUE_COL, self._userId, self._queueIdx, table.unpack(keyList)}, val)
end

function clsQueue:saveToDB()
	local info = {}
	self:serialize(info)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.QUEUE_COL, self._userId, self._queueIdx}, info)
end

function clsQueue:getUserId()
	return self._userId
end

function clsQueue:getQueueIdx()
	return self._queueIdx
end

function clsQueue:getQueueTbl()
	return self._queueTbl
end

function clsQueue:getWorkIdx()
	return self._workIdx
end

function clsQueue:getExpireTime()
	return self._expireTime
end

function clsQueue:getWorkTargetId()
	if not self:getWorkIdx() then
		return
	end
	return self._queueTbl[self:getWorkIdx()].targetId
end

function clsQueue:setWorkIdx(workIdx)
	self._workIdx = workIdx
	self:saveField({"_workIdx"}, self._workIdx)
end

function clsQueue:setExpireTime(expireTime)
	self._expireTime = expireTime
	self:saveField({"_expireTime"}, self._expireTime)
end

function clsQueue:checkIsExpired()
	return self._expireTime and self._expireTime < TIME.osBJSec()
end

function clsQueue:removeQueueData(queueIdx)
	self._queueTbl[queueIdx] = nil
	self:saveField({"_queueTbl", queueIdx}, nil)
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
		cancelRewardList = cancelRewardList,
	}
	self:saveField({"_queueTbl", nextQueueIdx}, queueTbl[nextQueueIdx])
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
	self:saveField({"_queueTbl"}, tbl)
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

--------------------------------------------------------------------------------------------------------------------------------------------

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
	self._queueTbl[self:getWorkIdx()] = nil
	self:saveField({"_queueTbl", self:getWorkIdx()}, nil)
	self:setWorkIdx(nil)
end

function clsQueue:getTimerKey(targetId)
	assert(false)
end

function clsQueue:onCancel(workIdx)
	if workIdx == self:getWorkIdx() then
		return false
	end
	local targetInfo = self._queueTbl[workIdx]
	if not targetInfo then
		return false
	end
	self:removeQueueData(workIdx)
	return true, targetInfo
end

