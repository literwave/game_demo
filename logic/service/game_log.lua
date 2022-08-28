local skynet = require "skynet"
require "skynet.manager"
require "misc.misc"

local CMD = {}

-- 先写到这里，会换到log文件夹里面的
-- 警告日志
function CMD.warn(msg)
	log(msg)
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
		_G.logPath = skynet.getenv("logpath")
        math.randomseed(os.time());
    end
	-- 日志初始化
    log_init();
	skynet.dispatch("lua", function(_, _, cmd, ...)
		local f = CMD[cmd]
			if f then
				skynet.ret(skynet.pack(f(...)))
			else
				skynet.error("no callback")
			end
	end)
	-- 注册服务别名
	skynet.register(".log")
end)