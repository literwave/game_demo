local skynet = require "skynet"
require "skynet.manager"

skynet.start(function()
	-- 启动主服务
	local masterName = ".logind"
	if skynet.localname(masterName) then
		-- 加载从登录服务
		dofile "../logic/service/logind/preload.lua"
		dofile "../common/slave_handle.lua"
		dofile "../common/slave_func.lua"
	else
		-- 加载主登录服务
		-- 要先注册，否则启动从服务的时候会创建成找不到.logind
		skynet.register(masterName)
		MASTER_HANDLE = Import("../common/master_handle.lua")
		MASTER_FUNC = Import("../common/master_func.lua")
		MASTER_HANDLE.startLogin()
	end
end)