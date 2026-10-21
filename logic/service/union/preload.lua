local DOFILE_LIST = {
	"../logic/service/union/global.lua",
}

local function init_dofile()
	for _, file_info in ipairs(DOFILE_LIST) do
		dofile(file_info)
	end
end

init_dofile()
