# troop persist (agent USER_TROOP_COL.dat)
# pos_hero_map: 站位 -> 英雄id

pos_hero_map <number, number>

troop_data {
    _user_id number
    _troop_idx number
    _pos_hero_tbl pos_hero_map
}

troop_bag <number, troop_data>

user_troop_doc {
    _troops troop_bag
}
