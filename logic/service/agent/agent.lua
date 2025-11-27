local skynet = require "skynet"
local queue = require "skynet.queue"
local protobuf = require "protobuf"

local CMD = {}

local userQueues = {
	-- [userId] = queue(),
}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.unpack
}

function CMD.login(fd, account, userId, addr)
	local user
	if userId == "" then
		user = USER_MGR.createNewUser(fd)
	else
		user = USER_MGR.tryInitUser(userId)
	end
	user:setAccount(account)
	user:setLoginAddr(addr)
	return user:getUserId()
end

function CMD.disconnect(fd, userId)
	userQueues[userId] = nil
	USER_MGR.disconnect(fd)
end

skynet.start(function()
	dofile "../logic/service/agent/preload.lua"
	skynet.dispatch("lua", function(seesion, _ , command, ...)
		local f = CMD[command]
		if seesion ~= 0 then
			skynet.ret(skynet.pack(f(...)))
		else
			f(...)
		end
	end)

	skynet.dispatch("client", function(fd, addr, packet, userId)
		if not userQueues[userId] then
			userQueues[userId] = queue()
		end
		local userQueue = userQueues[userId]
		-- 分包
		-- 取第一位  协议号
		local id = string.unpack(">I2", packet, 1)
		assert(fd)
		-- 接下来就是对应数据
		local decodeMsg = string.sub(packet, 3)

		local ptoName = ID_TO_PTONAME[id]
		if ptoName ~= "c2splaylogin" and USER_MGR.getUserIdByVfd(fd) then
			-- 这里肯定是没校验过的玩家发过来的消息
			return
		end
		if not for_maker[ptoName] then
			LOG._debug("ptoName: %s not register", ptoName)
			return
		end

		local packName = ID_TO_PACK_NAME[id]
		local msg = protobuf.decode(packName, decodeMsg)
		if not msg then
			if not msg then
				LOG._debug("packName: %s not exist", packName)
			end
			return
		end
		-- 分发数据
		pcall(userQueue, for_maker[ptoName], userId, msg)
	end)
end)