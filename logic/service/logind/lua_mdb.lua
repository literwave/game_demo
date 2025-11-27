local skynet = require "skynet"
local mongo = require "skynet.db.mongo"

-- 这里为什么玩家加载数据的时候不放这里，因为比如玩家下线了
-- 但是缓存还没入库，然后另外一个玩家修改他的数据，如果从这里加载的话，数据就会出现问题

mongoClient = nil
local function getMongoClient()
	if not mongoClient then
		mongoClient = mongo.client({
			host = skynet.getenv("mongodb_host"),
			port = skynet.getenv("mongodb_port"),
		})
	end
	return mongoClient
end

function updateDocByTbl(col, tbl, upinsert)
	mongoClient = getMongoClient()
	local db = mongoClient:getDB(GAME.getDataBase())
	local c = db:getCollection(col)
	for key, value in pairs(tbl) do
		local preString = '@'
		local newKey = numberKeyAddPreString(key, preString)
		local newVal = table.addNumberKeyPreString(value, preString)
		tbl[newKey] = newVal
		c:update({["_id"] = newKey}, newVal, upinsert)
	end
end

-- function insertDocByTbl(col, tbl)
-- 	mongoClient = getMongoClient()
-- 	local db = mongoClient:getDB(GAME.getDataBase())
-- 	local c = db:getCollection(col)
-- 	c:insert(tbl)
-- end

function commonLoadSingle(col, key)
	mongoClient = getMongoClient()
	local db = mongoClient:getDB(GAME.getDataBase())
	local c = db:getCollection(col)
	local result = c:findOne({_id = key})
	return table.removePreString(result, '@')
end

function commonLoadTbl(col)
	mongoClient = getMongoClient()
	local c = mongoClient:getCollection(col)
	local result = {}
	local cursor = c:find()
	while cursor:hasNext() do
		local document = cursor:next()
		table.insert(result, document)
	end
	cursor:close()
	if #result > 0 then
		return table.removePreString(result, '@')
	end
end