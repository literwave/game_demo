local skynet = require "skynet"
local protobuf = require "protobuf"

local DOFILE_LIST = {
	"../logic/service/world/global.lua",
}

local PROTO_FILE_LIST = {
	"../game_common/pb/common.pb",
}

local function encode_pack(msg, id, name)
	local pack_data = string.pack(">I2", id) .. protobuf.encode(name, msg)
	pack_data = string.pack(">I2", #pack_data) .. pack_data
	return pack_data
end

local function init_dofile()
	for _, file_info in ipairs(DOFILE_LIST) do
		dofile(file_info)
	end
	for _, proto_file in ipairs(PROTO_FILE_LIST) do
		protobuf.register_file(proto_file)
	end
	local function create_send_message(id, pack_name)
		return function(fd, data)
			if pack_name ~= "Heartbeat.s2c_heart_beat" then
				skynet.error(id, pack_name)
			end
			local gate_srv = USER_MGR.get_gate_srv_by_fd(fd)
			skynet.send(gate_srv, "lua", "send_client_pack", fd, encode_pack(data, id, pack_name))
		end
	end
	for pto_name, id in pairs(PTONAME_TO_ID) do
		for_caller[pto_name] = create_send_message(id, ID_TO_PACK_NAME[id])
	end
	math.randomseed(os.time())
	MAP_MGR.init()
	AOI_MGR.init()
end

init_dofile()
