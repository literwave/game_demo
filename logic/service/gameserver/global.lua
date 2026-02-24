
LOG		= Import("../logic/base/log.lua")
GAME		= Import("../logic/game.lua")
CONST		= Import("../logic/define/const.lua")
DATA_COMMON	= Import("../logic/define/data.lua")
FUNCLIB 	= Import("../common/funclib.lua")
CB_MGR		= Import("../common/cb_mgr.lua")
CALL_OUT	= Import("../common/call_out.lua")

MONGO_SLAVE	= Import("../logic/service/gameserver/mongo_slave.lua")
LMDB		= Import("../logic/service/gameserver/lua_mdb.lua")

USER_MGR	= Import("../logic/service/gameserver/module/user/mgr.lua")
ACT_BASE	= Import("../logic/service/gameserver/module/activity/base.lua")
ACT_MGR		= Import("../logic/service/gameserver/module/activity/mgr.lua")
