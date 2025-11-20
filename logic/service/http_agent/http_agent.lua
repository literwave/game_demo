local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"

local methodTagTbl = {
	["login"] = ".login",
	["pay"] = ".gameserver"
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
			local path, query = urllib.parse(url)
			if query then
				local paramsTbl = urllib.parse_query(query)
				local methodTag = paramsTbl.methodTag
				local server = methodTagTbl[methodTag]
				if server then
					skynet.send(server, "lua", "request", body)
				end
			end
			response(fd, 200, "success")
		end
	end)
end)