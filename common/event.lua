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

local function add_listener(mod, event_id)
	if type(mod[event_id]) ~= "function" then
		return false
	end
	local mods = listener[event_id]
	if not mods then
		mods = {}
		listener[event_id] = mods
	end
	mods[mod] = true
	return true
end

-- 跨服务订阅：别的服务 emit 时也会发到本服务
function register(event_id)
	if add_listener(getfenv(2), event_id) then
		datacenter.set(ROOT, event_id, skynet.self(), true)
	end
end

-- 只订阅本服务内的 dispatch / fire。agent 有多个，玩家相关的事件必须用这个，否则会发到别的 agent
function listen(event_id)
	add_listener(getfenv(2), event_id)
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

-- 先同步分发给本服务的 listen，再异步发给 register 了的其它服务
function fire(event_id, ...)
	dispatch(event_id, ...)
	local subscriber = datacenter.get(ROOT, event_id)
	if not subscriber then
		return
	end
	local self = skynet.self()
	for addr in pairs(subscriber) do
		if addr ~= self then
			skynet.send(addr, "event", event_id, ...)
		end
	end
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
