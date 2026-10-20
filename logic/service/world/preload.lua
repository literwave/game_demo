local skynet = require "skynet"
local protobuf = require "protobuf"

local DOFILE_LIST = {
	"../logic/service/world/global.lua",
}

local PROTO_FILE_LIST = {
	"../game_common/pb/common.pb",
}

local function encodePack(msg, id, name)
	local packData = string.pack(">I2", id) .. protobuf.encode(name, msg)
	packData = string.pack(">I2", #packData) .. packData
	return packData
end

local function initDofile()
	for _, fileInfo in ipairs(DOFILE_LIST) do
		dofile(fileInfo)
	end
	for _, protoFile in ipairs(PROTO_FILE_LIST) do
		protobuf.register_file(protoFile)
	end
	local function createSendMessage(id, packName)
		return function(fd, data)
			skynet.error(id, packName)
			local gateSrv = USER_MGR.getGateSrvByFd(fd)
			skynet.send(gateSrv, "lua", "sendClientPack", fd, encodePack(data, id, packName))
		end
	end
	for ptoName, id in pairs(PTONAME_TO_ID) do
		for_caller[ptoName] = createSendMessage(id, ID_TO_PACK_NAME[id])
	end
	math.randomseed(os.time())
	MAP_MGR.init()
end

initDofile()
