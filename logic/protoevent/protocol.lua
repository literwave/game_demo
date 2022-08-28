--  优化脚本自动生成
protocol = {
    --system 大协议号
    EnBigLogin = 1, --login
    EnBigChar  = 2, --chat

}

--小协议部分
--聊天系统
enChatSys = {
    -- 客户端请求(1-)
    C2S_CHAT = 1,         -- 请求聊天信息
    -- 服务端返回(1-)
    S2C_CHAT = 1          -- 聊天信息返回
}

-- 暂时先做成对应回调函数字符串
-- 使用lua 去执行load
-- 说明
-- 大协议部分
-- bigIds = {
--     -- 客户端请求(1-2)
--     [1]  = "netbase.handle",         --登录
--     [2]  = "netbase.handle",         --注册

--     [3]  = "netchat.handle",         --聊天

--     -- 服务端返回(1-2)
--     S2C_BIG_LOGIN   = 1,             -- 登录返回
--     S2C_BIG_CREATE  = 1,             -- 注册返回

--     S2C_SMALL_CHAT  = 2,             -- 聊天返回
-- }

-- --小协议部分
-- smallIds = {
--     -- 客户端请求(1-)
--     [1] = "netbase.C2SLogin",       --登录
--     [2] = "netbase.C2SCreate",      --注册
--     [3] = "netbase.C2SChat",        --聊天
--     -- 服务端返回(1-2)
--     S2C_LOGIN   = 1,                -- 登录返回
--     S2C_CREATE  = 2,                -- 注册返回
--     S2C_CHAT    = 3,                -- 聊天信息返回
-- }
