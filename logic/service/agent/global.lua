
LOG		= Import("../logic/base/log.lua")
GAME		= Import("../logic/game.lua")
CONST		= Import("../logic/define/const.lua")
DATA_COMMON	= Import("../logic/define/data.lua")
FUNCLIB 	= Import("../common/funclib.lua")
CB_MGR		= Import("../common/cb_mgr.lua")
CALL_OUT	= Import("../common/call_out.lua")

USER_BASE	= Import("../logic/service/agent/module/user/base.lua")
USER_MGR	= Import("../logic/service/agent/module/user/mgr.lua")
JSON4LUA	= Import("../common/json.lua")
MONGO_SLAVE	= Import("../logic/service/agent/mongo_slave.lua")
LMDB		= Import("../logic/service/agent/lua_mdb.lua")

CLS_HERO	= Import("../logic/service/agent/module/hero/base.lua")
HERO_MGR	= Import("../logic/service/agent/module/hero/mgr.lua")

ITEM_MGR	= Import("../logic/service/agent/module/item/mgr.lua")


-- BLACK_LIST	= Import("../logic/module/black_list/black_list.lua")
-- RANDOM_NAME	= Import("../logic/module/name/random_name.lua")
-- CHAT_BASE     = Import("chat/base.lua")
-- CHAT_MGR      = Import("chat/mgr.lua")

REWARD_MGR	= Import("../logic/service/agent/module/reward/mgr.lua")
-- BUILD_BASE	= Import("../logic/service/agent/module/build/base.lua")
-- BUILD_MGR	= Import("../logic/service/agent/module/build/mgr.lua")

-- WORK_QUEUE_BASE = Import("../logic/service/agent/module/work_queue/base.lua")
-- BUILD_WORK_QUEUE_BASE = Import("../logic/service/agent/module/work_queue/build_queue_base.lua")
-- WORK_QUEUE_MGR = Import("../logic/service/agent/module/work_queue/mgr.lua")