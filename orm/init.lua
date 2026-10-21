-- 游戏侧 ORM 入口：加载 schema_path 下的 *.td，转发到 lualib/orm

local skynet = require "skynet"
local core = require "orm"
local typedef = require "orm.typedef"

CLS_USER_DATA = "user_data"
CLS_HERO_DATA = "hero_data"
CLS_HERO_BAG = "hero_bag"
CLS_USER_HERO_DOC = "user_hero_doc"
CLS_ITEM_DATA = "item_data"
CLS_ITEM_BAG = "item_bag"
CLS_USER_ITEM_DOC = "user_item_doc"
CLS_QUEUE_DATA = "queue_data"
CLS_QUEUE_BAG = "queue_bag"
CLS_USER_QUEUE_DOC = "user_queue_doc"
CLS_USER_MAIL_DOC = "user_mail_doc"
CLS_SVR_MAIL_DOC = "svr_mail_doc"
CLS_GAME_SID_DATA = "game_sid_data"
CLS_BUILD_DATA = "build_data"
CLS_BUILD_BAG = "build_bag"
CLS_USER_BUILD_DOC = "user_build_doc"
CLS_TROOP_DATA = "troop_data"
CLS_TROOP_BAG = "troop_bag"
CLS_USER_TROOP_DOC = "user_troop_doc"

local SCHEMA_FILES = {
	"user.td",
	"hero.td",
	"item.td",
	"queue.td",
	"mail.td",
	"game_sid.td",
	"build.td",
	"troop.td",
}

local function load_schemas()
	local dir = skynet.getenv("schema_path")
	assert(dir and dir ~= "", "schema_path is empty")
	local type_list = {}
	for _, file in ipairs(SCHEMA_FILES) do
		local list = typedef.parse(file, dir)
		for _, item in ipairs(list) do
			table.insert(type_list, item)
		end
	end
	core.init(type_list)
end

load_schemas()

function create(cls_name, data)
	return core.create(cls_name, data)
end

function bind(obj, col, key)
	return core.bind(obj, col, key)
end

function hold(obj, col, key)
	return core.hold(obj, col, key)
end

function get(col, key)
	return core.get(col, key)
end

function forget(col, key)
	return core.forget(col, key)
end

function put(col, key, field, map_key, child)
	return core.put(col, key, field, map_key, child)
end

function remove(col, key, field, map_key)
	return core.remove(col, key, field, map_key)
end

function touch(obj)
	return core.touch(obj)
end

function dump(obj)
	return core.dump(obj)
end

function dump_field(obj, field)
	return core.dump_field(obj, field)
end

function is_cls(obj, cls_name)
	return core.is_cls(obj, cls_name)
end
