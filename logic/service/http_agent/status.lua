local skynet = require "skynet"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"

-- ?method_tag=3 返回 starting / ready / stopping
function on_http_request(fd, params_tbl, body)
	local status = skynet.call(".mcs", "lua", "status")
	httpd.write_response(sockethelper.writefunc(fd), 200, status)
end
