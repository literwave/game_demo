
local saveFieldTbl = {
	_mailId = function()
		return nil
	end,
	_mailKind = function()
		return nil
	end,
	_mailType = function()
		return nil
	end,
	_startTime = function()
		return nil
	end,
	_endTime = function()
		return nil
	end,
	_title = function()
		return nil
	end,
	_contentTbl = function()
		return nil
	end,
	_detailList = function()
		return {}
	end,
	_rewardList = function()
		return {}
	end,
	_isBattleMail = function()
		return false
	end,
}

clsMail = clsObject:Inherit()

function clsMail:__init__(oci)
	Super(clsMail).__init__(self, oci)
	for k, func in pairs(saveFieldTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
	assert(self._mailKind)
	assert(self._mailType)
end

function clsMail:release()
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.MAIL_COL, self._mailId}, nil)
	Super(clsMail).release(self)
end

function clsMail:serialize(tbl)
	for key, _ in pairs(saveFieldTbl) do
		tbl[key] = self[key]
	end
end

function clsMail:saveField(keyList, val)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.MAIL_COL, self._mailId, unpack(keyList)}, val)
end

function clsMail:saveToDB()
	local info = {}
	self:serialize(info)
	MONGO_SLAVE.opMongoValue({MONGO_SLAVE.MAIL_COL, self._mailId}, info)
end

function clsMail:getDetail()
	return self._detailTbl
end

function clsMail:getEndTime()
	return self._endTime
end

function clsMail:getRewardList()
	return self._rewardList
end

function clsMail:getMailId()
	return self._mailId
end

function clsMail:getMailAvatarType()
	return self._mailAvatarType or 0
end

function clsMail:genContentStr()
	return COMMON_FUNC.serialize(self._contentTbl)
end

function clsMail:genShareContentStr()
	local shareContentTbl = COMMON_FUNC.table_deepcopy(self._contentTbl)
	local mailInfo = DATA_COMMON.getMailInfo(self._mailType)
	if shareContentTbl.text and mailInfo and mailInfo.ShareDes then
		shareContentTbl.text[1] = mailInfo.ShareDes
	end
	return COMMON_FUNC.serialize(shareContentTbl)
end

function clsMail:getDetailList()
	return self._detailList
end

function clsMail:getMailKind()
	return self._mailKind
end

function clsMail:getMailType()
	return self._mailType
end

function clsMail:getStartTime()
	return self._startTime
end

function clsMail:isTimeout()
	if self._endTime == -1 then
		return false
	end
	return self._endTime < TIME.osBJSec()
end

function clsMail:getTitle()
	return self._title
end

function clsMail:syncDetail(vfd)
	local ptoTbl = {
		mailId = self:getMailId(),
		rewardList = self:getRewardList(),
		detailList = self:getDetailList(),
	}
	for_caller.c_req_mail_detail(vfd, ptoTbl)
end

function clsMail:canLock()
	return DATA_COMMON.canLockMail(self:getMailType())
end
