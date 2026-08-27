# mail persist（邮件正文仍为 plain serialize；用户/全服索引走 schema）

UserMailStatus {
    isRead boolean
    isGotReward boolean
    isLock boolean
    lv number
}

MailIdStatusMap <string, UserMailStatus>

MailKindBag <number, MailIdStatusMap>

UserMailDoc {
    mailTbl MailKindBag
    fetchSvrIdx number
}

SvrMailIdMap <number, string>

SvrMailDoc {
    globalIdx number
    svrMailTbl SvrMailIdMap
}
