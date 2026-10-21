local skynet = require "skynet"
require "skynet.manager"
local CMD = {}

local SID_VAR_NAME_LIST = {
	"user_num_id",
}

GAME_SID_TBL = {}

local GAME_SID_COL_KEY = "1"
local sid_data

local function load_game_data()
	local raw = MONGO_SLAVE.common_load_single(MONGO_SLAVE.COL.GAME_SID, GAME_SID_COL_KEY) or {}
	sid_data = ORM.create(ORM.CLS_GAME_SID_DATA, raw)
	ORM.bind(sid_data, MONGO_SLAVE.COL.GAME_SID, GAME_SID_COL_KEY)
	for _, var_name in pairs(SID_VAR_NAME_LIST) do
		_G[var_name] = sid_data[var_name] or 0
	end
	GAME_SID_TBL = {
		user_num_id = sid_data.user_num_id,
	}
end


local function convert_to_global_sid(local_id)
	return tonumber(string.format("%02d%05d%d", GAME.SRV_GROUP_ID, GAME.SERVER_ID, local_id))
end

function CMD.fetch_user_id()
	user_num_id = user_num_id + 1
	sid_data.user_num_id = user_num_id
	local user_id = convert_to_global_sid(user_num_id)
	GAME_SID_TBL.user_num_id = user_num_id
	return user_id
end

function CMD.shutdown()
	skynet.exit()
end

skynet.start(function()
	dofile "../logic/service/game_sid/preload.lua"
	load_game_data()
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