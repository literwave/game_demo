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

function onHttpRequest(fd, paramsTbl, body)
	local allServiceList = skynet.call(".launcher", "lua", "LIST")
	for _, addr in ipairs(allServiceList) do
		if addr ~= skynet.self() then
			skynet.call(addr, "lua", "shutdown")
		end
	end
	response(fd, 200, "shutting down")
	socket.close(fd)
	skynet.exit()
end