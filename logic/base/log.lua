package.path = SERVICE_PATH.."?.lua;" .. package.path
local skynet = require "skynet"

local SERVICE_INFO = string.format("%s:%0x ", SERVICE_NAME, skynet.self())

local _FILE_INFO_T = {
	" <",
	SERVICE_INFO,
	"nil",
	" line:",
	"nil",
	">",
}

local _FILE_INFO_WITH_NAME_T = {
	" <",
	SERVICE_INFO,
	"nil",
	" line:",
	"nil",
	">",
	" <",
	"nil",
	">",
}
function _Info(...)
	local debugInfo = debug.getinfo(2, 'nSl')
	local t
	
	if debugInfo.name then
		_FILE_INFO_WITH_NAME_T[8] = debugInfo.name
		t = _FILE_INFO_WITH_NAME_T
	else
		t = _FILE_INFO_T
	end
	t[3] = debugInfo.short_src
	t[5] = debugInfo.currentline
	local args = {table.concat(t), ...}

	-- for k,v in pairs(info) do
	--     skynet.error(k, ':', v)
	-- end
	skynet.send(".log", "lua", "info", args)
end

function _debug(...)
	local debugInfo = debug.getinfo(2, 'nSl')
	local t
	if debugInfo.name then
		_FILE_INFO_WITH_NAME_T[8] = debugInfo.name
		t = _FILE_INFO_WITH_NAME_T
	else
		t = _FILE_INFO_T
	end
	t[3] = debugInfo.short_src
	t[5] = debugInfo.currentline
	local pfile = os.date("[%Y-%m-%d %H:%M:%S]") .. " [DEBUG]" .. table.concat(t)
	-- for i = 1, args.n do
	-- 	args[i] = tostring(args[i])
	-- end
	
	skynet.send(".gamelog", "lua", "writefile", "debug", pfile, ...)
end

function _Error(...)
	local info = debug.getinfo(2)
	local path = string.sub(info.source, 2, -1)
	path = string.sub(path, 2, -1)
	local para_1 = "["..string.match(path, "^.*") .."]: line: "..info.currentline.." print: "
	local args = {para_1, ...}

	-- for k,v in pairs(info) do
	--     skynet.error(k, ':', v)
	-- end
	skynet.send(".log", "lua", "error", args)
end
