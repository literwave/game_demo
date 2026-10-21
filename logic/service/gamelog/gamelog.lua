local skynet = require "skynet"
require "skynet.manager"
local log_path = skynet.getenv("logpath")
-- local cjson = require "cjson"

local CMD = {}

-- 警告日志
local function writefile(pfile, mod, args, file_name)
	if not mod then mod = "a+" end
	local args_str = table2str(args)
	-- todo
	if type(args) == "table" then
		args_str = table2str(args)
	else
		args = table.pack(args)
		for i = 1, args.n do
			args[i] = tostring(args[i])
		end
		args_str = table.concat(args, " ")
	end
	local file, err = io.open(file_name, mod)
	if not file then
		os.execute(string.format("mkdir -p %q", log_path))
		file, err = io.open(file_name, mod)
	end
	local write_str = pfile..args_str
	print(write_str)
	if not file then
		skynet.error("gamelog open failed", file_name, err)
		return
	end
	file:write(write_str .. "\n")
	file:close()
end

function CMD.writefile(level, pfile, args)
	local file_name = log_path .. "/" .. "common_"..level.."_"..os.date("%Y%m%d")..".log"
	writefile(pfile, nil, args, file_name)
end

function CMD.shutdown()
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_, _, cmd, ...)
		local f = CMD[cmd]
			if f then
				f(...)
			else
				skynet.error("no callback")
			end
	end)
	-- 注册服务别名
	skynet.register(".gamelog")
end)
