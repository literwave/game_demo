# building persist (agent USER_BUILD_COL.dat)
# map 的 number key（bid）落库为字符串，加载时按类型还原

BuildData {
	_userId string
	_bid number
	_level number
}

BuildBag <number, BuildData>

UserBuildDoc {
	_builds BuildBag
}
