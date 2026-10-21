local protobuf = require "protobuf"
local DOFILE_LIST = {
	"../logic/service/gated/global.lua",
}

local PROTO_FILE_LIST = {
	"../game_common/pb/login.pb",
}

local function system_start_up()	
end

local function init_dofile()
	for _, file_info in ipairs(DOFILE_LIST) do
		dofile(file_info)
	end
	for _, proto_file in ipairs(PROTO_FILE_LIST) do
		protobuf.register_file(proto_file)
	end
	math.randomseed(os.time())
	-- 这里预加载数据，比如登录的时候拉取账号对应的tbl
	system_start_up()
end

init_dofile()

