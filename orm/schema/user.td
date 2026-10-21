# user persist schema (agent USER_INFO_COL.dat)
# map key number 落库为字符串，加载时由 orm 按类型还原，无需 @ 前缀

res_map <number, number>

sdk_param_map <string, string>

system_open_map <number, number>

user_data {
    _user_id string
    _birth_time number
    _login_time number
    _born_server_id number
    _name string
    _sex number
    _sdk_param_tbl sdk_param_map
    _res_tbl res_map
    _real_diamond number
    _gift_diamond number
    _sum_recharge_diamond number
    _head_icon number
    _lottery_times number
    _level number
    _exp number
    _system_open_tbl system_open_map
}
