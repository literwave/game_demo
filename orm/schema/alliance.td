# alliance persist (union service ALLIANCE_COL.dat)
# 每个联盟一份，key = 联盟 id。玩家属于哪个联盟、申请了哪些联盟启动时从这里重建
# 成员和申请里的名字、头像、等级、战力是 agent 上报的快照，玩家登录或战力变化时刷新

alliance_member {
    _uid number
    _name string
    _head_icon number
    _pos number
    _level number
    _power number
    _join_time number
    _offline_time number
}

alliance_member_map <number, alliance_member>

alliance_apply {
    _uid number
    _name string
    _head_icon number
    _level number
    _power number
    _time number
}

alliance_apply_map <number, alliance_apply>

alliance_data {
    _alliance_id number
    _name string
    _flag number
    _level number
    _exp number
    _join_type number
    _notice string
    _manifesto string
    _leader_id number
    _create_time number
    _members alliance_member_map
    _applies alliance_apply_map
}
