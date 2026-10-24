-- 本目录 Lua 的 SHA256 与地图版本。服务端记录 mapRevision，不要和旧版点位混用。
-- 配置表 ResLand、ResLandType 由 game_common 的 server/res 提供，不在此包内。

return {
    ["schemaVersion"] = 2,
    ["mapRevision"] = "635e6e505d56efae39e63c369743e8e4397d17d70b035ab58e83fc781d799e72",
    ["width"] = 1000,
    ["height"] = 1000,
    ["cellIdFormula"] = "y * 1000 + x",
    ["listAccess"] = "list[cellId][1]=type, list[cellId][2]=level",
    ["fixedBirthResourceCount"] = 6069,
    ["fixedBirthLevels"] = {
4,5,6
},
    ["fixedInnerResourceCount"] = 658,
    ["resourceLayoutVersion"] = 3,
    ["files"] = {
        ["campaign-map.lua"] = "0aa938f7e2cf75ae015fea2d85a1b8f74c64bd367d9f284b7b8c7a11b43ada3c",
        ["mapRes_0.lua"] = "868856090e417ef3d80ee891fe172520b49765c8b39077bcf22deed98a69056b",
        ["terrain.lua"] = "2a3026164b45cebf0776419e4e90b1f89658a329878716e314ab8b4f3322a689"
    }
}
