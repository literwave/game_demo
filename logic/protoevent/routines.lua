require "misc.misc"
require "protobuf"

local socket = require "skynet.socket"

dmap = {}

-- 注册协议回调函数
function register(sys_id, small_id, func)
    local name = sys_id + "_" + small_id
    dmap[name] = func
end


-- 取消注册协议回调函数
function unregister(sys_id, small_id)
    local name = sys_id + "_" + small_id
    dmap[name] = nil
end

-- 回调
function dispatch(actor, sys_id, small_id, protodata)
    local name = sys_id + "_" + small_id
    local cb = dmap[name]
    if not cb then misc.log_print() end
    return cb(actor, protodata)
end

function send_msg_to_client(vfd, sys_id, small_id, pType, packet)
    local stringbuffer = protobuf.encode(pType, packet)
    local str = string.char(sys_id, small_id) .. stringbuffer
    local package = string.pack(">s2", str)
    socket.write(vfd, package)
end

function sendDataPack(actor, sys_id, small_id, pType, packet)
    -- 登录的时候不会给套接字,要等登录成功才会设置对应的套接字
    -- 登录的时候不能放到游戏服里面处理，要放到logind服务处理
    -- 玩家的初始化要放到登录那边处理
    local vfd = actor.getFD() or getFD()
    log("==sendPackage:",actor.getFD(), sys_id, small_id)
    send_msg_to_client(vfd, sys_id, small_id, pType, packet)
end