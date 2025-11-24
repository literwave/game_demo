local cbGlobalId = 0

local callBackTbl = {}

function fetchCallbackId(modName, funcName, ...)
	cbGlobalId = cbGlobalId + 1

	callBackTbl[cbGlobalId] = {
		modName = modName,
		funcName = funcName,
		paramTbl = {...},
	}

	return cbGlobalId
end

function getCBInfo(id)
	return callBackTbl[id]
end

function clearCBInfo(id)
	callBackTbl[id] = nil
end