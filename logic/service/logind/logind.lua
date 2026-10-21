local skynet = require "skynet"
require "skynet.manager"

skynet.start(function()
	local master_name = ".logind"
	if skynet.localname(master_name) then
		dofile "../logic/service/logind/preload.lua"
		dofile "../common/slave_handle.lua"
		dofile "../common/slave_func.lua"
	else
		skynet.register(master_name)
		MASTER_HANDLE = Import("../common/master_handle.lua")
		MASTER_FUNC = Import("../common/master_func.lua")
		MASTER_HANDLE.start_login()
	end
end)