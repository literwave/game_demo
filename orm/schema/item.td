# item persist (agent USER_ITEM_COL.dat)

item_data {
    _item_id string
    _item_type number
    _user_id string
    _item_cnt number
    _strengthen_lv number
    _strengthen_exp number
    _forge_lv number
    _put_on_hero_type number
}

item_bag <string, item_data>

user_item_doc {
    _items item_bag
}
