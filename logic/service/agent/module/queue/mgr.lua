
allUserWorkQueueTbl = {}
--[[
	[userId] = {
		[queueIdx] = obj,
	}
]]

function refQueue(workQueueObj)
	local userId = workQueueObj:getUserId()
	local workQueueType = workQueueObj:getWorkQueueType()
	local workQueueIdx = workQueueObj:getWorkQueueIdx()
	if not allUserWorkQueueTbl[userId] then
		allUserWorkQueueTbl[userId] = {}
	end
	if not allUserWorkQueueTbl[userId][workQueueType] then
		allUserWorkQueueTbl[userId][workQueueType] = {}
	end
	allUserWorkQueueTbl[userId][workQueueType][workQueueIdx] = workQueueObj
end

function unrefQueue(workQueueObj)
	local userId = workQueueObj:getUserId()
	local workQueueIdx = workQueueObj:getWorkQueueIdx()
	allUserWorkQueueTbl[userId][workQueueIdx] = nil
	if table.isEmpty(allUserWorkQueueTbl[userId]) then
		allUserWorkQueueTbl[userId] = nil
	end
end

local function createQueue(oci)
	return QUEUE_BASE.clsQueue:New(oci)
end

function loadData()
	local tbl = MONGO_SLAVE.commonLoadTbl(MONGO_SLAVE.QUEUE_COL)
	for _, queueInfoTbl in pairs(tbl) do
		for _, info in pairs(queueInfoTbl) do
			createQueue(info)
		end
	end
end

function saveData()
	local saveTbl = {}
	for userId, queueInfoTbl in pairs(allUserWorkQueueTbl) do
		saveTbl[userId] = {}
		for queueIdx, queueObj in pairs(queueInfoTbl) do
			local info = {}
			queueObj:serialize(info)
			saveTbl[userId][queueIdx] = info
		end
	end
	MONGO_SLAVE.commonSaveTbl(MONGO_SLAVE.QUEUE_COL, saveTbl)
end

function systemStartup()
	local offsetTime = TIME.osBJSec() - GAME.getShutDownTime()
	if offsetTime <= 0 then
		return
	end
	for _, queueInfoTbl in pairs(allUserWorkQueueTbl) do
		for _, queueObj in pairs(queueInfoTbl) do
			queueObj:systemStartup(offsetTime)
		end
	end
end

local function initUserQueue(userId)
	local oci = {
		_userId = userId,
		_queueIdx = CONST.FIRST_QUEUE_IDX,
	}
	local queue = createQueue(oci)
	queue:saveToDB()
end

function onUserLogin(user, isFirstLogin)
	if not isFirstLogin then
		return
	end
	initUserQueue(user:getUserId())
end

function syncAllQueueInfoToClient(userId)
	local fd = USER_MGR.getfdByUserId(userId)
	if not fd then
		return
	end
	local allWorkQueueTbl = getUserAllQueueTbl(userId)
	local list = {}
	for _, queueInfoTbl in pairs(allWorkQueueTbl or EMPTY_TABLE) do
		for _, queueObj in pairs(queueInfoTbl) do
			table.insert(list, queueObj:genClientPTOInfo())
		end
	end
	for_caller.s2c_sync_all_queue_info(fd, list)
end

function syncQueueInfoToClient(queueObj)
	local userId = queueObj:getUserId()
	local fd = USER_MGR.getFdByUserId(userId)
	if fd then
		for_caller.s2c_sync_queue_info(fd, queueObj:genClientPTOInfo())
	end
end

local function tryUpdateUserWorkQueue(userId)
	local needSyncToClient = false
	for _, queueInfoTbl in pairs(allUserWorkQueueTbl[userId] or {}) do
		for _, queueObj in pairs(queueInfoTbl) do
			if queueObj:checkIsExpired() then
				needSyncToClient = queueObj:onExpired()
			end
		end
	end
	if needSyncToClient then
		syncAllQueueInfoToClient(userId)
	end
end

function getUserAllQueueTbl(userId)
	tryUpdateUserWorkQueue(userId)
	return allUserWorkQueueTbl[userId]
end

function getUserQueueTbl(userId)
	local allWorkQueueTbl = getUserAllQueueTbl(userId)
	return allWorkQueueTbl
end

function getUserQueue(userId, queueIdx)
	local workQueueTbl = getUserQueueTbl(userId)
	return workQueueTbl and workQueueTbl[queueIdx]
end

function createUserQueue(userId, workQueueIdx, expireTime)
	if getUserQueue(userId, workQueueIdx) then
		return
	end
	local oci = {
		_userId = userId,
		_workQueueIdx = workQueueIdx,
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
	local workQueueTbl = getUserQueueTbl(userId)
	if not workQueueTbl then
		return false
	end
	for _, workQueueObj in pairs(workQueueTbl) do
		if workQueueObj:checkTargetIsInQueue(targetId) then
			return true, workQueueObj
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

local function onReqBuyQueue(fd, buyQueueIdx, buyCnt)
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
	for_caller.s2c_buy_build_queue(fd, buyQueueIdx, buyCnt)
end

local function onReqAllWorkQueueInfo(fd)
	local userId = USER_MGR.getUserIdByFd(fd)
	syncAllQueueInfoToClient(userId)
end

local function onCancelBuildWork(fd, workQueueIdx, queueIdx)
	local userId = USER_MGR.getUserIdByFd(fd)
	local queueObj = getUserQueue(userId, workQueueIdx)
	if not queueObj then
		return
	end
	if queueObj:getWorkIdx() == queueIdx then
		return
	end
	if not queueObj:onCancel(queueIdx) then
		return
	end
	syncQueueInfoToClient(queueObj)
end

function __init__()
	for_maker.c2s_buy_build_queue = onReqBuyQueue
	for_maker.c2s_req_all_queue_info = onReqAllWorkQueueInfo
	for_maker.c2s_cancel_build_work = onCancelBuildWork
end