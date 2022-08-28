---        filename agent
-------    @author  xiaobo
---        date 2022/03/30/22/17/25
local skynet = require "skynet"
require "base/baseheader"
require "player.global"

local CMD = {}
local client_fd
local player 


function CMD.Init()
    misc.log_print("agent init ",skynet.self())
	-- 查看一下agent使用内存
    local _memery1 = collectgarbage("count")
	misc.log_print("agent memery: ",_memery1)
	-- 初始化玩家对象
    player = require "player"
    --
end


function getFD() 
  return client_fd
end
function GetPlayer()
  return player
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
  unpack = function(msg, sz) 
     return msg, sz
  end,
	dispatch = function (_, _, msg, sz)
	   local packet = skynet.tostring(msg,sz)
	   -- 分包
	-- 取第一位  大协议号
	   local bigId = string.byte(packet, 1, 1)
	   -- 取第二位  小协议号
	   local smallId = string.byte(packet, 2, 2)
	   -- 接下来就是对应数据
	   local msg = string.sub(packet, 3)
	   -- 分发数据
	   local actor = GetPlayer()
	   protocolevent.dispatch(actor, bigId, smallId, msg)
	end
}

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	client_fd = fd
	GetPlayer().SetFD(fd)
	skynet.fork(function()
      skynet.sleep(5)
  end)
	skynet.call(gate, "lua", "forward", fd)
	
end

function CMD.disconnect()
	-- todo: do something before exit
	GetPlayer().SocketClose()
	skynet.exit()
end

function CMD.Change2Net(...)
    netcommon.netAgentChange(...)
end


skynet.start(function()
  -- 得到玩家信息 和玩家一些方法
  -- 启动服务的调一次 初始化玩家
  CMD.Init();
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
