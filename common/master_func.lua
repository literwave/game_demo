local skynet = require "skynet"
local websocket = require "http.websocket"
CMD = {}

function CMD.registerGate(gate, serverId, slaveServiceList)
	for _, slaveService in ipairs(slaveServiceList) do
		skynet.send(slaveService, "lua", "registerGate", serverId, gate)
	end
end

function accept(slaveService, fd, addr)
	skynet.send(slaveService, "lua", "auth", fd, addr)
end