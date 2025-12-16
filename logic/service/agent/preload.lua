local skynet = require "skynet"
local protobuf = require "protobuf"

local DOFILE_LIST = {
	"../logic/service/agent/global.lua",
}

local PROTO_FILE_LIST = {
	"../proto/pb/login.pb",
	"../proto/pb/heartbeat.pb",
	"../proto/pb/hero.pb",
	"../proto/pb/reward.pb",
	"../proto/pb/build.pb",
}

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
			local gateSrv = USER_MGR.getGateSrvByFd(fd)
			skynet.send(gateSrv, "lua", "sendClientPack", fd, encodePack(data, id, packName))
		end
	end
	for ptoName, id in pairs(PTONAME_TO_ID) do
		for_caller[ptoName] = createSendMessage(id, ID_TO_PACK_NAME[id])
	end
	math.randomseed(os.time())
	-- 这里预加载数据，比如登录的时候拉取账号对应的tbl
	systemStartUp()
end

initDofile()

