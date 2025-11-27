local skynet = require "skynet"
needRefCalloutTbl = {}

noStopCBTbl = {}


local function doCB(id)
	local profile = GAME.getProfile()
	if profile then
		profile.start()
	end
	local info = CB_MGR.getCBInfo(id)
	local f = _G[info.modName][info.funcName]
	local ret = xpcall(function()
		f(unpack(info.paramTbl))
	end, __G__TRACKBACK__)
	if profile then
		local modName = info.modName
		local funcName = info.funcName
		if modName == "SLICE_TASK" then
			local taskTbl = info.paramTbl[2]
			if taskTbl then
				modName = taskTbl.moduleName or info.modName
				funcName = taskTbl.funcName or info.funcName
			end
		end
		profile.stop(modName, funcName)
	end
end

local function luaMultiCB(id, time)
	if not noStopCBTbl[id] then
		return
	end
	doCB(id)
	skynet.timeout(time, function()
		luaMultiCB(id)
	end)
end

local function luaOnceCB(id)
	if not noStopCBTbl[id] then
		return
	end
	doCB(id)
	CB_MGR.clearCBInfo(id)
	noStopCBTbl[id] = nil
	needRefCalloutTbl[id] = nil
end

function callOnce(modName, funcName, time, ...)
	local m = _G[modName]
	assert(m)
	assert(m[funcName])
	time = time * 100
	if time <= 0 then
		time = 0.1
	end
	local id = CB_MGR.fetchCallbackId(modName, funcName, ...)
	skynet.timeout(time, function()
		luaMultiCB(id, time)
	end)

	needRefCalloutTbl[id] = os.time() + time

	return id
end

function callFre(modName, funcName, time, ...)
	local m = _G[modName]
	assert(m)
	assert(m[funcName])
	local id = CB_MGR.fetchCallbackId(modName, funcName, ...)
	skynet.timeout(time * 100, function ()
		luaOnceCB(id)
	end)

	return id
end

function removeCallOut(idx)
	CB_MGR.clearCBInfo(idx)
	noStopCBTbl[idx] = nil
	needRefCalloutTbl[idx] = nil
end

-- function wizRefCallOut()
-- 	local curTime = TIME.osBJSec()
-- 	for id, endTime in pairs(needRefCalloutTbl) do
-- 		lcallout.rmCall(id)
-- 		local leftTime = endTime - curTime
-- 		if leftTime <= 0 then
-- 			leftTime = 0.1
-- 		end
-- 		lcallout.callOnce(id, leftTime)
-- 	end
-- end

