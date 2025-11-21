local define = {
    Chat = {
        c2sChat = 256,
        s2cChat = 257
    },
    Login = {
        c2splaylogin = 258,
        s2cplaylogin = 259,
        s2cplaycreate = 260,
        s2cplayloginok = 261
    },
    Test = {
        c2sTest = 262,
        s2cTest = 263
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
