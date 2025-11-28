local define = {
    Heartbeat = {
        c2sheartbeat = 256,
        s2cheartbeat = 257
    },
    Chat = {
        c2sChat = 258,
        s2cChat = 259
    },
    Login = {
        c2splaylogin = 260,
        s2cplaylogin = 261,
        s2cplaycreate = 262,
        s2cplayloginok = 263
    },
    Hero = {
        s2csyncherobaseinfo = 264
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
