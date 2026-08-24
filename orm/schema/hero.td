# hero persist schema (agent USER_HERO_COL.dat)
# 文档形状: { _heroes: { "heroType": HeroData, ... } }
# map 的 number key 落库为字符串，加载时按类型还原，路径中不出现数字段

SkillMap <number, number>
EquipMap <number, number>

HeroData {
    _heroType number
    _userId string
    _exp number
    _level number
    _star number
    _equipTbl EquipMap
    _skillTbl SkillMap
    _newTag boolean
    _state number
}

HeroBag <number, HeroData>

UserHeroDoc {
    _heroes HeroBag
}
