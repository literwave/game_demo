
LOG		= Import("../logic/base/log.lua")
GAME		= Import("../logic/game.lua")
CONST		= Import("../logic/define/const.lua")
-- DATA_COMMON	= Import("../logic/define/data.lua")
FUNCLIB 	= Import("../common/funclib.lua")
CB_MGR		= Import("../common/cb_mgr.lua")
CALL_OUT	= Import("../common/call_out.lua")

LOGIN_MGR	= Import("../logic/module/login/mgr.lua")

USER_BASE	= Import("../logic/module/user/base.lua")
USER_MGR	= Import("../logic/module/user/mgr.lua")
JSON4LUA	= Import("../common/json.lua")
MONGO_SLAVE	= Import("../common/mongo_slave.lua")


WHITE_LIST	= Import("../logic/module/white_list/white_list.lua")
BLACK_LIST	= Import("../logic/module/black_list/black_list.lua")
-- RANDOM_NAME	= Import("../logic/module/name/random_name.lua")
-- CHAT_BASE     = Import("chat/base.lua")
-- CHAT_MGR      = Import("chat/mgr.lua")