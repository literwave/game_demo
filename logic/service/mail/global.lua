
LOG		= Import("../logic/base/log.lua")
GAME		= Import("../logic/game.lua")
CONST		= Import("../logic/define/const.lua")
DATA_COMMON	= Import("../logic/define/data.lua")
FUNCLIB 	= Import("../common/funclib.lua")
CB_MGR		= Import("../common/cb_mgr.lua")
CALL_OUT	= Import("../common/call_out.lua")

ORM		= Import("../orm/init.lua")

MONGO_SLAVE	= Import("../logic/service/mail/mongo_slave.lua")
LMDB		= Import("../logic/service/mail/lua_mdb.lua")

USER_MGR	= Import("../logic/service/mail/module/user/mgr.lua")
MAIL_BASE	= Import("../logic/service/mail/module/mail/base.lua")
MAIL_BATTLE	= Import("../logic/service/mail/module/mail/battle.lua")
MAIL_MGR	= Import("../logic/service/mail/module/mail/mgr.lua")
