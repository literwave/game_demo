local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"

-- 子模块自己回包并关 fd；这里只兜底没匹配上和报错的情况
local method_tag_tbl = {
	[1] = Import("../logic/service/http_agent/shutdown.lua"),
	[2] = Import("../logic/service/http_agent/hot_update.lua"),
	[3] = Import("../logic/service/http_agent/status.lua"),
}

local function response(fd, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(fd), ...)
	if not ok then
		skynet.error("http response failed", fd, err)
	end
end

local function handle_request(fd)
	local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), 8192)
	if code ~= 200 then
		response(fd, code)
		return
	end
	local _, query = urllib.parse(url)
	local params_tbl = query and urllib.parse_query(query) or {}
	local mod = method_tag_tbl[tonumber(params_tbl.method_tag)]
	if not mod then
		response(fd, 404, "unknown method_tag: " .. tostring(params_tbl.method_tag))
		return
	end
	mod.on_http_request(fd, params_tbl, body)
end

skynet.start(function()
	skynet.dispatch("lua", function(_, _, fd)
		socket.start(fd)
		local ok, err = xpcall(handle_request, debug.traceback, fd)
		if not ok then
			skynet.error("http request error", err)
			response(fd, 500, "error: " .. tostring(err))
		end
		socket.close(fd)
	end)
end)
