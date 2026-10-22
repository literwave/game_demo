local skynet = require "skynet"
need_ref_callout_tbl = {}

no_stop_cb_tbl = {}


local function do_cb(id)
	local profile = GAME.get_profile()
	if profile then
		profile.start()
	end
	local info = CB_MGR.get_cb_info(id)
	local f = _G[info.mod_name][info.func_name]
	local ret = xpcall(function()
		f(table.unpack(info.param_tbl))
	end, __G__TRACKBACK__)
	if profile then
		local mod_name = info.mod_name
		local func_name = info.func_name
		if mod_name == "SLICE_TASK" then
			local task_tbl = info.param_tbl[2]
			if task_tbl then
				mod_name = task_tbl.module_name or info.mod_name
				func_name = task_tbl.func_name or info.func_name
			end
		end
		profile.stop(mod_name, func_name)
	end
end

local function lua_multi_cb(id, time)
	if not no_stop_cb_tbl[id] then
		return
	end
	do_cb(id)
	skynet.timeout(time, function()
		lua_multi_cb(id)
	end)
end

local function lua_once_cb(id)
	if not no_stop_cb_tbl[id] then
		return
	end
	do_cb(id)
	CB_MGR.clear_cb_info(id)
	no_stop_cb_tbl[id] = nil
	need_ref_callout_tbl[id] = nil
end

function call_once(mod_name, func_name, time, ...)
	local m = _G[mod_name]
	assert(m)
	assert(m[func_name])
	time = time * 100
	if time <= 0 then
		time = 0.1
	end
	local id = CB_MGR.fetch_callback_id(mod_name, func_name, ...)
	skynet.timeout(time, function()
		lua_multi_cb(id, time)
	end)

	need_ref_callout_tbl[id] = TIME.os_bj_sec() + time

	return id
end

function call_fre(mod_name, func_name, time, ...)
	local m = _G[mod_name]
	assert(m)
	assert(m[func_name])
	local id = CB_MGR.fetch_callback_id(mod_name, func_name, ...)
	skynet.timeout(time * 100, function ()
		lua_once_cb(id)
	end)

	return id
end

function remove_call_out(idx)
	CB_MGR.clear_cb_info(idx)
	no_stop_cb_tbl[idx] = nil
	need_ref_callout_tbl[idx] = nil
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

