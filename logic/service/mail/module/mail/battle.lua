
local save_field_tbl = {
	_result = function()
		return {}
	end,
	_user_rec_tbl = function()
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
	_camp_rec_tbl = function()
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
	_soldier_rec_list = function()
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
	_hero_info_list = function()
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
	_battle_attr_rate_list = function()
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

cls_mail = MAIL_BASE.cls_mail:Inherit()

function cls_mail:__init__(oci)
	Super(cls_mail).__init__(self, oci)
	for k, func in pairs(save_field_tbl) do
		if oci[k] == nil then
			self[k] = func()
		else
			self[k] = oci[k]
		end
	end
end

function cls_mail:serialize(tbl)
	Super(cls_mail).serialize(self, tbl)
	for key, _ in pairs(save_field_tbl) do
		tbl[key] = self[key]
	end
end

function cls_mail:sync_detail(vfd, mail_user_id)
	Super(cls_mail).sync_detail(self, vfd)
	local user_camp = self._user_rec_tbl[mail_user_id].camp
	local user_rec_list = {}
	local camp_rec_list = {}
	for camp, info in pairs(self._camp_rec_tbl) do
		local user_id = info.userId
		local user_info = self._user_rec_tbl[user_id]
		if user_info then
			table.insert(user_rec_list, {
				userId = user_id,
				camp = user_info.camp,
				name = user_info.name,
				icon = user_info.icon,
				union_name = user_info.union_name,
			})
		end
		table.insert(camp_rec_list, {
			gx = info.gx,
			gz = info.gz,
			camp = camp,
			init_s_cnt = info.init_s_cnt,
			alive_s_cnt = info.alive_s_cnt,
			immunity_s_cnt = info.immunity_s_cnt,
			hurt_s_cnt = info.hurt_s_cnt,
			dead_s_cnt = info.dead_s_cnt,
			loss_soldiers_power = info.loss_soldiers_power,
		})
	end
	for_caller.c_req_mail_battle_rec(vfd, self._mail_id, self._result, user_camp, user_rec_list, camp_rec_list)
end

function cls_mail:sync_battle_rec_detail(vfd)
	local user_rec_list = {}
	for user_id, info in pairs(self._user_rec_tbl) do
		table.insert(user_rec_list, {
			userId = user_id,
			camp = info.camp,
			name = info.name,
			icon = info.icon,
			union_name = info.union_name,
		})
	end
	for_caller.s2c_req_mail_battle_rec_detail(vfd, self._mail_id, user_rec_list, self._soldier_rec_list, self._hero_info_list, self._battle_attr_rate_list)
end

