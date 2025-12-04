local define = {
    Reward = {
        s2c_show_reward = 256,
        s2c_sync_user_diamond = 257
    },
    Heartbeat = {
        c2s_heart_beat = 258,
        s2c_heart_beat = 259
    },
    Chat = {
        c2sChat = 260,
        s2cChat = 261
    },
    Login = {
        c2s_user_login = 262,
        s2c_user_login = 263,
        s2c_user_create = 264,
        s2c_user_login_ok = 265
    },
    Hero = {
        s2c_sync_hero_base_info = 266
    }
}
ID_TO_PACK_NAME = {}
PTONAME_TO_ID = {}
ID_TO_PTONAME = {} -- 这里需要优化，其实就只有客户端发给后端才需要这个数据
for_maker = {}
for_caller = {}
	
local function initPto()
	for mod, packTbl in pairs(define) do
		for ptoName, id in pairs(packTbl) do
			local packName = mod .. "." .. ptoName
			ID_TO_PACK_NAME[id] = packName
			PTONAME_TO_ID[ptoName] = id
		end
	end
end

initPto()
