local protobuf = require "protobuf"

local DOFILE_LIST = {
	"../logic/service/logind/global.lua",
}

local PROTO_FILE_LIST = {
	"../proto/pb/login.pb",
}

local function systemStartUp()
	MONGO_SLAVE.systemStartUp()
	LREDIS.systemStartUp()
end

local function initDofile()
	for _, fileName in ipairs(DOFILE_LIST) do
		dofile(fileName)
	end
	for _, protoFile in ipairs(PROTO_FILE_LIST) do
		protobuf.register_file(protoFile)
	end
	math.randomseed(TIME.osBJSec())
	systemStartUp()
end

initDofile()