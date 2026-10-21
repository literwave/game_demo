require "skynet"

function send_user_mail(user_id, mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec)
	skynet.send(".mail", "lua", "send_user_mail", user_id, mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec)
end

function send_srv_mail(mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec)
	skynet.send(".mail", "lua", "send_srv_mail", mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec)
end

function send_group_mail(user_id_tbl, mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec)
	skynet.send(".mail", "lua", "send_group_mail", user_id_tbl, mail_kind, mail_type, title, content_tbl, detail_tbl, reward_list, life_sec)
end