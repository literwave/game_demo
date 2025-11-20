---        filename preload
-------    @author  xiaobo
---        date 2023/05/28/18/06/39

DOFILE_LIST = {
	"../logic/base/import.lua",
	"../logic/base/common_class.lua",
	"../logic/base/class.lua",
	"../logic/base/netPb.lua",
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
