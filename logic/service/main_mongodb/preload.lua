local DOFILE_LIST = {
	"../logic/service/main_mongodb/global.lua",
}

local function initDofile()
	for _, fileInfo in ipairs(DOFILE_LIST) do
		dofile(fileInfo)
	end
end

initDofile()

