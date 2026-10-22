local skynet = require "skynet"
local redis = require "skynet.db.redis"

-- 登录信息应该用redis的，而不是mongo, 因为登录是高并发的操作
redis_client = nil

local function get_redis_client()
	if not redis_client then
		local password = skynet.getenv("redis_password")
		local config = {
			host = skynet.getenv("redis_host"),
			port = skynet.getenv("redis_port"),
		}
		if password and password ~= "" then
			config.auth = password
		end
		redis_client = redis.connect(config)
	end
	return redis_client
end

function set_lock_login_nx(val)
	-- 这里要锁账号么？
	redis_client = get_redis_client()
	local lock_key = GAME.get_login_lock_key()
	local ok, err = redis_client:set(lock_key, val, "NX", "PX", CONST.LOCK_TIME)
	if not ok then
		skynet.error("set lock failed", err)
	end
end

function unlock_login_nx(val)
	redis_client = get_redis_client()
	local lock_key = GAME.get_login_lock_key()
	if redis_client:get(lock_key) == val then
		redis_client:del(lock_key)
	end
end

local function to_map(list)
	local map = {}
	if not list then
		return map
	end
	for i = 1, #list, 2 do
		map[list[i]] = list[i + 1]
	end
	return map
end

function hgetall(key)
	redis_client = get_redis_client()
	return to_map(redis_client:hgetall(key))
end

function hset(key, field, value)
	redis_client = get_redis_client()
	redis_client:hset(key, field, value)
end

function hmset(key, map, expire)
	redis_client = get_redis_client()
	local args = { key }
	for field, value in pairs(map) do
		args[#args + 1] = field
		args[#args + 1] = value
	end
	redis_client:hmset(args)
	if expire then
		redis_client:expire(key, expire)
	end
end

function system_start_up()
	get_redis_client()
	assert(redis_client, "redis connect failed")
end