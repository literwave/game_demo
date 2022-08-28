require "protoevent.protocol"

local systemId = systemIds.enBigChat
local protocol = enChatSys



function reqActorChat(actor, packet)
    -- 逻辑
    local sendList = packet
    protocolevent.sendDataPack(actor, systemId, enChatSys.S2C_CHAT, "Protocol.S2CChat", sendList)
end


-- 注册协议
init = function ()
    protocolevent.register(systemId, protocol.C2S_CHAT, reqActorChat)         --请求聊天基本数据
end

init()












