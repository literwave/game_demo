local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.shutdown()
	skynet.exit()
end

function CMD.send_user_mail(user_id, mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec)
	MAIL_MGR.send_user_mail(user_id, mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec)
end

function CMD.send_srv_mail(mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec)
	MAIL_MGR.send_srv_mail(mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec)
end

function send_group_mail(user_id_tbl, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec)
	MAIL_MGR.send_group_mail(user_id_tbl, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec)
end

skynet.start(function()
	skynet.error("boot mail success")
	dofile "../logic/service/mail/preload.lua"
	skynet.dispatch("lua", function (session, _, cmd, ...)
		local f = CMD[cmd]
		if f then
			if session ~= 0 then
				skynet.ret(skynet.pack(f(...)))
			else
				f(...)
			end
		end
	end)
	skynet.register(".mail")
end)
