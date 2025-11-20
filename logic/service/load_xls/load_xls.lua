local skynet = require "skynet"
local sharedata = require "skynet.sharedata"
local CONFIG_PATH = skynet.getenv("config_path")
local CMD = {}

local lfs = require "lfs"

FILE_MODIFY_TIME_TBL = {
	-- [filename] = modification
}

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

-- 待做，类似于协议初始化
skynet.start(function()
	for file in lfs.dir (CONFIG_PATH) do
		local temdata = require (CONFIG_PATH .. file)
		sharedata.new(file, temdata)
		local filename = file:sub(1, -5)
		local fileAttr = lfs.attributes(CONFIG_PATH .. file)
		FILE_MODIFY_TIME_TBL[filename] = fileAttr.modification
        end
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		assert(CMD[cmd])
		local f = CMD[cmd]
		f()
	end)
end)
