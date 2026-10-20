local skynet = require "skynet"
local protobuf = require "protobuf"

local DOFILE_LIST = {
	"../logic/service/agent/global.lua",
}

local PROTO_FILE_LIST = {
	"../game_common/pb/common.pb",
	"../game_common/pb/login.pb",
	"../game_common/pb/heartbeat.pb",
	"../game_common/pb/hero.pb",
	"../game_common/pb/reward.pb",
	"../game_common/pb/build.pb",
	"../game_common/pb/user.pb",
	"../game_common/pb/lottery.pb",
	"../game_common/pb/item.pb",
}

function __G__TRACKBACK__(msg)
	print("server lua error", SERVICE_NAME)
	if not LOG then
		print(btInfo)
		return
	end
	LOG._error(btInfo)
	if MONITOR_MGR then
		pcall(MONITOR_MGR.onError, msg, btInfo)
	end
end

local function systemStartUp()
	MONGO_SLAVE.systemStartup()
end

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
	-- 这里要优化一下前端发给后端的协议不需要加载进table
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
	systemStartUp()
end

initDofile()

