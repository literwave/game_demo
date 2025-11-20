
function isInternalServer()
	return CONST.TEST_SERVER_GROUP_TBL[GAME.SRV_GROUP_ID]
end

function getNextRefreshLeftTime(refreshTimeList)
	local minLeftTime = nil
	for i, info in ipairs(refreshTimeList) do
		local leftTime = TIME.getDeltaSecToTime(info.hour, info.min, info.sec)	
		if (not minLeftTime) or (minLeftTime > leftTime) then
			minLeftTime = leftTime
		end
	end
	return minLeftTime
end

function checkContainIllegalChar(name)
	return string.find(name, "[@%.$%s]")
end

function convertMD5ToHex(md5_code)
        local sign_tbl = {}
        local len = string.len(md5_code)
        for i = 1, len do
                local s = string.sub(md5_code, i, i)                                                                         
                table.insert(sign_tbl, string.format("%02x", string.byte(s)))                                                
        end 
        return table.concat(sign_tbl)
end

function getStrMD5(str, toUpper)
        local md5Str = convertMD5ToHex(lmd5_sum.md5_sum(str, string.len(str)))                                               
        if toUpper then
                return string.upper(md5Str)                                                                                  
        else        
                return md5Str
        end         
end

-- local accType2Prefix = {
-- 	[COMMON_CONST.LOGIN_ACCOUNT_TYPE.RASTAR_ANDROID] = "ML_RASTAR",
-- 	[COMMON_CONST.LOGIN_ACCOUNT_TYPE.WX_MINI_PROGRAM] = "ML_WX",
-- }

function genSdkLoginAccount(accountType, account)
	if accountType == COMMON_CONST.LOGIN_ACCOUNT_TYPE.NONE then
		return account
	end
	local preFix = accType2Prefix[accountType]
	return string.format("%s_%s", preFix, account)
end

function genSdkLoginAccountTblByOpenId(openId)
	local accTbl = {}
	for _, accountType in pairs(COMMON_CONST.LOGIN_ACCOUNT_TYPE) do
		accTbl[genSdkLoginAccount(accountType, openId)] = true
	end
	return accTbl
end

function getSdkOrgOpenId(account)
	local openId = account
	local pos = string.find(account, "_")
	if pos then
		openId = string.sub(account, pos + 1)
	end
	return openId
end

function checkEnumValid(value)
	local reasonTbl = {}
	for k, reason in pairs(value) do
		if reasonTbl[reason] then
			return false
		end
		reasonTbl[reason] = k
	end
	return true
end

function checkTblEqual(tbl1, tbl2, depth)
	depth = (depth or 0) + 1
	assert(depth < 100)
	if type(tbl1) ~= "table" then
		return tbl1 == tbl2
	end
	if type(tbl1) ~= type(tbl2) then
		return false
	end
	for k, v in pairs(tbl1) do
		if not checkTblEqual(v, tbl2[k], depth) then
			return false
		end
	end
	for k, v in pairs(tbl2) do
		if not checkTblEqual(v, tbl1[k], depth) then
			return false
		end
	end
	return true
end

function calFormationPower(userId, formation)
	local formationPower = 0
	for slot, heroType in pairs(formation) do
		local hero = HERO_MGR.getHeroByType(userId, heroType)
		formationPower = formationPower + hero:getHeroPower()
	end
	return formationPower
end

