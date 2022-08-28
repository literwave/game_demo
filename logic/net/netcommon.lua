---        filename netcommon
-------    @author  xiaobo
---        date 2022/03/30/22/17/34

require "skynet"
local socket = require "skynet.socket"

-----
function netcommon.netPackCommon(packet)
    -- 取第一位  大协议号
    local bigId = string.byte(packet, 1, 1)
    -- 取第二位  小协议号
    local smallId = string.byte(packet, 2, 2)--math.floor(string.sub(result,2,2))
    -- 接下来就是对应数据
    local msg = string.sub(packet, 3)
    misc.log_print("--netcommon bigId ",bigId , "--netcommon smallId:",smallId )
    
end
-----------------------------
--  公共发送协议
-----------------------------
function netcommon.sendPackage(roleObj, bigid, smallid, pack)
    -- 登录的时候不会给套接字,要等登录成功才会设置对应的套接字
    local vfd = roleObj.getFD() or getFD()
    log("==sendPackage:",roleObj.getFD(), bigid, smallid)
    local str = string.char(bigid, smallid) .. pack
    local package = string.pack(">s2", str)
    socket.write(vfd, package)
end

sendPackage = netcommon.sendPackage 
return netcommon

