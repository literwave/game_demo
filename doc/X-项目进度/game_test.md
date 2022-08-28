### game_test

* 前言

  * game_test 项目是使用`skynet`搭建的服务器，也是自己第一个使用和学习`skynet`的项目

* 项目拆分理解

* `main_start`里面

  ```lua
  skynet.error("Server start")
  
  skynet.uniqueservice("protobufinit")
  -- 初始化协议数据,注册协议，使用protobuf
  skynet.newservice("debug_console",8000)
  local watchdog = skynet.newservice("watchdog")
  -- 初始化看门狗服务
  ```

* `watchdog`里面

  ```lua
  
  skynet.start(function()
  	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
  		if cmd == "socket" then
  			local f = SOCKET[subcmd]
  			f(...)
  			-- socket api don't need return
  		else
  		  print("what dogcmd "..cmd)
  			local f = assert(CMD[cmd])
  			skynet.ret(skynet.pack(f(subcmd, ...)))
  		end
  	end)
  	
    -- 启动网关服务
  	gate = skynet.newservice("gate")
  	
  	-- 启动相关文件加载
  	local function load_init()
        -- 启动配置表服务
        skynet.newservice("data/share")
  	  -- 启动mysql服务
        mysql = skynet.newservice("mysql/sql")
        maxaccount = skynet.newservice("account/maxaccount")
    end
    ---------------------------------
  
    skynet.timeout(1,function() load_init() end)
  	skynet.register ".watchdog"
  end)
  ```

  