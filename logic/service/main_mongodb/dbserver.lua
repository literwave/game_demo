---        filename dbserver
-------    @author  xiaobo
---        date 2022/08/28/13/36/14

local skynet = require "skynet"
require "skynet.manager" 
local mysql = require "skynet.db.mysql"

local db
local CMD = {}

function sql_start(str,func)
	CMD.start(str,func)
end
function CMD.querycb(sqlst)
	local res = db:query(sqlst)
	return res;
end


-- 这个主的数据库做的服务应该是建表,对应表字段的修改和删�?
skynet.start(function()
	dofile "../common/dbglobal.lua"
	dofile "../logic/service/dbserver/preload.lua"
	modify_actor_table()
   local db_etc = load("return "..skynet.getenv "db_info")()
   local function on_connect(db)
	  db:query("set charset utf8");
	end
  db=mysql.connect({
	    host=db_etc[1],
	    port=tonumber(db_etc[2]),
	    database=db_etc[3],
	    user=db_etc[4],
	    password=db_etc[5],
	    max_packet_size = 1024 * 1024,
	    on_connect = on_connect
	})
	if not db then
		  skynet.error("failed to connect mysql")
	end
	-- db:query("set names utf8")
	--
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(CMD[cmd])
	    if session == 0 then 
	        f(subcmd, ...)
	    else 
		    skynet.ret(skynet.pack(f(subcmd, ...)))
	    end
	 end)

	 
	skynet.register ".dbserver"
	-- skynet.register ".sql"
end)

