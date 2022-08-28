---        filename slave_func
-------    @author  xiaobo
---        date 2022/08/27/14/03/55

local skynet = require "skynet"
local socket = require "skynet.socket"
local protobuf = require "protobuf"

dofile "../logic/protoevent/routines.lua"
CMD = {}

function CMD.auth(fd)
	skynet.error("slave deal login")
	socket.start(fd)
	while true do
		local read_data = socket.read(fd)
		-- 不等于大协议号登录 就退出
		local sys_id = string.byte(read_data, 1, 1)
		local small_id = string.byte(read_data, 2, 2)
		local msg_data = string.sub(read_data, 3)
		if sys_id ~= 1 then
			return
		else
			if small_id == 1 then
				-- 玩家登录
				local packet = protobuf.decode("Login.c2splaylogin", msg_data)
				-- 待做 查找数据库 是否有该账号且密码是否正确
				-- 现在直接返回登录成功
				-- 如果账号密码没问题要给到网关那边，由网关那边主动发送登录结果
				-- send_msg_to_client(fd, sys_id, small_id, "Login.s2cplaylogin", send_list)
				-- 转移套接字服务控制权给网关服务
				socket.abandon(fd)
				skynet.call(".gate", "lua", "authfd" ,account, packet.passwd, sys_id, small_id, fd)
				break
			elseif small_id == 2 then
				-- 玩家注册
				local packet = protobuf.decode("Login.c2splayregister", msg_data)
				-- 待做 插入数据库 是否存在该账号
				-- 现在直接返回注册成功
				local send_list = {account = packet.account, passwd = packet.passwd, confirm_passwd = packet.confirm_passwd}
				send_msg_to_client(fd, sys_id, small_id, "Login.s2cplayregister", send_list)
			end
		end
	end
end





