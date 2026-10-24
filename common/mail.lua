local skynet = require "skynet"

-- 发信都交给 .mail 服务。mail_id 是 Mail 表模板 id，detail_list 依次替换模板里的 %s（字符串），
-- reward_list 为 {{reward_type, item_id, item_count}}，没有奖励传 nil

function send_user_mail(user_id, mail_id, detail_list, reward_list)
	skynet.send(".mail", "lua", "send_user_mail", user_id, mail_id, detail_list or {}, reward_list or {})
end

function send_group_mail(user_id_list, mail_id, detail_list, reward_list)
	skynet.send(".mail", "lua", "send_group_mail", user_id_list, mail_id, detail_list or {}, reward_list or {})
end

-- 全服邮件：当前在线的立即收到，之后登录的在过期前登录也会收到
function send_srv_mail(mail_id, detail_list, reward_list)
	skynet.send(".mail", "lua", "send_srv_mail", mail_id, detail_list or {}, reward_list or {})
end
