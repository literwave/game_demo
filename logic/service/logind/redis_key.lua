all_key_list = {}
all_key_tbl = {}
all_key_name_tbl = {}

-- 设计思路，colName就是这个模块的变量，这样就不用写枚举字符串了，
-- 这里应该是写在单个agent里的，不应该写在common模块里的，
-- 
local key_desc_tbl = {
	{
		key = "ACCOUNT_INFO_KEY",
		key_name = "account_info_key",
	},
}

local function try_init_key_list()
	if next(all_key_list) then
		assert(false)
	end
	local env = getfenv(1)
	for _, info in ipairs(key_desc_tbl) do
		table.insert(all_key_list, {
			key_name = info.key_name,
		})
		env[info.key] = info.key_name
	end
	for _, key_info in pairs(all_key_list) do
		local key_name = key_info.key_name
		assert(not all_key_name_tbl[key_name])
		all_key_name_tbl[key_name] = true
	end
	assert(next(all_key_list))
end

function system_start_up()
	try_init_key_list()
	LREDIS.try_init_redis_con()
end