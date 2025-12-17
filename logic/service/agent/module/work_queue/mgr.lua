
allUserWorkQueueTbl = {}
--[[
	[userId] = {
		[workQueueType] = {
			[workQueueIdx] = obj,
		}
	}
]]

function refWorkQueue(workQueueObj)
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

function unrefWorkQueue(workQueueObj)
	local userId = workQueueObj:getUserId()
	local workQueueType = workQueueObj:getWorkQueueType()
	local workQueueIdx = workQueueObj:getWorkQueueIdx()
	allUserWorkQueueTbl[userId][workQueueType][workQueueIdx] = nil
	if table.isEmpty(allUserWorkQueueTbl[userId][workQueueType]) then
		allUserWorkQueueTbl[userId][workQueueType] = nil
	end
	if table.isEmpty(allUserWorkQueueTbl[userId]) then
		allUserWorkQueueTbl[userId] = nil
	end
end

local WORK_QUEUE_MODE = {
	[CONST.WORK_QUEUE_TYPE.BUILD] = {
		[1] = BUILD_WORK_QUEUE_BASE,
		[2] = BUILD_WORK_QUEUE_BASE,
	}
}

local function createWorkQueue(oci)
	local mod = WORK_QUEUE_MODE[oci._workQueueType][oci._workQueueIdx]
	assert(mod)
	return mod.clsWorkQueue:New(oci)
end

function loadData()
	local tbl = MONGO_SLAVE.commonLoadTbl(MONGO_SLAVE.WORK_QUEUE_COL)
	for userId, allQueueInfo in pairs(tbl) do
		for workQueueType, queueInfoTbl in pairs(allQueueInfo) do
			for queueIdx, info in pairs(queueInfoTbl) do
				createWorkQueue(info)
			end
		end
	end
end

function saveData()
	local saveTbl = {}
	for userId, allQueueInfo in pairs(allUserWorkQueueTbl) do
		saveTbl[userId] = {}
		for workQueueType, queueInfoTbl in pairs(allQueueInfo) do
			saveTbl[userId][workQueueType] = {}
			for queueIdx, workQueueObj in pairs(queueInfoTbl) do
				local info = {}
				workQueueObj:serialize(info)
				saveTbl[userId][workQueueType][queueIdx] = info
			end
		end
	end
	MONGO_SLAVE.commonSaveTbl(MONGO_SLAVE.WORK_QUEUE_COL, saveTbl)
end

function systemStartup()
	-- 起服时 根据关服时长补偿在关服时开始建造的建筑/科技
	local offsetTime = TIME.osBJSec() - SERVER_INFO.getShutDownTime()
	if offsetTime <= 0 then
		return
	end
	for userId, userWorkQueueTbl in pairs(allUserWorkQueueTbl) do
		for workQueueType, queueInfoTbl in pairs(userWorkQueueTbl) do
			for queueIdx, workQueueObj in pairs(queueInfoTbl) do
				workQueueObj:systemStartup(offsetTime)
			end
		end
	end
end

function syncAllWorkQueueInfoToClient(userId)
	local vfd = USER_MGR.getVfdByUserId(userId)
	if not vfd then
		return
	end
	local allWorkQueueTbl = getUserAllWorkQueueTbl(userId)
	local list = {}
	for workQueueType, queueInfoTbl in pairs(allWorkQueueTbl or {}) do
		for queueIdx, workQueueObj in pairs(queueInfoTbl) do
			table.insert(list, workQueueObj:genClientPTOInfo())
		end
	end
	for_caller.c_sync_all_work_queue_info(vfd, list)
end

function syncWorkQueueInfoToClient(workQueueObj)
	local userId = workQueueObj:getUserId()
	local vfd = USER_MGR.getVfdByUserId(userId)
	if vfd then
		for_caller.c_sync_work_queue_info(vfd, workQueueObj:genClientPTOInfo())
	end
end

function initUserWorkQueue(userId)
	local oci = {
		_userId = userId,
		_workQueueType = CONST.WORK_QUEUE_TYPE.BUILD,
		_workQueueIdx = 1,
	}
	local workQueue = createWorkQueue(oci)
	workQueue:saveToDB()
end

local function tryUpdateUserWorkQueue(userId)
	local needSyncToClient = false
	for workQueueType, queueInfoTbl in pairs(allUserWorkQueueTbl[userId] or {}) do
		for queueIdx, workQueueObj in pairs(queueInfoTbl) do
			if workQueueObj:checkIsExpired() then
				needSyncToClient = workQueueObj:onExpired()
			end
		end
	end
	if needSyncToClient then
		syncAllWorkQueueInfoToClient(userId)
	end
end

function getUserAllWorkQueueTbl(userId)
	tryUpdateUserWorkQueue(userId)
	return allUserWorkQueueTbl[userId]
end

function getUserWorkQueueTbl(userId, workQueueType)
	local allWorkQueueTbl = getUserAllWorkQueueTbl(userId)
	return allWorkQueueTbl and allWorkQueueTbl[workQueueType]
end

function getUserWorkQueue(userId, workQueueType, workQueueIdx)
	local workQueueTbl = getUserWorkQueueTbl(userId, workQueueType)
	return workQueueTbl and workQueueTbl[workQueueIdx]
end

function createUserWorkQueue(userId, workQueueType, workQueueIdx, expireTime)
	local mod = WORK_QUEUE_MODE[workQueueType][workQueueIdx]
	assert(mod)
	if getUserWorkQueue(userId, workQueueType, workQueueIdx) then
		return
	end
	local oci = {
		_userId = userId,
		_workQueueType = workQueueType,
		_workQueueIdx = workQueueIdx,
		_expireTime = expireTime,
	}
	local workQueueObj = createWorkQueue(oci)
	workQueueObj:saveToDB()
end

local WORK_QUEUE_PRIORITY = {
	[COMMON_CONST.WORK_QUEUE_TYPE.BUILD] = {1, 2, 3},
}

function getFreeBuildWorkQueue(userId, workQueueType, targetId)
	local priorityList = WORK_QUEUE_PRIORITY[workQueueType]
	for _, workQueueIdx in ipairs(priorityList) do
		local workQueueObj = getUserWorkQueue(userId, workQueueType, workQueueIdx)
		if workQueueObj and workQueueObj:checkCanAddNewWork(targetId) then
			return workQueueObj
		end
	end
end

function checkWorkIsExist(userId, workQueueType, targetId)
	local workQueueTbl = getUserWorkQueueTbl(userId, workQueueType)
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

function checkCanAddNewWork(userId, workQueueType, targetId)
	local isExist = checkWorkIsExist(userId, workQueueType, targetId)
	if isExist then
		return false, 350044
	end
	local workQueueObj = getFreeBuildWorkQueue(userId, workQueueType, targetId)
	if not workQueueObj then
		return false, 350144
	end
	return true, nil, workQueueObj
end

function getTargetWorkQueueInfo(userId, workQueueType, targetId)
	local workQueueTbl = getUserWorkQueueTbl(userId, workQueueType)
	if not workQueueTbl then
		return
	end
	for _, workQueueObj in pairs(workQueueTbl) do
		local isExist, queueIdx = workQueueObj:checkTargetIsInQueue(targetId)
		if isExist then
			return workQueueObj, queueIdx
		end
	end
	return false
end

function tryAddNewWork(userId, workQueueType, targetId, cancelRewardList)
	local ret, msgId, workQueueObj = checkCanAddNewWork(userId, workQueueType, targetId)
	if not ret then
		return false, msgId
	end
	workQueueObj:addNewWork(targetId, cancelRewardList)
	local startQueueIdx, startTargetId = workQueueObj:tryStartWork()
	workQueueObj:afterStartWork(startQueueIdx, startTargetId)
	syncWorkQueueInfoToClient(workQueueObj)
	return true
end

function tryRemoveWork(userId, workQueueType, workQueueIdx, targetId)
	if not workQueueIdx then
		return
	end
	local workQueueObj = getUserWorkQueue(userId, workQueueType, workQueueIdx)
	if not workQueueObj then
		return
	end
	workQueueObj:onWorkFinish(targetId)
	local startQueueIdx, startTargetId = workQueueObj:tryStartWork()
	workQueueObj:afterStartWork(startQueueIdx, startTargetId)
	syncWorkQueueInfoToClient(workQueueObj)
end

local AFTER_CREATE_UNION_HELP_FUNC = {
	[CONST.EVENT_KEY_BUILD] = {
		[3] = function(userId, workQueueIdx)
			local workQueueObj = getUserWorkQueue(userId, CONST.WORK_QUEUE_TYPE.BUILD, workQueueIdx)
			workQueueObj:setNeedUnionHelp(true)
		end,
	},
}

function afterCreateUnionHelp(paramTbl, eventKey, customKey)
	if not paramTbl or not paramTbl.workQueueIdx or not eventKey or not customKey then
		return
	end
	local func = AFTER_CREATE_UNION_HELP_FUNC[eventKey] and AFTER_CREATE_UNION_HELP_FUNC[eventKey][paramTbl.workQueueIdx]
	if not func then
		return
	end
	func(paramTbl.userId, paramTbl.workQueueIdx)
end

-------------------------------------------------------------------------------------------------------------------------------------------------

local function onReqBuyWorkQueue(vfd, buyWorkQueueIdx, buyCnt)
	if buyCnt <= 0 then
		return
	end
	local workQueueTbl = DATA_COMMON.getValueByKey(1)
	local queueBuyInfo = workQueueTbl[buyWorkQueueIdx]
	if not queueBuyInfo then
		return
	end
	local _, costYb = unpack(queueBuyInfo)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	local user = USER_MGR.getUserByVfd(vfd)
	
	if not user:checkCanUseDiamond(costYb * buyCnt) then
		return
	end
	user:subDiamondAndSync(costYb * buyCnt, {CONST.FLOW_REASON.BUY_BUILD_WORK_QUEUE, buyCnt})

	local workQueue = WORK_QUEUE_MGR.getUserWorkQueue(userId, CONST.WORK_QUEUE_TYPE.BUILD, buyWorkQueueIdx)
	if workQueue then
		local expireTime = workQueue:getExpireTime()
		workQueue:setExpireTime(expireTime + CONST.ONE_HOUR_SEC * buyCnt)
	else
		createUserWorkQueue(userId, CONST.WORK_QUEUE_TYPE.BUILD, buyWorkQueueIdx, TIME.osBJSec() + COMMON_CONST.ONE_HOUR_SEC * buyCnt)
	end
	syncAllWorkQueueInfoToClient(userId)
	for_caller.c_buy_build_work_queue(vfd, buyWorkQueueIdx, buyCnt)
end

local function onReqAllWorkQueueInfo(vfd)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	syncAllWorkQueueInfoToClient(userId)
end

local function onCancelBuildWork(vfd, workQueueType, workQueueIdx, queueIdx)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	local workQueueObj = getUserWorkQueue(userId, workQueueType, workQueueIdx)
	if not workQueueObj then
		return
	end
	if workQueueObj:getWorkIdx() == queueIdx then
		return
	end
	if not workQueueObj:onCancel(queueIdx) then
		return
	end
	syncWorkQueueInfoToClient(workQueueObj)
end

function __init__()
	for_maker.s_buy_build_work_queue = onReqBuyWorkQueue
	for_maker.s_req_all_work_queue_info = onReqAllWorkQueueInfo
	for_maker.s_cancel_build_work = onCancelBuildWork
end
