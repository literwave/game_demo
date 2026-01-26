local skynet = require "skynet"
require "skynet.manager"

skynet.start(function()
	local masterName = ".logind"
	if skynet.localname(masterName) then
		dofile "../logic/service/logind/preload.lua"
		dofile "../common/slave_handle.lua"
		dofile "../common/slave_func.lua"
	else
		skynet.register(masterName)
		MASTER_HANDLE = Import("../common/master_handle.lua")
		MASTER_FUNC = Import("../common/master_func.lua")
		MASTER_HANDLE.startLogin()
	end
end)