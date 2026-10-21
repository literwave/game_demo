local skynet = require "skynet"
CMD = {}

function CMD.register_gate(gate, server_id, slave_service_list)
	for _, slave_service in ipairs(slave_service_list) do
		skynet.send(slave_service, "lua", "register_gate", server_id, gate)
	end
end

function accept(slave_service, fd, addr)
	skynet.send(slave_service, "lua", "auth", fd, addr)
end