DOFILE_LIST = {
	"../logic/base/import.lua",
	"../logic/base/common_class.lua",
	"../logic/base/class.lua",
	"../proto/netPb.lua",
	"../logic/base/extend.lua",
	"../logic/base/global.lua",
	"../logic/base/time.lua",
	"../logic/game.lua",
}

function initGame()
	for _, fileInfo in ipairs(DOFILE_LIST) do
	    dofile(fileInfo)
	end
end

initGame()
