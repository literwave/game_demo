local skynet = require "skynet"
local mongo = require "skynet.db.mongo"

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

function updateDocByTbl(col, tbl)
	mongoClient = getMongoClient()
	local db = mongoClient:getDB(GAME.getDataBase())
	local c = db:getCollection(col)
	c:update(selector, update, true)
end

function insertDocByTbl(col, tbl)
	mongoClient = getMongoClient()
	local db = mongoClient:getDB(GAME.getDataBase())
	local c = db:getCollection(col)
	c:insert(tbl)
end

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