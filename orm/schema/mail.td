# mail persist（邮件正文仍为 plain serialize；用户/全服索引走 schema）

user_mail_status {
    is_read boolean
    is_got_reward boolean
    is_lock boolean
    lv number
}

mail_id_status_map <string, user_mail_status>

mail_kind_bag <number, mail_id_status_map>

user_mail_doc {
    mail_tbl mail_kind_bag
    fetch_svr_idx number
}

svr_mail_id_map <number, string>

svr_mail_doc {
    global_idx number
    svr_mail_tbl svr_mail_id_map
}
