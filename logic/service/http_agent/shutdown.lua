local skynet = require "skynet"
require "skynet.manager"	-- skynet.abort
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
	local result = skynet.call(".mcs", "lua", "stop")
	response(fd, 200, result)
	socket.close(fd)
	if result:find("^stopped") then
		skynet.abort()
	end
end
