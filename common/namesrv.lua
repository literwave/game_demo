---        filename namesrv
-------    @author  xiaobo
---        date 2022/08/27/12/52/57

-- 启服需要的启动的服务
START_NAME_SVER = {
    "protobufinit",
    "game_log",
    "load_xls",
    "dbserver",
    "maxaccount",
    "logind",
    "dbserver"
}

-- 	-- 日志文件 (需要为日志服务单独起一个actor)
-- 	skynet.newservice("game_log")
--     -- 启动网关服务
-- 	gate = skynet.newservice("gate")
-- 	-- 启动相关文件加载
-- 	local function load_init()
--       -- 启动配置表服务
--       skynet.newservice("data/share")
-- 	  -- 启动mysql服务
--       skynet.newservice("mysql/sql")
-- 	  -- 单独起一个服务的好处 是可以查看到服务器玩家达到上限了
--       skynet.newservice("account/maxaccount")
--   end