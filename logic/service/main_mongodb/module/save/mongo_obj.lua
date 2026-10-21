local skynet = require "skynet"
local mongo = require "skynet.db.mongo"

cls_mongo_db = cls_object:Inherit()

function cls_mongo_db:__init__(oci)
	Super(cls_mongo_db).__init__(self, oci)
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
	self.mongo_client = mongo.client(conf)
	if not self.mongo_client then
		LOG._error("MongoDB connection failed")
	end
end

function cls_mongo_db:disconnect()
	self.mongo_client:disconnect()
end

local function check_write(op, args, ok, err)
	if ok then
		return
	end
	local key = args.selector and args.selector._id
	skynet.error(string.format("mongo %s failed db=%s col=%s id=%s err=%s",
		op, tostring(args.database), tostring(args.collection), tostring(key), tostring(err)))
end

function cls_mongo_db:insert(args)
	local db = self.mongo_client:getDB(args.database)
	local c = db:getCollection(args.collection)
	local ok, err = c:safe_insert(args.doc)
	check_write("insert", args, ok, err)
end

function cls_mongo_db:insert_batch(args)
	local db = self.mongo_client:getDB(args.database)
	local c = db:getCollection(args.collection)
	for _, doc in ipairs(args.docs) do
		local ok, err = c:safe_insert(doc)
		check_write("insert", args, ok, err)
	end
end

function cls_mongo_db:delete(args)
	local db = self.mongo_client:getDB(args.database)
	local c = db:getCollection(args.collection)
	local ok, err = c:safe_delete(args.selector, args.single)
	check_write("delete", args, ok, err)
end

function cls_mongo_db:drop(args)
	local db = self.mongo_client:getDB(args.database)
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

function cls_mongo_db:find_one(args)
	local db = self.mongo_client:getDB(args.database)
	args.limit = 1
	local r = find_command(db, args)
	if r and r.ok == 0 then
		skynet.error(string.format("mongo findOne failed db=%s col=%s err=%s",
			tostring(args.database), tostring(args.collection), tostring(r.errmsg)))
	end
	if r and r.cursor and r.cursor.first_batch then
		return r.cursor.first_batch[1]
	end
	return nil
end

function cls_mongo_db:find_all(args)
	local db = self.mongo_client:getDB(args.database)
	local r = find_command(db, args)
	if r and r.ok == 0 then
		skynet.error(string.format("mongo findAll failed db=%s col=%s err=%s",
			tostring(args.database), tostring(args.collection), tostring(r.errmsg)))
	end
	if r and r.cursor then
		return r.cursor.first_batch or {}
	end
	return {}
end

function cls_mongo_db:update(args)
	local db = self.mongo_client:getDB(args.database)
	local c = db:getCollection(args.collection)
	local ok, err = c:safe_update(args.selector, args.update, args.upsert, args.multi)
	check_write("update", args, ok, err)
end

function cls_mongo_db:create_index(args)
	local db = self.mongo_client:getDB(args.database)
	local c = db:getCollection(args.collection)
	local result = c:createIndex(args.keys, args.option)
	return result
end

function cls_mongo_db:runCommand(args)
	local db = self.mongo_client:getDB(args.database)
	local result = db:runCommand(args)
	return result
end

-- bulkWrite 待实现，其实一条条更新也差不多的
-- function clsMongoDb:bulkWrite(args)
-- 	local db = self.mongoClient:getDB(args.database)
-- 	local result = db:runCommand(args)
-- 	return result
-- end