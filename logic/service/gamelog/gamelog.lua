local skynet = require "skynet"
require "skynet.manager"
local logPath = skynet.getenv("logpath")
-- local cjson = require "cjson"

local CMD = {}

-- 警告日志
local function writefile(pfile, mod, args)
	if not mod then mod = "a+" end
	local argsStr = table2str(args)
	-- todo
	if type(args) == "table" then
		argsStr = table2str(args)
	else
		args = table.pack(args)
		for i = 1, args.n do
			args[i] = tostring(args[i])
		end
		argsStr = table.concat(args, " ")
	end
	local fileName = logPath .. "/" .. "common_error_"..os.date("%Y%m%d")..".txt"
	local file = io.open(fileName, mod);
	local writeStr = pfile..argsStr
	file:write(writeStr .. "\n");
	file:close();
end

function CMD.writefile(level, pfile, args)
	writefile(pfile, nil, args)
end

function CMD.info(msg)
	log(msg)
end

function CMD.error(msg)
	log(msg)
end

function CMD.shutdown()
	skynet.exit()
end

skynet.start(function()
	-- 日志服务
	local function log_init()
		math.randomseed(os.time());
	end
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
