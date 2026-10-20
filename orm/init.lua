-- 游戏侧 ORM 入口：加载 schema_path 下的 *.td，转发到 lualib/orm

local skynet = require "skynet"
local core = require "orm"
local typedef = require "orm.typedef"

CLS_USER_DATA = "UserData"
CLS_HERO_DATA = "HeroData"
CLS_HERO_BAG = "HeroBag"
CLS_USER_HERO_DOC = "UserHeroDoc"
CLS_ITEM_DATA = "ItemData"
CLS_ITEM_BAG = "ItemBag"
CLS_USER_ITEM_DOC = "UserItemDoc"
CLS_QUEUE_DATA = "QueueData"
CLS_QUEUE_BAG = "QueueBag"
CLS_USER_QUEUE_DOC = "UserQueueDoc"
CLS_USER_MAIL_DOC = "UserMailDoc"
CLS_SVR_MAIL_DOC = "SvrMailDoc"
CLS_GAME_SID_DATA = "GameSidData"
CLS_BUILD_DATA = "BuildData"
CLS_BUILD_BAG = "BuildBag"
CLS_USER_BUILD_DOC = "UserBuildDoc"

local SCHEMA_FILES = {
	"user.td",
	"hero.td",
	"item.td",
	"queue.td",
	"mail.td",
	"game_sid.td",
	"build.td",
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
