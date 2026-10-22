
LOG		= Import("../logic/base/log.lua")
GAME		= Import("../logic/game.lua")
CONST		= Import("../logic/define/const.lua")
DATA_COMMON	= Import("../logic/define/data.lua")
FUNCLIB 	= Import("../common/funclib.lua")
CB_MGR		= Import("../common/cb_mgr.lua")
CALL_OUT	= Import("../common/call_out.lua")
TIME		= Import("../common/time.lua")
EVENT		= Import("../common/event.lua")

MONGO_SLAVE	= Import("../logic/base/mongo_slave.lua")
LMDB		= Import("../logic/service/gameserver/lua_mdb.lua")

USER_MGR	= Import("../logic/service/gameserver/module/user/mgr.lua")
