local skynet = require "skynet"
local sharedata = require "skynet.sharedata"
local CONFIG_PATH = skynet.getenv("config_path")
local CMD = {}

FILE_MODIFY_TIME_TBL = {
	-- [filename] = modification
}

-- 这里先这样手动加载数据，后续优化成遍历dir目录下的文件，然后new
DATA_FILE_LIST = {
	"../read_config/Hero.lua",
	"../read_config/ReportInfo.lua",
	"../read_config/ServerGroup.lua",
	"../read_config/Global.lua",
	"../read_config/HeroDebris.lua",
	"../read_config/Resource.lua",
}

function CMD.shutdown()
	skynet.exit()
end

function CMD.hotUpdate()
	for file in lfs.dir (CONFIG_PATH) do
		local filename = file:sub(1, -5)
		local fileAttr = lfs.attributes(CONFIG_PATH .. file)
		if not FILE_MODIFY_TIME_TBL[filename] then
			local temdata = require (CONFIG_PATH .. file)
			sharedata.new(filename, temdata)
			FILE_MODIFY_TIME_TBL[filename] = fileAttr.modification
		else
			local oldModification = FILE_MODIFY_TIME_TBL[filename]
			if oldModification ~= fileAttr.modification then
				local temdata = require (CONFIG_PATH .. file)
				sharedata.update(filename, temdata)
				FILE_MODIFY_TIME_TBL[filename] = fileAttr.modification
			end
		end
	end
end

local function loadDataFile()
	for _, file in ipairs(DATA_FILE_LIST) do
		local filename = file:match("([^/\\]+)%.lua$")
		local loadData = require(filename)
		sharedata.new(filename, loadData)
		FILE_MODIFY_TIME_TBL[filename] = os.time()
	end
end

-- 待做，类似于协议初始化
skynet.start(function()
	loadDataFile()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		assert(CMD[cmd])
		local f = CMD[cmd]
		f()
	end)
end)
