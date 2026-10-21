local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"

local function response(fd, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(fd), ...)
	if not ok then
		socket.close(fd)
	end
end

function on_http_request(fd, params_tbl, body)
	local all_service_list = skynet.call(".launcher", "lua", "LIST")
	for _, addr in ipairs(all_service_list) do
		if addr ~= skynet.self() then
			skynet.call(addr, "lua", "shutdown")
		end
	end
	response(fd, 200, "shutting down")
	socket.close(fd)
	skynet.timeout(100, function()
		os.exit()
	end)
end