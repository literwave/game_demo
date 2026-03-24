
allMailTbl = {}
--[[
	[mailId] = mail,
--]]

delMailIdTbl = {}
--[[
	[mailId] = true,
--]]

userMailInfoTbl = {}
--[[
	[userId] = {
		mailTbl = {
			[mailKind] = {
				[mailId] = {
					isRead = *,
					isGotReward = *,
					isLock = *,
					lv = *,
				},
			},
		},
		fetchSvrIdx = *,
	}
--]]

svrMailInfo = {}
--[[
	globalIdx = *,
	svrMailTbl = {
		[idx] = mailId,
	}
--]]

mailRefTbl = {}
--[[
	[mailId] = cnt,
--]]

function saveData()
	local saveMailTbl = {}
	for mailId, mail in pairs(allMailTbl) do
		local info = {}
		mail:serialize(info)
		saveMailTbl[mailId] = info
	end
	MONGO_SLAVE.commonSaveMany(MONGO_SLAVE.MAIL_COL, saveMailTbl)
	local delMailTbl = {}
	for mailId in pairs(delMailIdTbl) do
		if not saveMailTbl[mailId] then
			delMailTbl[mailId] = true
		end
	end
	MONGO_SLAVE.commonDelMany(MONGO_SLAVE.MAIL_COL, delMailTbl)
	MONGO_SLAVE.commonSaveTbl(MONGO_SLAVE.USER_MAIL_COL, userMailInfoTbl)
	MONGO_SLAVE.commonSaveTbl(MONGO_SLAVE.SVR_MAIL_COL, svrMailInfo)
end

local function createMail(oci)
	if oci._isBattleMail then
		return MAIL_BATTLE.clsMail:New(oci)
	end
	return MAIL_BASE.clsMail:New(oci)
end

function loadData()
	userMailInfoTbl = MONGO_SLAVE.commonLoadTbl(MONGO_SLAVE.USER_MAIL_COL)
	svrMailInfo = MONGO_SLAVE.commonLoadTbl(MONGO_SLAVE.SVR_MAIL_COL)
	if not svrMailInfo.globalIdx then
		svrMailInfo = {
			globalIdx = 0,
			svrMailTbl = {},
		}
	end
	for _, mailId in pairs(svrMailInfo.svrMailTbl) do
		mailRefTbl[mailId] = (mailRefTbl[mailId] or 0) + 1
	end
	for _, userInfo in pairs(userMailInfoTbl) do
		for _, mailTbl in pairs(userInfo.mailTbl) do
			for mailId, _ in pairs(mailTbl) do
				mailRefTbl[mailId] = (mailRefTbl[mailId] or 0) + 1
			end
		end
	end
end

local function tryInitUserMailInfo(userId)
	if not userMailInfoTbl[userId] then
		userMailInfoTbl[userId] = {
			mailTbl = {},
			fetchSvrIdx = svrMailInfo.globalIdx,
		}
		MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_MAIL_COL, userId}, userMailInfoTbl[userId])
	end
end

local function tryInitMailTbl(mailIdList)
	local ret = {}
	local queryList = {}
	for _, mailId in pairs(mailIdList) do
		local mail = allMailTbl[mailId]
		if mail then
			ret[mailId] = mail
		else
			table.insert(queryList, mailId)
		end
	end
	if #queryList > 0 then
		local dataTbl = MONGO_SLAVE.commonLoadMany(MONGO_SLAVE.MAIL_COL, queryList)
		for mailId, data in pairs(dataTbl) do
			local mail = createMail(data)
			allMailTbl[mailId] = mail
			ret[mailId] = mail
		end
	end
	return ret
end

function tryInitMail(mailId)
	if not allMailTbl[mailId] then
		local saveTbl = MONGO_SLAVE.commonLoadSingle(MONGO_SLAVE.MAIL_COL, mailId)
		if not saveTbl or not next(saveTbl) then
			return
		end
		allMailTbl[mailId] = createMail(saveTbl)
	end
	return allMailTbl[mailId]
end

local function getUserMailTbl(userId)
	tryInitUserMailInfo(userId)
	return userMailInfoTbl[userId].mailTbl
end

local function getUserMailByKind(userId, mailKind)
	local mailTbl = getUserMailTbl(userId)
	return mailTbl[mailKind]
end

local function getUserMailInfo(userId, mailKind, mailId)
	local mailTbl = getUserMailByKind(userId, mailKind)
	return mailTbl and mailTbl[mailId]
end

local function setMailReaded(userId, mailKind, mailId)
	local userMailInfo = getUserMailInfo(userId, mailKind, mailId)
	if not userMailInfo.isRead then
		userMailInfo.isRead = true
		MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_MAIL_COL, userId, "mailTbl", mailKind, mailId, "isRead"}, true)
	end
end

local function setMailRewarded(userId, mailKind, mailId)
	local userMailInfo = getUserMailInfo(userId, mailKind, mailId)
	userMailInfo.isGotReward = true
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_MAIL_COL, userId, "mailTbl", mailKind, mailId, "isGotReward"}, true)
end

local function setMailLock(userId, mailKind, mailId, isLock)
	local userMailInfo = getUserMailInfo(userId, mailKind, mailId)
	userMailInfo.isLock = isLock
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_MAIL_COL, userId, "mailTbl", mailKind, mailId, "isLock"}, isLock)
end

local function delMail(mailId)
	assert(not delMailIdTbl[mailId])
	local mail = allMailTbl[mailId]
	if mail then
		delMailIdTbl[mailId] = true
		mail:release()
		allMailTbl[mailId] = nil
	end
end

local function incrMailRefCnt(mailId)
	mailRefTbl[mailId] = (mailRefTbl[mailId] or 0) + 1
end

local function descMailRefCnt(mailId)
	mailRefTbl[mailId] = mailRefTbl[mailId] - 1
	if mailRefTbl[mailId] <= 0 then
		delMail(mailId)
		mailRefTbl[mailId] = nil
	end
end

local function delUserMail(userId, mailKind, mailId)
	local mailTbl = userMailInfoTbl[userId].mailTbl
	if mailTbl[mailKind] and mailTbl[mailKind][mailId] then
		mailTbl[mailKind][mailId] = nil
		MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_MAIL_COL, userId, "mailTbl", mailKind, mailId}, nil)
		descMailRefCnt(mailId)
	end
end

local function addUserMailInfo(userId, mailKind, mailId, userMailInfo)
	local mailTbl = getUserMailTbl(userId)
	if not mailTbl[mailKind] then
		mailTbl[mailKind] = {}
	end
	assert(not mailTbl[mailKind][mailId])
	mailTbl[mailKind][mailId] = userMailInfo
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_MAIL_COL, userId, "mailTbl", mailKind, mailId}, userMailInfo)
	incrMailRefCnt(mailId)
end

local function setUserFetchSvrIdx(userId, idx)
	userMailInfoTbl[userId].fetchSvrIdx = idx
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.USER_MAIL_COL, userId, "fetchSvrIdx"}, idx)
end

local function addSvrMail(mailId)
	local idx = svrMailInfo.globalIdx + 1
	incrMailRefCnt(mailId)
	svrMailInfo.globalIdx = idx
	svrMailInfo.svrMailTbl[idx] = mailId
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.SVR_MAIL_COL, "globalIdx"}, idx)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.SVR_MAIL_COL, "svrMailTbl", idx}, mailId)
end

local function delSvrMail(idx)
	local mailId = svrMailInfo.svrMailTbl[idx]
	svrMailInfo.svrMailTbl[idx] = nil
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.SVR_MAIL_COL, "svrMailTbl", idx}, nil)
	descMailRefCnt(mailId)
end

local function tryClearSvrMail()
	for idx, mailId in pairs(svrMailInfo.svrMailTbl) do
		local mail = tryInitMail(mailId)
		if mail:isTimeout() then
			delSvrMail(idx)
		end
	end
end

local function genMailSimPto(userId, mailKind, mailId)
	local userMailInfo = getUserMailInfo(userId, mailKind, mailId)
	local mail = tryInitMail(mailId)
	local ret = {
		mailId = mailId,
		title = mail:getTitle(),
		content = mail:genContentStr(),
		startTime = mail:getStartTime(),
		endTime = mail:getEndTime(),
		mailType = mail:getMailType(),
		mailAvatarType = mail:getMailAvatarType(),
		isRead = userMailInfo.isRead,
		isLock = userMailInfo.isLock,
		isGotReward = userMailInfo.isGotReward,
	}
	return ret
end

local function putMailToUser(userId, mailKind, mailId)
	local userMailInfo = {
		isRead = false,
		isGotReward = true,
		isLock = false,
	}
	local mail = tryInitMail(mailId)
	if COMMON_FUNC.hasElement(mail:getRewardList()) then
		userMailInfo.isGotReward = false
	end
	addUserMailInfo(userId, mailKind, mailId, userMailInfo)
end

local function putMailToUserAndSync(userId, mailKind, mailId)
	putMailToUser(userId, mailKind, mailId)
	local vfd = USER_MGR.getVfdByUserId(userId)
	if vfd then
		local info = genMailSimPto(userId, mailKind, mailId)
		for_caller.c_sync_new_mail(vfd, mailKind, info)
	end
end

local function tryGetSvrMail(userId)
	tryInitUserMailInfo(userId)
	local lastFetchIdx = userMailInfoTbl[userId].fetchSvrIdx
	local allSvrMailTbl = svrMailInfo.svrMailTbl
	for idx = lastFetchIdx+1, svrMailInfo.globalIdx do
		setUserFetchSvrIdx(userId, idx)
		local mailId = allSvrMailTbl[idx]
		local mail = mailId and tryInitMail(mailId)
		if mail and not mail:isTimeout() then
			putMailToUserAndSync(userId, mail:getMailKind(), mailId)
		end
	end
end

local function createNewMail(mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec, mailAvatarType)
	assert(lifeSec)
	local mailId = getIdBySrvIdAndTimestamp()
	local startTime = TIME.osBJSec()
	local endTime = -1
	if lifeSec > 0 then
		endTime = startTime + lifeSec
	end
	local oci = {
		_mailId = mailId,
		_mailKind = mailKind,
		_mailType = mailType,
		_title = title,
		_contentTbl = contentTbl,
		_detailTbl = detailTbl,
		_rewardList = rewardList,
		_startTime = startTime,
		_endTime = endTime,
	}
	local mail = createMail(oci)
	mail:saveToDB()
	allMailTbl[mailId] = mail
	return mailId
end

local function createNewBattleMail(mailKind, mailType, title, contentTbl, detailTbl, rewardList, mailBattleRec, lifeSec, mailAvatarType)
	assert(lifeSec)
	local mailId = getIdBySrvIdAndTimestamp()
	local startTime = TIME.osBJSec()
	local endTime = -1
	if lifeSec > 0 then
		endTime = startTime + lifeSec
	end
	local oci = {
		_mailId = mailId,
		_mailKind = mailKind,
		_mailType = mailType,
		_title = title,
		_contentTbl = contentTbl,
		_detailTbl = detailTbl,
		_rewardList = rewardList,
		_startTime = startTime,
		_endTime = endTime,
		_mailAvatarType = mailAvatarType,
		_result = mailBattleRec.result,
		_campRecTbl = mailBattleRec.campRecTbl,
		_userRecTbl = mailBattleRec.userRecTbl,
		_soldierRecList = mailBattleRec.soldierRecList,
		_heroInfoList = mailBattleRec.heroInfoList,
		_battleAttrRateList = mailBattleRec.battleAttrRateList,
		_isBattleMail = true,
	}
	local mail = createMail(oci)
	mail:saveToDB()
	allMailTbl[mailId] = mail
	loadedTbl[mailId] = true
	return mailId
end

function sliceGetSvrMail(ulist, pro, paramTbl)
	local userId = ulist[pro]
	tryGetSvrMail(userId)
end

function onUserLogin(user)
	local userId = user:getUserId()
	tryInitUserMailInfo(userId)
	tryGetSvrMail(userId)
end

local function checkMailRewardOverLimit(userId, mailKind, mailId)
	local userMailInfo = getUserMailInfo(userId, mailKind, mailId)
	if not userMailInfo then
		return false
	end
	local mail = tryInitMail(mailId)
	if not mail then
		return false
	end
	local rewardItemTbl = {}
	for _, rewardInfo in pairs(mail:getRewardList()) do
		if rewardInfo.reward_type == CONST.REWARD_TYPE_ITEM then
			local itemType = rewardInfo.item_type
			rewardItemTbl[itemType] = (rewardItemTbl[itemType] or 0) + rewardInfo.item_count
		end
	end
	for itemType, rewardItemCnt in pairs(rewardItemTbl) do
		local limitAddCnt = ITEM_MGR.getLimitAddCnt(userId, itemType)
		if limitAddCnt and rewardItemCnt > limitAddCnt then
			return true
		end
	end
	return false
end

local function tryGetMailReward(userId, mailKind, mailId)
	local userMailInfo = getUserMailInfo(userId, mailKind, mailId)
	if not userMailInfo then
		return false
	end
	if not userMailInfo.isRead then
		setMailReaded(userId, mailKind, mailId)
	end
	if userMailInfo.isGotReward then
		return false
	end
	local mail = tryInitMail(mailId)
	if not mail then
		return false
	end
	setMailRewarded(userId, mailKind, mailId)
	local actualRwdList = REWARD_MGR.rewardUser(userId, mail:getRewardList(), {CONST.FLOW_REASON.MAIL, mail:getMailType()})
	return true, actualRwdList
end

local function tryDelUserMailByKind(userId, mailKind)
	local mailTbl = getUserMailByKind(userId, mailKind)
	if not mailTbl then
		return
	end
	local delMailTbl = {}
	local mailList = {}
	local queryMailIdList = {}
	for mailId, info in pairs(mailTbl) do
		if not info.isLock then
			table.insert(queryMailIdList, mailId)
		end
	end
	local queryMailTbl = tryInitMailTbl(queryMailIdList)
	for mailId, mail in pairs(queryMailTbl) do
		if mail:isTimeout(mailId) then
			delMailTbl[mailId] = true
		else
			table.insert(mailList, mail)
		end
	end
	local limitCnt = DATA_COMMON.getValueByKey(3)
	local needDelCnt = #mailList - limitCnt
	if needDelCnt <= 0 then
		return
	end
	table.sort(mailList, function(mail1, mail2)
		return mail1:getStartTime() < mail2:getStartTime()
	end)
	for _, mail in ipairs(mailList) do
		local mailId = mail:getMailId()
		delMailTbl[mailId] = true
		needDelCnt = needDelCnt - 1
		if needDelCnt <= 0 then
			break
		end
	end
	local delList = {}
	for mailId in pairs(delMailTbl) do
		tryGetMailReward(userId, mailKind, mailId)
		delUserMail(userId, mailKind, mailId)
		table.insert(delList, mailId)
	end
	local vfd = USER_MGR.getVfdByUserId(userId)
	if vfd then
		for_caller.s2c_del_mail_list(vfd, mailKind, delList)
	end
end

function tryDelMailById(delMailId)
	if not mailRefTbl[delMailId] then
		return
	end
	for idx, mailId in pairs(svrMailInfo.svrMailTbl) do
		if mailId == delMailId then
			delSvrMail(idx)
			if not mailRefTbl[delMailId] then
				return
			end
		end
	end
	for userId, userInfo in pairs(userMailInfoTbl) do
		for mailKind, mailTbl in pairs(userInfo.mailTbl) do
			if mailTbl[delMailId] then
				delUserMail(userId, mailKind, delMailId)
				local vfd = USER_MGR.getVfdByUserId(userId)
				if vfd then
					for_caller.c_del_mail_list(vfd, mailKind, {delMailId})
				end
				if not mailRefTbl[delMailId] then
					return
				end
			end
		end
	end
end

function sendUserMail(userId, mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec, mailAvatarType)
	local mailId = createNewMail(mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec, mailAvatarType)
	putMailToUserAndSync(userId, mailKind, mailId)
	tryDelUserMailByKind(userId, mailKind)
	return mailId
end

function sendSrvMail(mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec, mailAvatarType)
	local mailId = createNewMail(mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec, mailAvatarType)
	addSvrMail(mailId)
	local userIdList = COMMON_FUNC.getTblValueList(USER_MGR.getVfdUserIdTbl())
	SLICE_TASK.sliceFuncNoSave("MAIL_MGR", "sliceGetSvrMail", userIdList, 30)
	tryClearSvrMail()
	return mailId
end

function sendGroupMail(userIdTbl, mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec, mailAvatarType)
	local mailId = createNewMail(mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec, mailAvatarType)
	for userId, _ in pairs(userIdTbl) do
		putMailToUserAndSync(userId, mailKind, mailId)
		tryDelUserMailByKind(userId, mailKind)
	end
	return mailId
end

function sendBattleMail(userIdTbl, mailKind, mailType, title, contentTbl, detailTbl, rewardList, mailBattleRec, lifeSec, mailAvatarType)
	local mailId = createNewBattleMail(mailKind, mailType, title, contentTbl, detailTbl, rewardList, mailBattleRec, lifeSec, mailAvatarType)
	for userId, _ in pairs(userIdTbl) do
		putMailToUserAndSync(userId, mailKind, mailId)
		tryDelUserMailByKind(userId, mailKind)
	end
end

local function onReqMailList(vfd, mailKind)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	tryDelUserMailByKind(userId, mailKind)
	local list = {}
	local tbl = getUserMailByKind(userId, mailKind)
	if tbl then
		for mailId, _ in pairs(tbl) do
			table.insert(list, genMailSimPto(userId, mailKind, mailId))
		end
	end
	for_caller.c_req_mail_list(vfd, mailKind, list)
end

local function onReqMailDetail(vfd, mailKind, mailId)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	local tbl = getUserMailByKind(userId, mailKind)
	if tbl and tbl[mailId] then
		setMailReaded(userId, mailKind, mailId)
		local mail = tryInitMail(mailId)
		mail:syncDetail(vfd, userId)
	end
end

local function onReqUnreadCntList(vfd)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	local mailTbl = getUserMailTbl(userId)
	local list = {}
	for mailKind, tbl in pairs(mailTbl) do
		local unreadCnt = 0
		for _, info in pairs(tbl) do
			if not info.isRead then
				unreadCnt = unreadCnt + 1
			end
		end
		table.insert(list, { k = mailKind, v = unreadCnt, })
	end
	for_caller.c_req_unread_mail_cnt_list(vfd, list)
end

local function tryDelMail(userId, mailKind, mailId, info)
	if info.isLock then
		return false
	end
	if not info.isGotReward then
		return false
	end
	tryInitMail(mailId)
	delUserMail(userId, mailKind, mailId)
	return true
end

local function onDelMailList(vfd, mailKind, mailIdList)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	local tbl = getUserMailByKind(userId, mailKind)
	if not tbl then
		return
	end
	local delMailIdList = {}
	for _, mailId in pairs(mailIdList) do
		local info = tbl[mailId]
		if info then
			if tryDelMail(userId, mailKind, mailId, info) then
				table.insert(delMailIdList, mailId)
			end
		end
	end
	for_caller.s2c_del_mail_list(vfd, mailKind, delMailIdList)
end

local function onSetMailLock(vfd, mailKind, mailId, isLock)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	local tbl = getUserMailByKind(userId, mailKind)
	local info = tbl and tbl[mailId]
	if info and info.isLock ~= isLock then
		if isLock then
			local mail = tryInitMail(mailId)
			if not mail:canLock() then
				return
			end
		end
		setMailLock(userId, mailKind, mailId, isLock)
		for_caller.c_set_mail_lock(vfd, mailKind, mailId, isLock)
	end
end

local function onGetMailReward(vfd, mailKindIdList)
	local userId = USER_MGR.getUserIdByVfd(vfd)
	local allRewardList = {}
	local rewardMailIdList = {}
	for _, info in pairs(mailKindIdList) do
		local mailKind = info.k
		local mailId = info.v
		if checkMailRewardOverLimit(userId, mailKind, mailId) then
			USER_MGR.tellMeByLanguageId(userId, 110277)
		else
			local ret, rewardList = tryGetMailReward(userId, mailKind, mailId)
			if ret then
				table.insert(allRewardList, rewardList)
				table.insert(rewardMailIdList, mailId)
			end
		end
	end
	local showRewardList = FUNCLIB.mergeRewardList(table.unpack(allRewardList))
	REWARD_MGR.showReward(userId, showRewardList)
	for_caller.c_get_mail_reward(vfd, rewardMailIdList)
end

function __init__()
	for_maker.c2s_req_mail_list = onReqMailList
	for_maker.c2s_req_mail_detail = onReqMailDetail
	for_maker.c2s_req_unread_mail_cnt_list = onReqUnreadCntList
	for_maker.c2s_del_mail_list = onDelMailList
	for_maker.c2s_set_mail_lock = onSetMailLock
	for_maker.c2s_get_mail_reward = onGetMailReward
end