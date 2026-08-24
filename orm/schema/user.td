# user persist schema (agent USER_INFO_COL.dat)
# map key number 落库为字符串，加载时由 orm 按类型还原，无需 @ 前缀

ResMap <number, number>

SdkParamMap <string, string>

UserData {
    _userId string
    _birthTime number
    _loginTime number
    _bornServerId number
    _name string
    _sex number
    _sdkParamTbl SdkParamMap
    _resTbl ResMap
    _realDiamond number
    _giftDiamond number
    _sumRechargeDiamond number
    _headIcon number
    _lotteryTimes number
}
