allUserQueueTbl = {}
--[[
	[userId] = {
		[queueIdx] = obj,
	}
]]

function refQueue(queueObj)
	local userId = queueObj:getUserId()
	local queueIdx = queueObj:getQueueIdx()
	if not allUserQueueTbl[userId] then
		allUserQueueTbl[userId] = {}
	end
	allUserQueueTbl[userId][queueIdx] = queueObj
end

function unrefQueue(workQueueObj)
	local userId = workQueueObj:getUserId()
	local queueIdx = workQueueObj:getQueueIdx()
	if allUserQueueTbl[userId] then
		allUserQueueTbl[userId][queueIdx] = nil
		if table.isEmpty(allUserQueueTbl[userId]) then
			allUserQueueTbl[userId] = nil
		end
	end
end

local function createQueue(oci)
	return QUEUE_BASE.clsQueue:New(oci)
end

function persistUserQueues(userId)
	assert(userId)
	local queueTbl = allUserQueueTbl[userId] or {}
	local bagData = {}
	for queueIdx, queueObj in pairs(queueTbl) do
		bagData[queueIdx] = queueObj._data
	end
	local doc = ORM.create(ORM.CLS_USER_QUEUE_DOC, { _queues = bagData })
	MONGO_SLAVE.saveDoc(MONGO_SLAVE.QUEUE_COL, userId, ORM.dump(doc))
end

local function tryInitUserQueues(userId)
	if not allUserQueueTbl[userId] then
		allUserQueueTbl[userId] = {}
		local raw = MONGO_SLAVE.commonLoadSingle(MONGO_SLAVE.QUEUE_COL, userId) or {}
		local doc = ORM.create(ORM.CLS_USER_QUEUE_DOC, raw)
		for _, queueData in pairs(doc._queues) do
			if ORM.is_cls(queueData, ORM.CLS_QUEUE_DATA) then
				createQueue(queueData)
			end
		end
	end
	return allUserQueueTbl[userId]
end

function loadData()
end

function saveData()
	for userId in pairs(allUserQueueTbl) do
		persistUserQueues(userId)
	end
end

function systemStartup()
	local offsetTime = TIME.osBJSec() - GAME.getShutDownTime()
	if offsetTime <= 0 then
		return
	end
	for _, queueInfoTbl in pairs(allUserQueueTbl) do
		for _, queueObj in pairs(queueInfoTbl) do
			queueObj:systemStartup(offsetTime)
		end
	end
end

local function initUserQueue(userId)
	tryInitUserQueues(userId)
	if getUserQueue(userId, CONST.FIRST_QUEUE_IDX) then
		return
	end
	local oci = {
		_userId = userId,
		_queueIdx = CONST.FIRST_QUEUE_IDX,
	}
	local queue = createQueue(oci)
	queue:saveToDB()
end

function onUserLogin(user, isFirstLogin)
	if not isFirstLogin then
		tryInitUserQueues(user:getUserId())
		return
	end
	initUserQueue(user:getUserId())
end

function syncAllQueueInfoToClient(userId)
	local fd = USER_MGR.getFdByUserId(userId)
	if not fd then
		return
	end
	local allWorkQueueTbl = getUserAllQueueTbl(userId)
	local list = {}
	for _, queueObj in pairs(allWorkQueueTbl or EMPTY_TABLE) do
		table.insert(list, queueObj:genClientPTOInfo())
	end
	for_caller.s2c_sync_all_queue_info(fd, {list = list})
end

function syncQueueInfoToClient(queueObj)
	local userId = queueObj:getUserId()
	local fd = USER_MGR.getFdByUserId(userId)
	if fd then
		for_caller.s2c_sync_queue_info(fd, queueObj:genClientPTOInfo())
	end
end

local function tryUpdateUserQueue(userId)
	local needSyncToClient = false
	for _, queueObj in pairs(allUserQueueTbl[userId] or {}) do
		if queueObj:checkIsExpired() then
			needSyncToClient = queueObj:onExpired()
		end
	end
	if needSyncToClient then
		syncAllQueueInfoToClient(userId)
	end
end

function getUserAllQueueTbl(userId)
	tryInitUserQueues(userId)
	tryUpdateUserQueue(userId)
	return allUserQueueTbl[userId]
end

function getUserQueueTbl(userId)
	return getUserAllQueueTbl(userId)
end

function getUserQueue(userId, queueIdx)
	local queueTbl = getUserQueueTbl(userId)
	return queueTbl and queueTbl[queueIdx]
end

function createUserQueue(userId, queueIdx, expireTime)
	if getUserQueue(userId, queueIdx) then
		return
	end
	local oci = {
		_userId = userId,
		_queueIdx = queueIdx,
		_expireTime = expireTime,
	}
	local workQueueObj = createQueue(oci)
	workQueueObj:saveToDB()
end

function getIdleBuildQueue(userId, targetId)
	for _, queueIdx in ipairs(CONST.QUEUE_PRIORITY) do
		local queueObj = getUserQueue(userId, queueIdx)
		if queueObj and queueObj:checkCanAddNewWork(targetId) then
			return queueObj
		end
	end
end

function checkWorkIsExist(userId, targetId)
	local queueTbl = getUserQueueTbl(userId)
	if not queueTbl then
		return false
	end
	for _, queueObj in pairs(queueTbl) do
		if queueObj:checkTargetIsInQueue(targetId) then
			return true
		end
	end
	return false
end

function checkCanAddNewWork(userId, targetId)
	local isExist = checkWorkIsExist(userId, targetId)
	if isExist then
		return false, 350044
	end
	local queueObj = getIdleBuildQueue(userId, targetId)
	if not queueObj then
		return false, 350144
	end
	return true, nil
end

function getTargetWorkQueueInfo(userId, targetId)
	local queueTbl = getUserQueueTbl(userId)
	if not queueTbl then
		return
	end
	for _, queueObj in pairs(queueTbl) do
		local isExist, queueIdx = queueObj:checkTargetIsInQueue(targetId)
		if isExist then
			return queueTbl, queueIdx
		end
	end
	return false
end

function tryAddNewWork(userId, targetId, cancelRewardList)
	local ret, msgId = checkCanAddNewWork(userId, targetId)
	if not ret then
		return false, msgId
	end
	local queueObj = getIdleBuildQueue(userId, targetId)
	queueObj:addNewWork(targetId, cancelRewardList)
	local startQueueIdx, startTargetId = queueObj:tryStartWork()
	queueObj:afterStartWork(startQueueIdx, startTargetId)
	syncQueueInfoToClient(queueObj)
	return true
end

function tryRemoveWork(userId, queueIdx, targetId)
	if not queueIdx then
		return
	end
	local queueObj = getUserQueue(userId, queueIdx)
	if not queueObj then
		return
	end
	queueObj:onWorkFinish(targetId)
	local startQueueIdx, startTargetId = queueObj:tryStartWork()
	queueObj:afterStartWork(startQueueIdx, startTargetId)
	syncQueueInfoToClient(queueObj)
end

local function onReqBuyQueue(fd, tbl)
	local buyQueueIdx, buyCnt = tbl.buyQueueIdx, tbl.buyCnt
	if buyCnt <= 0 then
		return
	end
	local queueTbl = DATA_COMMON.getValueByKey(1)
	local queueBuyInfo = queueTbl[buyQueueIdx]
	if not queueBuyInfo then
		return
	end
	local _, costYb = table.unpack(queueBuyInfo)
	local userId = USER_MGR.getUserIdByFd(fd)
	local user = USER_MGR.getUserByFd(fd)
	if not user:checkCanUseDiamond(costYb * buyCnt) then
		return
	end
	user:subDiamondAndSync(costYb * buyCnt, {CONST.REASON_BUY_BUILD_QUEUE, buyCnt})
	local queue = getUserQueue(userId, buyQueueIdx)
	if queue then
		local expireTime = queue:getExpireTime()
		queue:setExpireTime(expireTime + CONST.ONE_HOUR_SEC * buyCnt)
	else
		createUserQueue(userId, buyQueueIdx, TIME.osBJSec() + CONST.ONE_HOUR_SEC * buyCnt)
	end
	syncAllQueueInfoToClient(userId)
	for_caller.s2c_buy_build_queue(fd, {buyQueueIdx = buyQueueIdx, buyCnt = buyCnt})
end

local function onReqAllWorkQueueInfo(fd)
	local userId = USER_MGR.getUserIdByFd(fd)
	syncAllQueueInfoToClient(userId)
end

local function onCancelBuildWork(fd, tbl)
	local workIdx, queueIdx = tbl.idx, tbl.queueIdx
	local userId = USER_MGR.getUserIdByFd(fd)
	local queueObj = getUserQueue(userId, queueIdx)
	if not queueObj then
		return
	end
	if queueObj:getWorkIdx() == workIdx then
		return
	end
	if not queueObj:onCancel(workIdx) then
		return
	end
	syncQueueInfoToClient(queueObj)
end

function __init__()
	for_maker.c2s_buy_build_queue = onReqBuyQueue
	for_maker.c2s_req_all_queue_info = onReqAllWorkQueueInfo
	for_maker.c2s_cancel_build_work = onCancelBuildWork
end
