local skynet = require "skynet"
local netpack = require "skynet.netpack"
-- local socketdriver = require "skynet.socketdriver"
local socket = require "skynet.socket"
CMD = {}
SOCKET = {}
local SLAVE_ADDRESS = {}

local login_port = skynet.getenv("login_port")
local slave_cnt = tonumber(skynet.getenv("slave_cnt"))

local address = skynet.getenv("address")

function startLogin()
	for _ = 1, slave_cnt do
	    table.insert(SLAVE_ADDRESS, skynet.newservice("logind"))
	end
	skynet.error(string.format("login Listen on %s:%d", address, login_port))
	local fd = socket.listen(address or "0.0.0.0", login_port)
	local balance = 1
	socket.start(fd, function (fd, addr)
		local slaveService = SLAVE_ADDRESS[balance]
		balance = balance + 1
		if balance > slave_cnt then
			balance = 1
		end
		pcall(MASTER_FUNC.accept, slaveService, fd, addr)
		
	end)
	skynet.dispatch("lua", function (_, address, cmd, ...)
		local f = CMD[cmd]
		if f then
			local ret = f(...)
			if ret then
				skynet.ret(skynet.pack(f(address, ...)))	
			end
		end
	end)
end

function CMD.createUserOk(account, userId)
	local idx = tonumber(userId) % slave_cnt
	local slaveService = SLAVE_ADDRESS[idx]
	pcall(MASTER_FUNC.createUserOk, slaveService, account, tostring(userId))
end

