local function onReqUserRes(fd)
	local user = USER_MGR.getUserByFd(fd)
	local resList = {}
	for resType = CONST.RES_TYPE_FOOD, CONST.RES_TYPE_WOOD do
		table.insert(resList, makeCommonPtoTbl(resType, user:getResNum(resType)))
	end
	for_caller.s2c_req_user_res(fd, {resList = resList})
end

function __init__()
	for_maker.c2s_req_user_res = onReqUserRes
end