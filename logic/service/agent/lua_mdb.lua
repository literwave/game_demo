local skynet = require "skynet"
local mongo = require "skynet.db.mongo"

-- 这里为什么玩家加载数据的时候不放这里，因为比如玩家下线了
-- 但是缓存还没入库，然后另外一个玩家修改他的数据，如果从这里加载的话，数据就会出现问题

mongo_client = nil
local function get_mongo_client()
	if not mongo_client then
		local conn = mongo.client({
			host = skynet.getenv("mongodb_host"),
			port = tonumber(skynet.getenv("mongodb_port")),
			username = skynet.getenv("mongodb_user"),
			password = skynet.getenv("mongodb_password"),
		})
		mongo_client = conn:getDB(GAME.get_data_base())
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
	local c = mongo_client:getCollection(col)
	c:insert(tbl)
end

function common_load_single(col, key)
	mongo_client = get_mongo_client()
	local c = mongo_client:getCollection(col)
	local result = c:findOne({_id = key})
	return result
end

function common_load_tbl(col)
	mongo_client = get_mongo_client()
	local c = mongo_client:getCollection(col)
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