local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"

local method_tag_tbl = {
	[1] = Import("../logic/service/http_agent/shutdown.lua"),
}

local function response(fd, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(fd), ...)
	if not ok then
		socket.close(fd)
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, fd)
		socket.start(fd)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), 8192)
		if code ~= 200 then
			response(fd, code)
		else
			local tmp = {}
			if header.host then
				table.insert(tmp, string.format("host: %s", header.host))
			end
			local path, query = urllib.parse(url)
			table.insert(tmp, string.format("path: %s", path))
			local ret = "failed"
			if query then
				local params_tbl = urllib.parse_query(query)
				local method_tag = tonumber(params_tbl.method_tag)
				local mod = method_tag_tbl[method_tag]
				mod.on_http_request(fd, params_tbl, body)
			end
		end
	end)
end)