local skynet = require "skynet"
require "skynet.manager"
local CMD = {}

local SID_VAR_NAME_LIST = {
	"userNumId",
}

GAME_SID_TBL = {}

local GAME_SID_COL_KEY = "1"
local sidData

local function loadGameData()
	local raw = MONGO_SLAVE.commonLoadSingle(MONGO_SLAVE.COL.GAME_SID, GAME_SID_COL_KEY) or {}
	sidData = ORM.create(ORM.CLS_GAME_SID_DATA, raw)
	ORM.bind(sidData, MONGO_SLAVE.COL.GAME_SID, GAME_SID_COL_KEY)
	for _, varName in pairs(SID_VAR_NAME_LIST) do
		_G[varName] = sidData[varName] or 0
	end
	GAME_SID_TBL = {
		userNumId = sidData.userNumId,
	}
end


local function convertToGlobalSID(localId)
	return string.format("%02d%05d%s", GAME.SRV_GROUP_ID, GAME.SERVER_ID, localId)
end

function CMD.fetchUserId()
	userNumId = userNumId + 1
	sidData.userNumId = userNumId
	local userId = convertToGlobalSID(userNumId)
	GAME_SID_TBL.userNumId = userNumId
	return userId
end

function CMD.shutdown()
	skynet.exit()
end

skynet.start(function()
	dofile "../logic/service/game_sid/preload.lua"
	loadGameData()
	skynet.dispatch("lua", function(session, _, cmd, ...)
		local f = CMD[cmd]
			if f then
				local ret = f(...)
				if session ~= 0 then
					skynet.ret(skynet.pack(ret))	
				end
			else
				skynet.error("no callback")
			end
	end)
	skynet.register(".game_sid")
end)