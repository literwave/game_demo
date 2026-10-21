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
function _info(...)
	local debug_info = debug.getinfo(2, 'nSl')
	local t
	if debug_info.name then
		_FILE_INFO_WITH_NAME_T[8] = debug_info.name
		t = _FILE_INFO_WITH_NAME_T
	else
		t = _FILE_INFO_T
	end
	t[3] = debug_info.short_src
	t[5] = debug_info.currentline
	local pfile = os.date("[%Y-%m-%d %H:%M:%S]") .. " [INFO]" .. table.concat(t)
	skynet.send(".gamelog", "lua", "writefile", "info", pfile, ...)
end

function _debug(...)
	local debug_info = debug.getinfo(2, 'nSl')
	local t
	if debug_info.name then
		_FILE_INFO_WITH_NAME_T[8] = debug_info.name
		t = _FILE_INFO_WITH_NAME_T
	else
		t = _FILE_INFO_T
	end
	t[3] = debug_info.short_src
	t[5] = debug_info.currentline
	local pfile = os.date("[%Y-%m-%d %H:%M:%S]") .. " [DEBUG]" .. table.concat(t)
	skynet.send(".gamelog", "lua", "writefile", "debug", pfile, ...)
end

function _error(...)
	local debug_info = debug.getinfo(2, 'nSl')
	local t
	if debug_info.name then
		_FILE_INFO_WITH_NAME_T[8] = debug_info.name
		t = _FILE_INFO_WITH_NAME_T
	else
		t = _FILE_INFO_T
	end
	t[3] = debug_info.short_src
	t[5] = debug_info.currentline
	local pfile = os.date("[%Y-%m-%d %H:%M:%S]") .. " [ERROR]" .. table.concat(t)
	skynet.send(".gamelog", "lua", "writefile", "error", pfile, ...)
end
