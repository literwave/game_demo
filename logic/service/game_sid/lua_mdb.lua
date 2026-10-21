local skynet = require "skynet"
local mongo = require "skynet.db.mongo"

mongo_client = nil
local function get_mongo_client()
	if not mongo_client then
		mongo_client = mongo.client({
			host = skynet.getenv("mongodb_host"),
			port = tonumber(skynet.getenv("mongodb_port")),
			username = skynet.getenv("mongodb_user"),
			password = skynet.getenv("mongodb_password"),
		})
	end
	return mongo_client
end

function update_doc_by_tbl(col, tbl)
	mongo_client = get_mongo_client()
	local db = mongo_client:getDB(GAME.get_data_base())
	local c = db:getCollection(col)
	c:update(selector, update, true)
end

function insert_doc_by_tbl(col, tbl)
	mongo_client = get_mongo_client()
	local db = mongo_client:getDB(GAME.get_data_base())
	local c = db:getCollection(col)
	c:insert(tbl)
end

function common_load_single(col, key)
	mongo_client = get_mongo_client()
	local db = mongo_client:getDB(GAME.get_data_base())
	local c = db:getCollection(col)
	local result = c:findOne({_id = key})
	return result
end

function common_load_tbl(col)
	mongo_client = get_mongo_client()
	local db = mongo_client:getDB(GAME.get_data_base())
	local c = db:getCollection(col)
	local tbl = {}
	local cursor = c:find()
	while cursor:hasNext() do
		local document = cursor:next()
		tbl[document["_id"]] = document.dat
	end
	cursor:close()
	if table.has_element(tbl) then
		return tbl
	end
end