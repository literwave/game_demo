# item persist (agent USER_ITEM_COL.dat)

ItemData {
    _itemId string
    _itemType number
    _userId string
    _itemCnt number
    _strengthenLv number
    _strengthenExp number
    _forgeLv number
    _putOnHeroType number
}

ItemBag <string, ItemData>

UserItemDoc {
    _items ItemBag
}
