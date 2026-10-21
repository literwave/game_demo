# building persist (agent USER_BUILD_COL.dat)
# map 的 number key（bid）落库为字符串，加载时按类型还原

build_data {
	_user_id number
	_bid number
	_level number
}

build_bag <number, build_data>

user_build_doc {
	_builds build_bag
}
