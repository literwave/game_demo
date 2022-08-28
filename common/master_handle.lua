---        filename master_handle
-------    @author  xiaobo
---        date 2022/08/27/13/51/11

local skynet = require "skynet"
local netpack = require "skynet.netpack"
-- local socketdriver = require "skynet.socketdriver"
local socket = require "skynet.socket"
CMD = {}
SOCKET = {}
local slave_address = {}

local login_port = skynet.getenv("login_port")
local slave_cnt = skynet.getenv("slave_cnt")

local address
local queue


local function start_login()

    -- 先不处理套接字相关
    -- 启动从服务,保存地址用来做负载均衡
    for _ = 1, slave_cnt do
        table.insert(slave_address, skynet.newservice("logind"))
    end
	-- 开启登录套接字配置
	local nodelay = nodelay or true
	skynet.error(string.format("Listen on %s:%d", address, login_port))
	local fd = socket.listen(address or "0.0.0.0", login_port)
	-- 先不管逻辑处理，放到slavle里面去解析账号问题
	socket.start(fd, function ()
		-- 随机出一个slave_logind 处理逻辑
		local idx = math.random(#slave_address)
		-- 放到从登录服验证
		skynet.send(slave_address[idx], "lua", "auth", fd)
	end)
	skynet.error("login_port listend on: ", skynet.getenv("login_port"))


	skynet.start(function()
		skynet.dispatch("lua", function (_, address, cmd, ...)
			local f = CMD[cmd]
			if f then
				skynet.ret(skynet.pack(f(address, ...)))
			else
				skynet.ret(skynet.pack(handler.command(cmd, address, ...)))
			end
		end)
	end)
end

start_login()

