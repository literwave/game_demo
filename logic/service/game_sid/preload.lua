local DOFILE_LIST = {
	"../logic/service/game_sid/global.lua",
}

local function system_start_up()
	MONGO_SLAVE.system_startup()
end

local function init_dofile()
	for _, file_info in ipairs(DOFILE_LIST) do
		dofile(file_info)
	end
	system_start_up()
end

init_dofile()

