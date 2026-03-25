local skynet = require "skynet"

if SERVICE_NAME ~= "agent" then
local CALL_NO = 1
local CALL_TBL = {}
RPC_MOD = {}
local function addCallBackTbl(modName, cb, ...)
	CALL_TBL[CALL_NO] = {modName = modName, cb = cb, args = {...}}
	CALL_NO = CALL_NO % 10000000
end

local function getCallBackTbl(id)
	return CALL_TBL[id]
end
function subItemList(userId, cb, itemList, reasonList)
	local tAddr = USER_MGR.getAgentByUserId(userId)
	local sAddr = SERVICE_NAME
	local tbl = {
		args = itemList,
		sAddr = sAddr,
	}
	local id = CALL_NO
	addCallBackTbl(getfenv(2), cb, itemList, reasonList)
	skynet.send(tAddr, "rpc", "subItemList", id, skynet.self(),userId,tbl)
end

function subItemList(id, ok, userId)
	local tbl = getCallBackTbl(id)
	local modName = tbl.modName
	local funcName = tbl.func
	local ret = _G[modName][funcName](ok, userId)
	return ret
end

end

function genRewardInfo(rewardType, itemType, itemCount)
	return {reward_type = rewardType, item_type = itemType, item_count = itemCount}
end