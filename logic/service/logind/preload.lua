local protobuf = require "protobuf"

local DOFILE_LIST = {
	"../logic/service/logind/global.lua",
	-- "../logic/service/agent/load_xls.lua",
}

local PROTO_FILE_LIST = {
	"../proto/pb/login.pb",
}

local function systemStartUp()
	MONGO_SLAVE.systemStartup()
end

local function initDofile()
	for _, fileName in ipairs(DOFILE_LIST) do
		dofile(fileName)
	end
	for _, protoFile in ipairs(PROTO_FILE_LIST) do
		protobuf.register_file(protoFile)
	end
	math.randomseed(os.time())
	-- 这里预加载数据，比如登录的时候拉取账号对应的tbl
	systemStartUp()
end

initDofile()