local define = {
    Reward = {
        s2c_show_reward = 256
    },
    Heartbeat = {
        c2s_heart_beat = 257,
        s2c_heart_beat = 258
    },
    Chat = {
        c2sChat = 259,
        s2cChat = 260
    },
    Login = {
        c2s_user_login = 261,
        s2c_user_login = 262,
        s2c_user_create = 263,
        s2c_user_login_ok = 264
    },
    Hero = {
        s2c_sync_hero_base_info = 265
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
