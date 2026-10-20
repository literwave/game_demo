local skynet = require "skynet"
local sharedata = require "skynet.sharedata"
local CONFIG_PATH = skynet.getenv("config_path")
local CMD = {}

FILE_MODIFY_TIME_TBL = {
	-- [filename] = modification
}

-- 星图导出的表是 { {Id=...}, ... }，业务按 Id 取值，加载时转成 [Id] = row。
-- 不是这种形状的表（例如内城布局）原样放进 sharedata。
local function indexById(data)
	local first = data[1]
	if type(first) ~= "table" or first.Id == nil then
		return data
	end
	local indexed = {}
	for _, row in ipairs(data) do
		if type(row) == "table" and row.Id ~= nil then
			indexed[row.Id] = row
		end
	end
	return indexed
end

local function loadConfig(path)
	local chunk, err = loadfile(path)
	if not chunk then
		error(string.format("load config failed: %s (%s)", path, tostring(err)))
	end
	local data = chunk()
	assert(type(data) == "table", "config must return a table: " .. path)
	return indexById(data)
end

-- 这里先这样手动加载数据，后续优化成遍历dir目录下的文件，然后new
DATA_FILE_LIST = {
	"../game_common/server/res/Hero.lua",
	"../game_common/server/res/ReportInfo.lua",
	"../game_common/server/res/ServerGroup.lua",
	"../game_common/server/res/Global.lua",
	"../game_common/server/res/BuildingDetail.lua",
	"../game_common/server/res/BuildingLv.lua",
	"../game_common/server/res/HeadIcon.lua",
	"../game_common/server/res/Item.lua",
	"../game_common/server/res/Lottery.lua",
	"../res/innerCity.lua",
}

function CMD.shutdown()
	skynet.exit()
end

function CMD.hotUpdate()
	for file in lfs.dir(CONFIG_PATH) do
		local filename = file:sub(1, -5)
		local fileAttr = lfs.attributes(CONFIG_PATH .. file)
		if not FILE_MODIFY_TIME_TBL[filename] then
			local temdata = loadConfig(CONFIG_PATH .. file)
			sharedata.new(filename, temdata)
			FILE_MODIFY_TIME_TBL[filename] = fileAttr.modification
		else
			local oldModification = FILE_MODIFY_TIME_TBL[filename]
			if oldModification ~= fileAttr.modification then
				local temdata = loadConfig(CONFIG_PATH .. file)
				sharedata.update(filename, temdata)
				FILE_MODIFY_TIME_TBL[filename] = fileAttr.modification
			end
		end
	end
end

local function loadDataFile()
	for _, file in ipairs(DATA_FILE_LIST) do
		local filename = file:match("([^/\\]+)%.lua$")
		assert(filename, "bad config path: " .. tostring(file))
		local data = loadConfig(file)
		sharedata.new(filename, data)
		FILE_MODIFY_TIME_TBL[filename] = os.time()
		skynet.error("sharedata loaded:", filename)
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
