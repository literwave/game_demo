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

-- ?method_tag=2&files=logic/service/agent/module/hero/mgr.lua,logic/define/const.lua&config=1
function on_http_request(fd, params_tbl, body)
	local path_list = {}
	for path in string.gmatch(params_tbl.files or "", "[^,]+") do
		if not path:find("^%.%./") then
			path = "../" .. path
		end
		table.insert(path_list, path)
	end
	local ret = skynet.call(".mcs", "lua", "hot_update", path_list, params_tbl.config == "1")
	local lines = {ret.ok and "ok" or ("failed: " .. tostring(ret.err))}
	for _, name in ipairs(ret.done_list or {}) do
		table.insert(lines, "updated " .. name)
	end
	response(fd, 200, table.concat(lines, "\n"))
	socket.close(fd)
end
