local DOFILE_LIST = {
	"../logic/service/game_sid/global.lua",
}

local function systemStartUp()
	MONGO_SLAVE.systemStartup()
end

local function initDofile()
	for _, fileInfo in ipairs(DOFILE_LIST) do
		dofile(fileInfo)
	end
	systemStartUp()
end

initDofile()

