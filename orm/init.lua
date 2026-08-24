-- 游戏侧 ORM 入口：加载 orm/schema/*.td，转发到 skynet/lualib/orm

local core = require "orm"
local typedef = require "orm.typedef"

CLS_USER_DATA = "UserData"
CLS_HERO_DATA = "HeroData"
CLS_HERO_BAG = "HeroBag"
CLS_USER_HERO_DOC = "UserHeroDoc"

local SCHEMA_FILES = {
	"user.td",
	"hero.td",
}

local function schema_dir()
	-- config rootdir 相对 skynet 工作目录，一般为 ../
	local root = nil
	local ok, skynet = pcall(require, "skynet")
	if ok and skynet.getenv then
		root = skynet.getenv("rootdir")
	end
	root = root or "../"
	if root:sub(-1) ~= "/" then
		root = root .. "/"
	end
	return root .. "orm/schema"
end

local function load_schemas()
	local dir = schema_dir()
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

function dump(obj)
	return core.dump(obj)
end

function dump_field(obj, field)
	return core.dump_field(obj, field)
end

function is_cls(obj, cls_name)
	return core.is_cls(obj, cls_name)
end
