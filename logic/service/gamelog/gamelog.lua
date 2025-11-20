local skynet = require "skynet"
require "skynet.manager"
local logPath = skynet.getenv("logpath")
-- local cjson = require "cjson"

local CMD = {}

local function table2str(obj, indent)
	indent = indent or 0 -- 当前缩进层级
	local str = ""
	local indent_str = string.rep("\t", indent) -- 根据层级生成缩进字符�?	
	if type(obj) ~= "table" then
		return tostring(obj)
	end
	
	str = str .. "{\n"
	for k, v in pairs(obj) do
		-- 键的缩进
		str = str .. indent_str .. "\t[" .. tostring(k) .. "] = "
	
		-- 值的处理
		if type(v) == "table" then
			-- 递归处理子表，缩进层�?+1
			str = str .. table2str(v, indent + 1) .. ",\n"
		else
			str = str .. tostring(v) .. ",\n"
		end
	end
	str = str .. indent_str .. "}"
	
	return str
end

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

skynet.start(function()
	-- 日志服务
	local function log_init()
	    math.randomseed(os.time());
	end
	-- 日志初始�?    log_init();
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
