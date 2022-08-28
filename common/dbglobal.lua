---        filename dbglobal
-------    @author  xiaobo
---        date 2022/08/27/18/55/40

local mysql = require "skynet.db.mysql"
require "misc.misc"

local actor_varies = {
    actor_id = "bigint",
    static = "longtext"
}

function Sql_Start(str,func)
    CMD.start(str,func)
end
function  CMD.start(str,func)
        misc.log_print("------mysql--CMD.start:",str,func);
        skynet.fork(function ()
            local    res = db:query("select * from cats order by id asc")
            print ( "test3 loop times=" ,1,"\n","query result=",dump( res ) )
            res = db:query("select * from cats order by id asc")
            print ( "test3 loop times=" ,2,"\n","query result=",dump( res ) )
            --func(res);
        end)
        return "start return"
end
--sqlres1  {errno=1064,sqlstate="42000",err="You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near '{[\\\"1601307937324765076\\\"]={[1]=\\\"1\\\",[2]=\\\"1\\\",[3]=\\\"360\\\",},}'' WHERE rl_uID=1' at line 1",badresult=true,}  
function CMD.query(sqlst)
      --print("----------cmd.query:",sqlst);
        local res = db:query(sqlst);
        if res.errno then --
            if misc.IsTest() then local msg = debug.traceback(res.err, 2) misc.log_print(string.sub(sqlst,1,50)) misc.log_print(msg) end
            misc.SaveLog("sqlerror",string.sub(sqlst,1,50).." -|- "..res.err);
        end
end
function CMD.querycb(sqlst)
    local res = db:query(sqlst)
    if res.errno then --
        if misc.IsTest() then
            local msg = debug.traceback(res.err, 2) 
            misc.log_print(string.sub(sqlst,1,50)) 
            misc.log_print(msg) 
        end
        misc.log_print("sqlerror",string.sub(sqlst,1,50).." -|- "..res.err);
    end
    return res;
end

function modify_actor_table()
    local db_etc = load("return "..skynet.getenv "db_info")()
    local function on_connect(db)
       db:query("set charset utf8");
     end
    local db=mysql.connect({
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
           return
     end
     local sql = "desc actors;"
     local result = db:query(sql) 
     -- 如果表不存在就建表
     if result["badresult"] then
        sql = "create table actors () charset 'utf8';"
     end
end

