local DOFILE_LIST = {
	"../logic/service/game_sid/global.lua",
	-- "../logic/service/agent/load_xls.lua",
}

local function initDofile()
	for _, fileInfo in ipairs(DOFILE_LIST) do
		dofile(fileInfo)
	end
end

initDofile()

