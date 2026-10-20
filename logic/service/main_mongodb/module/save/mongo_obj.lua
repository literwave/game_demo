local skynet = require "skynet"
local mongo = require "skynet.db.mongo"

clsMongoDb = clsObject:Inherit()

function clsMongoDb:__init__(oci)
	Super(clsMongoDb).__init__(self, oci)
	local username = skynet.getenv("mongodb_user")
	local password = skynet.getenv("mongodb_password")
	local conf = {
		host = skynet.getenv("mongodb_host"),
		port = skynet.getenv("mongodb_port"),
	}
	if username and username ~= "" and password and password ~= "" then
		conf.username = username
		conf.password = password
	end
	self.mongoClient = mongo.client(conf)
	if not self.mongoClient then
		LOG._error("MongoDB connection failed")
	end
end

function clsMongoDb:disconnect()
	self.mongoClient:disconnect()
end

local function check_write(op, args, ok, err)
	if ok then
		return
	end
	local key = args.selector and args.selector._id
	skynet.error(string.format("mongo %s failed db=%s col=%s id=%s err=%s",
		op, tostring(args.database), tostring(args.collection), tostring(key), tostring(err)))
end

function clsMongoDb:insert(args)
	local db = self.mongoClient:getDB(args.database)
	local c = db:getCollection(args.collection)
	local ok, err = c:safe_insert(args.doc)
	check_write("insert", args, ok, err)
end

function clsMongoDb:insertBatch(args)
	local db = self.mongoClient:getDB(args.database)
	local c = db:getCollection(args.collection)
	for _, doc in ipairs(args.docs) do
		local ok, err = c:safe_insert(doc)
		check_write("insert", args, ok, err)
	end
end

function clsMongoDb:delete(args)
	local db = self.mongoClient:getDB(args.database)
	local c = db:getCollection(args.collection)
	local ok, err = c:safe_delete(args.selector, args.single)
	check_write("delete", args, ok, err)
end

function clsMongoDb:drop(args)
	local db = self.mongoClient:getDB(args.database)
	local r = db:runCommand("drop", args.collection)
	return r
end

local function find_command(db, args)
	local cmd = {
		"find", args.collection,
		"filter", args.query or {},
	}
	if args.selector then
		cmd[#cmd + 1] = "projection"
		cmd[#cmd + 1] = args.selector
	end
	if args.skip ~= nil then
		cmd[#cmd + 1] = "skip"
		cmd[#cmd + 1] = args.skip
	end
	if args.limit ~= nil then
		cmd[#cmd + 1] = "limit"
		cmd[#cmd + 1] = args.limit
	end
	return db:runCommand(table.unpack(cmd))
end

function clsMongoDb:findOne(args)
	local db = self.mongoClient:getDB(args.database)
	args.limit = 1
	local r = find_command(db, args)
	if r and r.ok == 0 then
		skynet.error(string.format("mongo findOne failed db=%s col=%s err=%s",
			tostring(args.database), tostring(args.collection), tostring(r.errmsg)))
	end
	if r and r.cursor and r.cursor.firstBatch then
		return r.cursor.firstBatch[1]
	end
	return nil
end

function clsMongoDb:findAll(args)
	local db = self.mongoClient:getDB(args.database)
	local r = find_command(db, args)
	if r and r.ok == 0 then
		skynet.error(string.format("mongo findAll failed db=%s col=%s err=%s",
			tostring(args.database), tostring(args.collection), tostring(r.errmsg)))
	end
	if r and r.cursor then
		return r.cursor.firstBatch or {}
	end
	return {}
end

function clsMongoDb:update(args)
	local db = self.mongoClient:getDB(args.database)
	local c = db:getCollection(args.collection)
	local ok, err = c:safe_update(args.selector, args.update, args.upsert, args.multi)
	check_write("update", args, ok, err)
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