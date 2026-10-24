# activity persist (agent USER_ACTIVITY_COL.dat)
# 只存活动自己的数据：活动期内登录天数、领奖记录、兑换次数。在线时长等取玩家模块

num_map <number, number>

act_data {
    _activity_id number
    _progress number
    _got_tbl num_map
    _extra_tbl num_map
    _day_no number
}

act_bag <number, act_data>

user_activity_doc {
    _acts act_bag
}
