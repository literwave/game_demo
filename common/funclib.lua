
function is_internal_server()
	return CONST.TEST_SERVER_GROUP_TBL[GAME.SRV_GROUP_ID]
end

function get_next_refresh_left_time(refresh_time_list)
	local min_left_time = nil
	for i, info in ipairs(refresh_time_list) do
		local left_time = TIME.get_delta_sec_to_time(info.hour, info.min, info.sec)	
		if (not min_left_time) or (min_left_time > left_time) then
			min_left_time = left_time
		end
	end
	return min_left_time
end

function check_contain_illegal_char(name)
	return string.find(name, "[@%.$%s]")
end

function convert_md5_to_hex(md5_code)
        local sign_tbl = {}
        local len = string.len(md5_code)
        for i = 1, len do
                local s = string.sub(md5_code, i, i)                                                                         
                table.insert(sign_tbl, string.format("%02x", string.byte(s)))                                                
        end 
        return table.concat(sign_tbl)
end

function get_str_md5(str, to_upper)
        local md5_str = convert_md5_to_hex(lmd5_sum.md5_sum(str, string.len(str)))                                               
        if to_upper then
                return string.upper(md5_str)                                                                                  
        else        
                return md5_str
        end         
end

-- local accType2Prefix = {
-- 	[COMMON_CONST.LOGIN_ACCOUNT_TYPE.RASTAR_ANDROID] = "ML_RASTAR",
-- 	[COMMON_CONST.LOGIN_ACCOUNT_TYPE.WX_MINI_PROGRAM] = "ML_WX",
-- }

function gen_sdk_login_account(account_type, account)
	if account_type == CONST.LOGIN_ACCOUNT_TYPE.NONE then
		return account
	end
	local pre_fix = acc_type2_prefix[account_type]
	return string.format("%s_%s", pre_fix, account)
end

function gen_sdk_login_account_tbl_by_open_id(open_id)
	local acc_tbl = {}
	for _, account_type in pairs(COMMON_CONST.LOGIN_ACCOUNT_TYPE) do
		acc_tbl[gen_sdk_login_account(account_type, open_id)] = true
	end
	return acc_tbl
end

function get_sdk_org_open_id(account)
	local open_id = account
	local pos = string.find(account, "_")
	if pos then
		open_id = string.sub(account, pos + 1)
	end
	return open_id
end

function check_enum_valid(value)
	local reason_tbl = {}
	for k, reason in pairs(value) do
		if reason_tbl[reason] then
			return false
		end
		reason_tbl[reason] = k
	end
	return true
end

function check_tbl_equal(tbl1, tbl2, depth)
	depth = (depth or 0) + 1
	assert(depth < 100)
	if type(tbl1) ~= "table" then
		return tbl1 == tbl2
	end
	if type(tbl1) ~= type(tbl2) then
		return false
	end
	for k, v in pairs(tbl1) do
		if not check_tbl_equal(v, tbl2[k], depth) then
			return false
		end
	end
	for k, v in pairs(tbl2) do
		if not check_tbl_equal(v, tbl1[k], depth) then
			return false
		end
	end
	return true
end

function merge_reward_list(...)
	local tbl = {}
	for _, reward_list in ipairs({...}) do
		for _, info in pairs(reward_list) do
			if not tbl[info.reward_type] then
				tbl[info.reward_type] = {}
			end
			if not tbl[info.reward_type][info.item_id] then
				tbl[info.reward_type][info.item_id] = 0
			end
			tbl[info.reward_type][info.item_id] = tbl[info.reward_type][info.item_id] + info.item_count
		end
	end
end