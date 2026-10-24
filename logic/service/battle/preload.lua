local DOFILE_LIST = {
	"../logic/service/battle/global.lua",
}

local function init_dofile()
	for _, file_info in ipairs(DOFILE_LIST) do
		dofile(file_info)
	end
	math.randomseed(os.time())
end

init_dofile()
