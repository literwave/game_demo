local protobuf = require "protobuf"

local DOFILE_LIST = {
	"../logic/service/logind/global.lua",
}

local PROTO_FILE_LIST = {
	"../game_common/pb/login.pb",
}

local function system_start_up()
	LREDIS.system_start_up()
end

local function init_dofile()
	for _, file_name in ipairs(DOFILE_LIST) do
		dofile(file_name)
	end
	for _, proto_file in ipairs(PROTO_FILE_LIST) do
		protobuf.register_file(proto_file)
	end
	math.randomseed(TIME.os_bj_sec())
	system_start_up()
end

init_dofile()