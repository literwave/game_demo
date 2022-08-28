package.path = SERVICE_PATH.."?.lua;" .. package.path
local skynet = require "skynet"
require "db.dbmgr"
require "playersave.propdata"
require "base.only"
require "playersave.otherdb"
require "player.playerex"
require "npc.herodb"

local netbase = require "net.netbase"

local skynet = require "skynet"
--
--
local define = require "define"
local sqlstatement = require "misc.sqlstatement"
local netpet = require "net.netpet"
local netplayer = require "net.netplayer"

-- 使用玩家方法
-- 创建玩家对象
local actor = CreatePlayerClass()

function actor.Init(pid)
    actor.m_ID = pid;
    --actor.m_FD = actor.m_FD;
    actor.m_Info = {}
    actor.m_DBList = { --#Save
        --createdbmgr(createpropdata(actor.m_ID), g_LoadRoleBaseData, g_SaveRoleBaseData),
        CPlayInfoDataBaseMgr(create_savepropdata(actor.m_ID), nil, sqlstatement.g_SaveRolePlayerSqlBaseInfo),
    }

    actor.m_BaseData = createpropdata(actor.m_ID)--actor.BaseData
    actor.m_Today = only_CToday(actor.m_ID)
    actor.m_Week = only_CWeek(actor.m_ID)
    actor.m_HeroDB = herodb_createdata(actor.m_ID)--herodb_createdata(actor.m_ID);
    --actor.m_EquipDB = equipdb_createdata(actor.m_ID)
    --actor.m_TaskDB = taskdb_createdata(actor.m_ID)
    actor.m_OtherDB = otherdb_createotherdb(actor.m_ID)
    --actor.m_BuildDB = builddb_createdata(actor.m_ID);
    actor.m_WhenUpdateSaveList = { --
        CDataUpdateSaveMgr(actor.m_BaseData, sqlstatement.g_LoadRoleBaseData, sqlstatement.g_SaveRoleBaseData),
        CDataUpdateSaveMgr(actor.m_Today, sqlstatement.g_LoadRoleTodayData, sqlstatement.g_SaveRoleTodayData),
        CDataUpdateSaveMgr(actor.m_Week, sqlstatement.g_LoadRoleWeekData, sqlstatement.g_SaveRoleWeekData),
        --CDataUpdateSaveMgr(actor.m_EquipDB, sqlstatement.g_LoadEquipData, sqlstatement.g_SaveEquipData),
        --CDataUpdateSaveMgr(actor.m_TaskDB, sqlstatement.g_LoadTaskData, sqlstatement.g_SaveTaskData),
        CDataUpdateSaveMgr(actor.m_OtherDB, sqlstatement.g_LoadOtherData, sqlstatement.g_SaveOtherData),
        CInertTableUpdateSaveMgr(actor.m_HeroDB, "tbl_hero"),
    }
     --CDataUpdateSaveMgr(actor.m_BuildDB, sqlstatement.g_LoadBuildData, sqlstatement.g_SaveBuildData),
    actor.m_nLogin = define.e_login.off;
    actor.m_nSaveTime = 0;
    actor.m_nGM = 0;
    actor.SetHeart()
end
--##########################agent#######################
function actor.SetAgent(agent)
    actor.m_Agent = agent;
end 
function actor.GetID()
    return actor.m_ID
end
function actor.SocketClose()
    log("SocketClose")
    local _memery4=collectgarbage("count")
    log("---memery4",_memery4);--内存
    
    actor.m_Agent =nil
    actor.m_FD = 0
    actor.Save(true);
    actor.m_nLogin = define.e_login.off--
    actor.OffLine()
end
function actor.SendDisconnect()
    skynet.send(".watchdog","lua","kick",actor.m_FD) --
end
function actor.GetAgent()
    return actor.m_Agent;
end
function actor.IsLoadOK()
    return actor.m_nLogin  == define.e_login.ok
end
function actor.SetFD(fd)
    actor.m_FD = fd;
    actor.m_nLogin = define.e_login.off;
end
function actor.GetFD()
    return actor.m_FD
end
function actor.GetSocketID()
    return actor.GetFD();
end
--##########################save#######################
function actor.AutoSave() 
    if actor.m_FD==0 or  actor.m_nLogin ~= define.e_login.ok  then return end;
    if actor.m_nSaveTime  == 0 then actor.m_nSaveTime = misc.RandInt(100*120,100*300); end--一分钟到五分钟之间,第一次存的时候,打乱他们的时间
    skynet.timeout(actor.m_nSaveTime, function()  --5分钟存一次
        actor.Save()
        actor.m_nSaveTime = 100*300;--之后就保存5分钟存一次
        --leo test
--        if misc.IsTest() then 
--            actor.m_nSaveTime = 100*60 --暂时是15秒保护一次
--        end
        --end;
        actor.AutoSave()
    end)
end
function actor.Save(boffline) --
    log("-------save game",actor.m_ID);
    if actor.m_nLogin ~= define.e_login.ok then return end;
    if not actor.m_BaseData then return end;
    for k,sobj in pairs(actor.m_DBList) do
        sobj.Save();
    end
    for k,sobj in pairs(actor.m_WhenUpdateSaveList) do
        log("k,sobj",k)
        sobj.UpdateSave();
    end
    skynet.send(".privy","lua","save",actor.m_ID) --保存离线数据
    --
    if not boffline and actor.m_FD > 0 then 
        local bkick = not actor.JudgeHeart() 
        if bkick then 
            actor.SendDisconnect()
        end
    end
end
--##########################basedata#######################
function actor.Set(key,value)
    actor.m_BaseData.Set(key,value);
end
function actor.Add(key,value)
    actor.m_BaseData.Add(key,value);
end
function actor.Query(key,default)
    if not actor.m_BaseData then return default end;
    local value = actor.m_BaseData.Query(key,default)
    if value then return value else return default end
end
function actor.SetAccountInfo(info)
    actor.m_AccountInfo = info
end
function actor.GetAccountName()
    return actor.m_AccountInfo['accountname']
end
function actor.Name()
    return actor.Query('name', "临时name名字");
end
function actor.GetName()     --获得玩家名字
    return actor.Name() 
end      
function actor.SetName(name)     --设置玩家名字
    actor.Set("name",name)
end
function actor.GetGrade()        --获得玩家等级
    return actor.Query("lv",1);
end
function actor.SetGrade(lv)      --设置玩家等级
    if lv ~= actor.GetGrade() then
        actor.Set("lv",lv)
    end
end
function actor.GetExp()          --获得玩家经验值
    return actor.Query("exp",0);
end
function actor.SetExp(exp)       --设置玩家经验值
    if exp ~= actor.GetExp() then
        actor.Set("exp",exp)
    end
end
function actor.GetSex()          --获得玩家的性别
    return actor.Query("sex",1)
end
function actor.SetSex(n)         --设置玩家的性别
    actor.Set("sex",n)
end
function actor.GetShape()        --获得玩家的模型id
    return actor.Query("sid",0)
end
function actor.SetShape(sid)     --设置玩家的模型id
    actor.Set("sid",sid);
end
function actor.GetLV()
    return actor.GetGrade()
end
function actor.GetIcon()
    return 0
end
function actor.GetSID()
    return 0
end
function actor.GetVipLV()        --获得玩家的VIP等级
    return actor.Query("vip",0)
end
function actor.SetVipLV(lv)      --设置玩家的VIP等级
    actor.Set("vip",lv)
end
function actor.GetGold()        --获得玩家的金币数量
    return actor.Query("gold",1000)
end
function actor.SetGold(gold_num)      --设置玩家的金币数量
    actor.Set("gold",gold_num)
end
function actor.GetDiamond()        --获得玩家的钻石
    return actor.Query("diamond",100)
end
function actor.SetDiamond(diamond_num)      --设置玩家的钻石
    actor.Set("diamond",diamond_num)
end
--------------修改名字------------------
function actor.ChangeName(name)      
    if not name then
        log("actor.ChangeName name",name)
        return
    end
    if name ~= actor.GetName() then
        actor.SetName(name)
        netplayer.S2CPlayerChangeName(name)
    end
end
--##########################enter#######################
function actor.SetCreate()
  actor.m_bCreate = true
end
function actor.Create()
    -------------------
    if actor.m_ID then actor.SetName("game:"..actor.m_ID) end
    actor.SetGrade(1);
    --actor.SetDiamon(100);
    --actor.SetGold(50)
    --additem
--    actor.m_ItemDB.AddNewItem(actor,1001,1);
--    actor.m_ItemDB.AddNewItem(actor,1004,1);
--    actor.m_ItemDB.AddNewItem(actor,1003,1);
    log("++-create end");
    actor._CreateEx()
    actor.m_bCreate = false;
    --新账号10秒后保存
    local function cb()
        actor.Save()
    end
    skynet.timeout(100*10,cb)
    --actor.SetCreateTimer()
end
function actor.EnterGame(reenter) --reenter代表是否是顶号进入的
    log("-----------gameEnter")
    if actor.m_bCreate then
      actor.Create();
      actor.m_bCreate = false;
    else 
        --actor.GetAllOnlineExcute()
    end
    local function test()
    end
    test();
    
    actor.m_nLogin = define.e_login.ok
    netbase.S2CBaseInfo(actor)
    ----
    local function DelaySendPack()--延迟1
    end
    DelaySendPack();
    --cup
    local function Delay2()--延迟2
    end
    Delay2()
    local function Delay3()
        --netplayer.S2C_NetPlayer_S2CSendAllOK(actor)
        --leo test
        --local netwar = require "net.netwar"
        --netwar.TestWarPve(actor)
        netpet.LoginSendAll(actor)
    end
    skynet.timeout(20,Delay3) --0.2秒时间延迟
    local function judge()
        --#leo test
        --end
    end
    judge()
    local function JudgeMemery()
        local _memery3=collectgarbage("count")
        log("---memery3",_memery3);--内存
    end
    skynet.timeout(200,JudgeMemery);
    actor.AutoSave();
    actor.SetHeart()
end
function actor.PrivyPrepare()--加载Privy数据
    skynet.send(".privy","lua","load",actor.m_ID)
end
function actor.OffLine() --下线
    log("OffLine---",actor.m_ID)
    if not actor.m_BaseData then return end;
    local function Delay() --需要离线是因为~Privy那边需要玩家离线,他才删除
        --save privy
        --skynet.call(".privy","lua","offline",actor.m_ID) --同时删除离线数据
    end
    skynet.timeout(2,Delay) --延迟0.01秒
    actor.OffLineEx();
    actor.LeaveScene()
    log("LeaveScene00---",actor.m_ID)
end
function actor.SaveInfo2Redis() --设置信息,可以让人去抢夺
    RedisCommon.SetInfo(actor.m_ID,actor.GetSaveRedisInfo())
end
--##################################
function actor.SetToday(key, value)
    actor.m_Today.Set(key, value)
end
function actor.AddToday(key, value)
    actor.m_Today.Add(key, value)
end    
function actor.GetToday(key, default)
    if not default then default = 0 end
    return actor.m_Today.Query(key, default)
end
--#############week#################
function actor.SetWeek(key,value)
    actor.m_Week.Set(key, value)
end    
function actor.AddWeek(key,value)
    actor.m_Week.Add(key,value)
end   
function actor.GetWeek(key,default)
    if not default then default = 0 end
    return actor.m_Week.Query(key, default)
end
--################other###################
function actor.SetOther(key,value)
    actor.m_OtherDB.Set(key, value)
end 
function actor.GetOther(key,default)
    if not default then default = 0 end
    return actor.m_OtherDB.Query(key, default)
end
--##########################################
function actor.GetHeroDB()
    return actor.m_HeroDB;
end
function actor.GetEquipDB()
    return actor.m_EquipDB;
end
function actor.GetTaskDB()
    return actor.m_TaskDB;
end
--#########GM--------
function actor.GetGM()
    if actor.m_nGM >0 then return actor.m_nGM; end
    if  misc.Now() < actor.Query("gmtm",0) then  --如果还在有效期内
        return 1
    else
        return 0 
    end
end
function actor.SetGM(n,ntime)
    actor.m_nGM = n;
    if not misc.IsNull(ntime) then 
        actor.Set("gmtm",misc.Now() + ntime)
    end
    notify.GS2CMessage(actor.GetSocketID(),"权限:"..n)
end
function actor.SetHeart()
    actor.m_HeartTime = C_game.GetSecond();
end
function actor.JudgeHeart()
    local difftime = C_game.GetSecond() - actor.m_HeartTime
    if difftime >= define.hearttime  then 
        return false
    end
    return true;
end
function actor.GetPos()
    return actor.Query("pos",{x=100,y=100})
end
function actor.SetPos(pos) --pos = {x=100,y=100}
    actor.Set("pos",pos)
end
--------------------------------------------------------------end
actor = actor
-- g_player = actor;
return actor