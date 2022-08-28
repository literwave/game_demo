require "gamelogin"
local protobuf = require "protobuf"
local protocol = require "protocol"
-------------c2s------------
local netbase = {}

-- 登录
function netbase.C2SLogin(actor, buff)
    local data = protobuf.decode("Protocol.C2SLogin",buff)
    log("netbase.C2SLogin data:", data);
    local info = {
        accountname = data.account,
        pwd = data.pwd,
    }
    g_gameLogin.CheckLoginEnter(actor, info)
    netbase.S2CBaseLogin(actor, {
        id = actor.m_ID, 
        name = actor.GetName(), 
        lv = actor.GetGrade(),
     })
end

-- 注册
function netbase.C2SCreate(actor, buff)
    local data = protobuf.decode("Protocol.C2SLogin",buff)
    log("netbase.C2SLogin data:", data);
    local info = {
        accountname = data.account,
        pwd = data.pwd,
    }
    -- 待写判断逻辑
    netbase.S2CBaseLogin(actor, {
        result = 1
     })
end

------------------------------

------------handle--------------
-- 小协议号对应的函数
function handleSmallFunc(smallId)
    local func = smallIds[smallId]
    return func
end

-- 大协议号对应的回调函数
function netbase.handle(sid,buff)
    local fun = handleSmallFunc[sid];
    if fun ~= nil then 
        fun(GetPlayer(),buff)
    else
        misc.log_print("---netbase don't handle--",sid)
    end
end

------------handle--------------

------------s2c--------------
-- 登录
function netbase.S2CBaseLogin(roleObj, Msg)
    local stringbuffer = protobuf.encode("Protocol.S2CLogin", Msg)
    sendPackage(roleObj, bigIds.S2C_BIG_LOGIN, smallIds.S2C_LOGIN, stringbuffer)
end
-- 注册
function netbase.S2CBaseCreate(roleObj, Msg)
    local stringbuffer = protobuf.encode("Protocol.S2CCreate", Msg)
    sendPackage(roleObj, bigIds.S2C_BIG_LOGIN, smallIds.S2C_LOGIN, stringbuffer)
end
------------------------------
return netbase
