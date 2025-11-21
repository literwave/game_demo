local skynet = require "skynet"
local mongo = require "skynet.db.mongo"

clsMongoDb = clsObject:Inherit()

function clsMongoDb:__init__(oci)
	Super(clsMongoDb).__init__(self, oci)
	self.mongoClient = mongo.client({
		host = skynet.getenv("mongodb_host"),
		port = skynet.getenv("mongodb_port"),
	})
	if not self.mongoClient then
		LOG._error("MongoDB connection failed")
	end
end

function clsMongoDb:disconnect()
	self.mongoClient:disconnect()
end

function clsMongoDb:insert(args)
	local db = self.mongoClient:getDB(args.database)
	local c = db:getCollection(args.collection)
	c:insert(args.doc)
end

function clsMongoDb:insertBatch(args)
	local db = self.mongoClient:getDB(args.database)
	local c = db:getCollection(args.collection)
	c:batch_insert(args.docs)
end

function clsMongoDb:delete(args)
	local db = self.mongoClient:getDB(args.database)
	local c = db:getCollection(args.collection)
	c:delete(args.selector, args.single)
end

function clsMongoDb:drop(args)
	local db = self.mongoClient:getDB(args.database)
	local r = db:runCommand("drop", args.collection)
	return r
end

function clsMongoDb:findOne(args)
	local db = self.mongoClient:getDB(args.database)
	local c = db:getCollection(args.collection)
	local result = c:findOne(args.query, args.selector)
	return result
end

function clsMongoDb:findAll(args)
	local db = self.mongoClient:getDB(args.database)
	local c = db:getCollection(args.collection)
	local result = {}
	local cursor = c:find(args.query, args.selector)
	if args.skip ~= nil then
		cursor:skip(args.skip)
	end
	if args.limit ~= nil then
		cursor:limit(args.limit)
	end
	while cursor:hasNext() do
		local document = cursor:next()
		table.insert(result, document)
	end
	cursor:close()
	if #result > 0 then
		return result
	end
end

function clsMongoDb:update(args)
	local db = self.mongoClient:getDB(args.database)
	local c = db:getCollection(args.collection)
	c:update(args.selector, args.update, args.upsert, args.multi)
end

function clsMongoDb:createIndex(args)
	local db = self.mongoClient:getDB(args.database)
	local c = db:getCollection(args.collection)
	local result = c:createIndex(args.keys, args.option)
	return result
end

function clsMongoDb:runCommand(args)
	local db = self.mongoClient:getDB(args.database)
	local result = db:runCommand(args)
	return result
end

-- bulkWrite 待实现，其实一条条更新也差不多的
-- function clsMongoDb:bulkWrite(args)
-- 	local db = self.mongoClient:getDB(args.database)
-- 	local result = db:runCommand(args)
-- 	return result
-- end