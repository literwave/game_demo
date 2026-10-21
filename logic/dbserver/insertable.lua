local skynet =  require "skynet"

function c_inert_table_update_save_mgr(datactrl,tbl,keyid)
	local self = c_data_update_save_mgr(datactrl,load_sql_str,save_sql_str)
	self.m_Table = tbl
	if not keyid then keyid = "rl_uID" end
	self.m_key_id = keyid
	function self.init(keys)
	    self.m_b_loding = 0
	    self.m_b_update = false
	    self.m_load_sql_str = "SELECT rl_sData FROM " .. self.m_Table .. " WHERE " .. self.m_key_id .. " = \'%s\';"
	    self.m_save_sql_str = "UPDATE " .. self.m_Table .. "  SET "..self._get_save_field().."rl_sData = %s WHERE  " .. self.m_key_id .. "  = \'%s\';"
	    self.m_insert_sql_str = "INSERT INTO " .. self.m_Table .. "  (`" .. self.m_key_id .. "`,`rl_sData`) VALUES (\'%s\',\'%s\');"
	end
	function self._reset_save_sql()
	    self.m_save_sql_str = "UPDATE " .. self.m_Table .. "  SET "..self._get_save_field().."rl_sData = %s WHERE  " .. self.m_key_id .. "  = \'%s\';"
	end
	function self._get_save_field()
	    return ""
	end
	function self._get_save_add_value()
	    return ""
	end
	function self._get_save_sql(sdata)
	    if self._get_save_field() == "" then 
	        return string.format(self.m_save_sql_str , sdata,self.m_data_ctrl.m_ID)
	    else 
	        local s = string.format(self.m_save_sql_str ,self._get_save_add_value(), sdata,self.m_data_ctrl.m_ID)
	        log("_getsavqsql1212",s);
	        return s
	    end
	end
	function self.Insert()
	    --sql = self.m_InsertSqlStr % (self.m_Keys ,"")
	    local sql = string.format(self.m_insert_sql_str ,self.m_data_ctrl.m_ID,"")
	    skynet.call(".sql", "lua", "query",sql)
	    --log("dbmgr insert",self.m_DataCtrl.m_ID)
	    --self.NewCreate()
	end
	function self.new_create()
	end
	
	self.init();
	return self;
end

