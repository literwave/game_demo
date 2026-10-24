-- common/event.lua：listen 只在本服务内分发，register 才登记到 datacenter；fire 不会发回自己

local EVENT_FILE = "common/event.lua"
local SELF = 10

local function setup()
	local dc = {}
	local sent = {}
	local fake_skynet = {
		PTYPE_EVENT = 99,
		self = function() return SELF end,
		register_protocol = function() end,
		dispatch = function() end,
		pack = function() end,
		unpack = function() end,
		send = function(addr, _, ...) sent[#sent + 1] = {addr, ...} end,
	}
	local fake_dc = {
		set = function(_, event_id, addr, v)
			dc[event_id] = dc[event_id] or {}
			dc[event_id][addr] = v
		end,
		get = function(_, event_id) return dc[event_id] end,
	}
	local env = setmetatable({}, {__index = _G})
	local old_require = require
	env.require = function(name)
		if name == "skynet" then
			return fake_skynet
		end
		if name == "skynet.datacenter" then
			return fake_dc
		end
		return old_require(name)
	end
	env.getfenv = function()
		return env.__caller
	end
	assert(loadfile(EVENT_FILE, "t", env))()
	return env, dc, sent
end

local T = {}

function T.listen_is_local_only()
	local E, dc, sent = setup()
	local got = {}
	E.__caller = {on_x = function(a) got[#got + 1] = a end}
	E.listen("on_x")
	assert(dc.on_x == nil, "listen must not register to datacenter")
	E.fire("on_x", 7)
	assert(#got == 1 and got[1] == 7)
	assert(#sent == 0)
end

function T.fire_skips_self_and_sends_others()
	local E, dc, sent = setup()
	E.__caller = {on_y = function() end}
	E.register("on_y")
	dc.on_y[20] = true
	E.fire("on_y", 1)
	assert(#sent == 1 and sent[1][1] == 20, "only the other service gets it")
end

return T
