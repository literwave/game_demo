### game_demo

* 前言

  * game_demo 项目是使用`skynet`搭建的服务器，也是自己第一个使用和学习`skynet`的项目
  * 设计初衷追求简单，采用单agent方式，全放一个服务处理，agent处理登录和业务逻辑
  * 数据库采用mongodb，agent缓存层，mongo服务立即存档
  * 项目采用ECS架构，便于维护

* 架构设计

  * gateserver网关服务
    * 收发消息，每个agent应该存一个对应网关服务的地址，这样每个服务分配了一个单独网关，负载均衡了
    * agent不销毁，不然设计很复杂
    * 采取单网关吧，反正后面支持可扩展
    * gate应该处理的逻辑，客户端连接上网关，由gate服务拆解包，那咋知道协议号所属的服务呢，比如有些协议要转发到登录服
    * import的时候要发送到网关服务，注册协议的时机得告诉网关这条协议是哪个服务的，这样协议转发就是对的了
    * gate需要哪些映射呢，需要协议号->服务地址。
  * loginserver登录服务
  * chatserver聊天服务
  * httpserverhttp服务
    * 这里我就不支持了http服务了，有很少的地方用到吧
    * http服务一般用到接受后台发送的消息吧，用`httpc post`请求路由，这样会有个问题，如何知道回调给哪个服务
  * slgserver服务
    * 类似于agent服务

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

* 优化

  * login做成单独一个服务，如果校验完毕就发到网关层，然后交给agent，数据管理设计，应该只需要account数据就好了吧，唯一id也做成一个服务吧，这样就能保持所有agent得到的uid是唯一的了，login还是改成主从结构吧