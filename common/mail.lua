require "skynet"

function sendUserMail(userId, mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec)
	skynet.send(".mail", "lua", "sendUserMail", userId, mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec)
end

function sendSrvMail(mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec)
	skynet.send(".mail", "lua", "sendSrvMail", mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec)
end

function sendGroupMail(userIdTbl, mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec)
	skynet.send(".mail", "lua", "sendGroupMail", userIdTbl, mailKind, mailType, title, contentTbl, detailTbl, rewardList, lifeSec)
end