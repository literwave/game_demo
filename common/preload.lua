local skynet = require "skynet"

if skynet.PTYPE_RPC == nil then
	skynet.PTYPE_RPC = 13
end

DOFILE_LIST = {
	"../logic/base/import.lua",
	"../logic/base/common_class.lua",
	"../logic/base/class.lua",
	"../game_common/server/net_pb.lua",
	"../logic/base/extend.lua",
	"../logic/base/global.lua",
	"../logic/game.lua",
}

function initGame()
	for _, fileInfo in ipairs(DOFILE_LIST) do
	    dofile(fileInfo)
	end
end

initGame()
