---        filename logind
-------    @author  xiaobo
---        date 2022/08/27/13/30/02

local skynet = require "skynet"
require "skynet.manager"


skynet.start(function()
	-- 启动主服务
	if skynet.localname(".logind") then
		-- 加载从登录服务
		dofile "../common/slave_handle.lua"
		dofile "../common/slave_func.lua"
	else
		-- 加载主登录服务
		-- 要先注册，否则启动从服务的时候会创建成找不到.logind
		skynet.register(".logind")
		dofile "../common/master_handle.lua"
		dofile "../common/master_func.lua"
	end
end)