local skynet = require "skynet"
local redis = require "skynet.db.redis"

-- 登录信息应该用redis的，而不是mongo, 因为登录是高并发的操作
redisClient = nil

local function getRedisClient()
	if not redisClient then
		local config = {
			host = skynet.getenv("redis_host"),
			port = skynet.getenv("redis_port"),
		}
		redisClient = redis.connect(config)
	end
	return redisClient
end

function setLockLoginNx(val)
	-- 这里要锁账号么？
	redisClient = getRedisClient()
	local lockKey = GAME.getLoginLockKey()
	local ok, err = redisClient:set(lockKey, val, "NX", "PX", CONST.LOCK_TIME)
	if not ok then
		skynet.error("set lock failed", err)
	end
end

function unlockLoginNx(val)
	redisClient = getRedisClient()
	local lockKey = GAME.getLoginLockKey()
	if redisClient:get(lockKey) == val then
		redisClient:del(lockKey)
	end
end

function setValueByKey(key, value, expire)
	redisClient = getRedisClient()
	redisClient:set(key, JSON4LUA.encode(value))
	if expire then
		redisClient:expire(key, expire)
	end
end

function getValueByKey(key)
	redisClient = getRedisClient()
	local val = redisClient:get(key)
	if val then
		return JSON4LUA.decode(val)
	end
	return val
end

function systemStartUp()
	getRedisClient()
	assert(redisClient, "redis connect failed")
end