local skynet = require "skynet"
local datacenter = require "skynet.datacenter"

local ROOT = "event"
-- [event_id] = { [mod] = true }；模块变量热更时保留
listener = {}

skynet.register_protocol {
	name = "event",
	id = skynet.PTYPE_EVENT,
	pack = skynet.pack,
	unpack = skynet.unpack,
}

local function ensure_listener(event_id)
	local mods = listener[event_id]
	if not mods then
		mods = {}
		listener[event_id] = mods
		datacenter.set(ROOT, event_id, skynet.self(), true)
	end
	return mods
end

function register(event_id)
	local mod = getfenv(2)
	if type(mod[event_id]) ~= "function" then
		return
	end
	local mods = ensure_listener(event_id)
	mods[mod] = true
end

function unregister(event_id)
	local mod = getfenv(2)
	local mods = listener[event_id]
	if not mods or not mods[mod] then
		return
	end
	mods[mod] = nil
	if next(mods) then
		return
	end
	listener[event_id] = nil
	datacenter.set(ROOT, event_id, skynet.self(), nil)
end

function dispatch(event_id, ...)
	local mods = listener[event_id]
	if not mods then
		return false
	end
	for mod in pairs(mods) do
		local fn = mod[event_id]
		if fn then
			fn(...)
		end
	end
	return true
end

function emit(event_id, ...)
	local subscriber = datacenter.get(ROOT, event_id)
	if not subscriber then
		return
	end
	for addr in pairs(subscriber) do
		skynet.send(addr, "event", event_id, ...)
	end
end

skynet.dispatch("event", function(_, _, event_id, ...)
	dispatch(event_id, ...)
end)
