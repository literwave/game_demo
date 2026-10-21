package.path = SERVICE_PATH.."?.lua;" .. package.path


local skynet =  require "skynet"
local mysql = require "skynet.db.mysql"
--require "pickle"
require "db.insertable"


function createdbmgr(datactrl,load_sql_str,save_sql_str)
	local self = {}
	function self.init()
	     self.m_data_ctrl = datactrl
	     self.m_save_sql_str = save_sql_str;
	     self.m_load_sql_str = load_sql_str
	     self.m_b_loding = true
	     self.m_temp_excute = {} --
	     self.m_wake_co = {}
	end
	function self.Insert()
	end
	function self.Prepare() --
	    if not self.m_data_ctrl or not self.m_load_sql_str then return end;
	    self.m_b_loding = true
	    --log("-----self.m_LoadSqlStr",self.m_LoadSqlStr);
	    local sql = string.format(self.m_load_sql_str , self.m_data_ctrl.m_ID);
	    local rz = skynet.call(".sql", "lua", "querycb",sql);
	    --log("------dbmgr.load",rz);
	    self._Load(rz)
	end
	function self.prepare_sync()--
	    if not self.m_data_ctrl or not self.m_load_sql_str then return end;
	    self.m_b_loding = true
	    local sql = string.format(self.m_load_sql_str , self.m_data_ctrl.m_ID);
	    skynet.fork(function ()  local rz = skynet.call(".sql", "lua", "querycb",sql); --
	        self._Load(rz)
	    end);
	end
	function self._Load(rz)
	    local str=nil
	    if misc.is_empty(rz) then
	        self.Insert();--
	    else
	        _,str = next(rz[1]);
	    end
	    local data 
	    if not str or str == ""or str == " " or ( string.len(str) ==1 and str:byte(1) == 6) then
	        data = {}
	    else
	        local function func(args)
	            data = g_pickle.eval(str);
	        end
	        local ok, err = xpcall(func, debug.traceback)
	        if not ok then
	            log("err",err);
	            data = {};
	        end
	    end
	    self.m_b_loding = false;
	    self.Load(data);
	    self.load_finish()
	end
	function self.Save()
	    local tdata = self.m_data_ctrl.Save();
	    local sdata = g_pickle.serialize_table(tdata);
	    sdata = mysql.quote_sql_str(sdata) --
	    local sql = self._get_save_sql(sdata)
	    skynet.fork(function () skynet.call(".sql", "lua", "query",sql) end);
	end
	function self._get_save_sql(sdata)
	    return string.format(self.m_save_sql_str , sdata,self.m_data_ctrl.m_ID)
	end
	function self.Load(data)
	    self.m_data_ctrl.Load(data);
	end
	function self.is_loading()
	    return self.m_b_loding
	end
	function self.load_finish()
	    --co
	    for i,co in ipairs(self.m_wake_co) do
	        skynet.wakeup(co) --
	    end
	    self.m_wake_co = {}
	    --cb
	    for k,cb in pairs(self.m_temp_excute) do
	        if cb then cb(self); end
	    end
	    self.m_temp_excute = {}
	end
	function self.append_awake_co(co)
	    if self.is_loading() then
	        table.insert(self.m_wake_co,co);
	    else
	        skynet.wakeup(co)
	    end
	end
	function self.Excute(cb) --
	    if self.is_loading() then
	        table.insert(self.m_temp_excute,cb);
	    else
	        if cb then  cb(self);  end
	    end
	end
	self.init();
	return self
end
function c_play_info_data_base_mgr(datactrl,load_sql_str,save_sql_str)
	local self = createdbmgr(datactrl,load_sql_str,save_sql_str)
	function self.Save()
	    local sdata = self.m_data_ctrl.Save();
	    local sql = string.format(self.m_save_sql_str ,sdata['name'],sdata['sex'],sdata['sid'],sdata['lv'],self.m_data_ctrl.m_ID)
	    skynet.fork(function () skynet.call(".sql", "lua", "query",sql) end);
	    --log("CPlayInfoDataBaseMgr",sdata);
	end
	function self.Load(data)
	end
	return self;
end

function c_data_update_save_mgr(datactrl,load_sql_str,save_sql_str)
	local self = createdbmgr(datactrl,load_sql_str,save_sql_str)
	function self.update_save() 
	    if self.m_data_ctrl.check_update()==true then
	        self.Save();
	        --log("---------CDataUpdateSaveMgr");
	    end
	end
	return self
end

