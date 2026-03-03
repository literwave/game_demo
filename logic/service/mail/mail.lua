local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.shutdown()
	skynet.exit()
end

function CMD.onUserLogin(userId, fd, gateSrv, isFirstLogin)
	skynet.error("mail login success", userId, gateSrv, isFirstLogin)
	USER_MGR.refLogin(userId, fd, gateSrv)
end

function CMD.onUserLogout(userId, fd)
	skynet.error("mail logout success", userId, fd)
	USER_MGR.disconnect(userId, fd)
end

function CMD.sendUserMail(userId, mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec)
	MAIL_MGR.sendUserMail(userId, mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec)
end

function CMD.sendSrvMail(mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec)
	MAIL_MGR.sendSrvMail(mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec)
end

function sendGroupMail(userIdTbl, mailType, title, contentTbl, detailTbl, rewardList, lifeSec)
	MAIL_MGR.sendGroupMail(userIdTbl, mailType, title, contentTbl, detailTbl, rewardList, lifeSec)
end

skynet.start(function()
	skynet.error("boot mail success")
	dofile "../logic/service/mail/preload.lua"
	skynet.dispatch("lua", function (session, address, cmd, ...)
		local f = CMD[cmd]
		if f then
			if session ~= 0 then
				skynet.ret(f(address, ...))
			else
				f(address, ...)
			end
		end
	end)
	skynet.register(".mail")
end)
