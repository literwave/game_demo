---        filename gamelogin
-------    @author  xiaobo
---        date 2022/03/30/22/16/57

package.path = SERVICE_PATH.."?.lua;" .. package.path

require "errorcode"
local define= require "define"
local skynet = require "skynet"
local accont = require "account.account"

--local publogin = require "publogin"
function creategamelogin()--create game login
	local self = {} 
	function self.CheckLoginEnter(who,info)
	    misc.log_print("start check agent login");
	    -- 已经登录
	    if who.m_nLogin == define.e_login.ok then--
	        return;
	    end
	    misc.log_print("step[1]: self.CheckLoginEnter");
	    -- 检查账号是否到了最大限�?
	    if not self.IsCanLogin() then
	        return;
	    end
	    misc.log_print("step[2]: self.CheckLoginEnter");
	    -- 向mysql服务发起call，检查是否存在账�?
	    accont.checkAccount(who, info);

	end
	function self.SendErrorCode(fd, errid)
	    misc.log_print("----SendErrorCode:", errid)
	    --待做 发送错误码
	end
	function self.IsCanLogin()
	    local rz = skynet.call(".maxaccount", "lua", "IsCanLogin");
	    misc.log_print("self.isCanLogin++", rz);
	    return  rz
	end
	-- 注册账号没有用到，待实现
	function self.CreateRole(account, info)
	    misc.log_print("self.CreateRole", account, info);
	end
	return self
end

g_gameLogin = creategamelogin()

