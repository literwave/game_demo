
local saveFieldTbl = {
	_userId = function ()
		return nil
	end,
	_workQueueType = function()
		return nil
	end,
	_workQueueIdx = function()
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
	_workIdx = function()	-- 当前队列目标索引
		return nil
	end,
	_expireTime = function()	-- 队伍过期时间
		return nil
	end,
}

clsWorkQueue = clsObject:Inherit()

function clsWorkQueue:__init__(oci)
	Super(clsWorkQueue).__init__(self, oci)
	for k, func in pairs(saveFieldTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
	WORK_QUEUE_MGR.refWorkQueue(self)
end

function clsWorkQueue:serialize(tbl)
	for key, _ in pairs(saveFieldTbl) do
		tbl[key] = self[key]
	end
end

function clsWorkQueue:release()
	WORK_QUEUE_MGR.unrefWorkQueue(self)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.WORK_QUEUE_COL, self._userId, self._workQueueType, self._workQueueIdx}, nil)
	Super(clsWorkQueue).release(self)
end

function clsWorkQueue:saveField(keyList, val)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.WORK_QUEUE_COL, self._userId, self._workQueueType, self._workQueueIdx, unpack(keyList)}, val)
end

function clsWorkQueue:saveToDB()
	local info = {}
	self:serialize(info)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.WORK_QUEUE_COL, self._userId, self._workQueueType, self._workQueueIdx}, info)
end

function clsWorkQueue:getUserId()
	return self._userId
end

function clsWorkQueue:getWorkQueueType()
	return self._workQueueType
end

function clsWorkQueue:getWorkQueueIdx()
	return self._workQueueIdx
end

function clsWorkQueue:getQueueTbl()
	return self._queueTbl
end

function clsWorkQueue:getWorkIdx()
	return self._workIdx
end

function clsWorkQueue:getExpireTime()
	return self._expireTime
end

function clsWorkQueue:getWorkTargetId()
	if not self:getWorkIdx() then
		return
	end
	return self._queueTbl[self:getWorkIdx()].targetId
end

function clsWorkQueue:setWorkIdx(workIdx)
	self._workIdx = workIdx
	self:saveField({"_workIdx"}, self._workIdx)
end

function clsWorkQueue:setExpireTime(expireTime)
	self._expireTime = expireTime
	self:saveField({"_expireTime"}, self._expireTime)
end

function clsWorkQueue:checkIsExpired()
	return self._expireTime and self._expireTime < TIME.osBJSec()
end

function clsWorkQueue:removeQueueData(queueIdx)
	self._queueTbl[queueIdx] = nil
	self:saveField({"_queueTbl", queueIdx}, nil)
end

function clsWorkQueue:addNewWork(targetId, cancelRewardList)
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

function clsWorkQueue:getQueueFrontData()
	local frontIdx = nil
	local queueTbl = self:getQueueTbl()
	for queueIdx, _ in pairs(queueTbl) do
		if not frontIdx or queueIdx < frontIdx then
			frontIdx = queueIdx
		end
	end
	return frontIdx, queueTbl[frontIdx]
end

function clsWorkQueue:getQueueCapacity()
	return 1
end

function clsWorkQueue:onExpired()
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

function clsWorkQueue:checkCanAddNewWork(targetId)
	if self:checkIsExpired() then
		return false
	end
	if table.size(self:getQueueTbl()) >= self:getQueueCapacity() then
		return false
	end
	return true
end

function clsWorkQueue:checkTargetIsInQueue(targetId)
	for queueIdx, info in pairs(self:getQueueTbl()) do
		if info.targetId == targetId then
			return true, queueIdx
		end
	end
	return false
end

--------------------------------------------------------------------------------------------------------------------------------------------

function clsWorkQueue:systemStartup(offsetTime)
end

function clsWorkQueue:genClientPTOInfo()
	local queueInfoList = {}
	for queueIdx, info in pairs(self:getQueueTbl()) do 
		table.insert(queueInfoList, {k = queueIdx, v = info.targetId})
	end
	return {
		workQueueType = self:getWorkQueueType(),
		workQueueIdx = self:getWorkQueueIdx(),
		queueInfoList = queueInfoList,
		targetId = self:getWorkTargetId() or COMMON_CONST.BUILD_WORK_QUEUE_BUSY_NONE,
		expireTime = self:getExpireTime() or -1,
	}
end

function clsWorkQueue:tryStartWork()
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

function clsWorkQueue:afterStartWork(startQueueIdx, startTargetId)

end

function clsWorkQueue:onWorkFinish(targetId)
	local nowWorkTargetId = self:getWorkTargetId()
	assert(nowWorkTargetId == targetId)
	self._queueTbl[self:getWorkIdx()] = nil
	self:saveField({"_queueTbl", self:getWorkIdx()}, nil)
	self:setWorkIdx(nil)
end

function clsWorkQueue:getTimerKey(targetId)
	assert(false)
end

function clsWorkQueue:onCancel(queueIdx)
	if queueIdx == self:getWorkIdx() then
		return false
	end
	local targetInfo = self._queueTbl[queueIdx]
	if not targetInfo then
		return false
	end
	self:removeQueueData(queueIdx)
	return true, targetInfo
end

