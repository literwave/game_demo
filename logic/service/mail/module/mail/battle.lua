
local saveFieldTbl = {
	_result = function()
		return {}
	end,
	_userRecTbl = function()
		return {}
		--[[
			[userId] = {
				camp = *,
				icon = *,
				name = *,
				unionName = *,
			}
		--]]
	end,
	_campRecTbl = function()
		return {}
		--[[
			[camp] = {
				userId = *,
				gx = *,
				gz = *,
				initSCnt = *,
				aliveSCnt = *,
				immunitySCnt = *,
				hurtSCnt = *,
				deadSCnt = *,
				lossSoldiersPower = *,
			}
		--]]
	end,
	_soldierRecList = function()
		return {}
		--[[
			[1] = {
				userId = *,
				soldierType = *,
				initSCnt = *,
				aliveSCnt = *,
				immunitySCnt = *,
				hurtSCnt = *,
				deadSCnt = *,
				killSCnt = *,
				camp = *,
				forceId = *,
			}
		--]]
	end,
	_heroInfoList = function()
		return {}
		--[[
			[1] = {
				camp = *,
				idx = *,
				heroType = *,
				lv = *,
				starRank = *,
				equipInfoList = {
					[1] = {
						pos = *,
						itemType = *,
						strengthenLv = *,
						forgeLv = *,
					},
				},
				swordLevel = *,
			},
		--]]
	end,
	_battleAttrRateList = function()
		return {}
		--[[
			[1] = {
				camp = *,
				attrType = *,
				soldierKind = *,
				rateList = {
					[1] = {
						source = *,
						rate = *,
					}
				},
			},
		--]]
	end,
}

clsMail = MAIL_BASE.clsMail:Inherit()

function clsMail:__init__(oci)
	Super(clsMail).__init__(self, oci)
	for k, func in pairs(saveFieldTbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
end

function clsMail:serialize(tbl)
	Super(clsMail).serialize(self, tbl)
	for key, _ in pairs(saveFieldTbl) do
		tbl[key] = self[key]
	end
end

function clsMail:syncDetail(vfd, mailUserId)
	Super(clsMail).syncDetail(self, vfd)
	local userCamp = self._userRecTbl[mailUserId].camp
	local userRecList = {}
	local campRecList = {}
	for camp, info in pairs(self._campRecTbl) do
		local userId = info.userId
		local userInfo = self._userRecTbl[userId]
		if userInfo then
			table.insert(userRecList, {
				userId = userId,
				camp = userInfo.camp,
				name = userInfo.name,
				icon = userInfo.icon,
				unionName = userInfo.unionName,
			})
		end
		table.insert(campRecList, {
			gx = info.gx,
			gz = info.gz,
			camp = camp,
			initSCnt = info.initSCnt,
			aliveSCnt = info.aliveSCnt,
			immunitySCnt = info.immunitySCnt,
			hurtSCnt = info.hurtSCnt,
			deadSCnt = info.deadSCnt,
			lossSoldiersPower = info.lossSoldiersPower,
		})
	end
	for_caller.c_req_mail_battle_rec(vfd, self._mailId, self._result, userCamp, userRecList, campRecList)
end

function clsMail:syncBattleRecDetail(vfd)
	local userRecList = {}
	for userId, info in pairs(self._userRecTbl) do
		table.insert(userRecList, {
			userId = userId,
			camp = info.camp,
			name = info.name,
			icon = info.icon,
			unionName = info.unionName,
		})
	end
	for_caller.s2c_req_mail_battle_rec_detail(vfd, self._mailId, userRecList, self._soldierRecList, self._heroInfoList, self._battleAttrRateList)
end

