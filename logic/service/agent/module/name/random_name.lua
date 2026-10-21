function get_random_name()
	local language = GAME.get_cur_language()
	local first_name_list = DATA_COMMON.get_first_name_list(language)
	local last_name_list = DATA_COMMON.get_last_name_list(language)
	local first_cnt = #first_name_list
	local last_cnt = #last_name_list
	local first_name_idx = math.random(1, first_cnt)
	local last_name_idx = math.random(1, last_cnt)
	local first_name = first_name_list[first_name_idx].Txt
	local last_name = last_name_list[last_name_idx].Txt
	return string.format("%s%s", last_name, first_name)
end

function gen_new_user_name()
	-- 这里如果重复了咋办, 随机的让他重复吧
	local name = get_random_name()
	if USER_NAME.check_name_exsist(name) then
		return string.format("%s%s", name)
	end
	return name
end
