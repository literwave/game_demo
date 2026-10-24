-- 州域、关口、城池和建议出生区。出生点按容量分配玩家并保持间距。
-- footprintRadius 为方形占地半径：出生州 1 即 3×3，资源州 2 即 5×5，洛阳 4 即 9×9。

return {
    ["version"] = 1,
    ["title"] = "千里山河 · 破关逐鹿",
    ["width"] = 1000,
    ["height"] = 1000,
    ["seed"] = 20261024,
    ["fixedBirthResourceCount"] = 6069,
    ["fixedBirthLevels"] = {
4,5,6
},
    ["birthResourceMinDistance"] = {
        ["all"] = 8,
        ["advanced"] = 28,
        ["level6"] = 48
    },
    ["resourceLayoutVersion"] = 3,
    ["fixedInnerResourceCount"] = 658,
    ["innerResourceSpacing"] = {
        ["6"] = {
            ["6"] = 14,
            ["7"] = 26,
            ["8"] = 42
        },
        ["7"] = {
            ["6"] = 14,
            ["7"] = 26,
            ["8"] = 42
        },
        ["8"] = {
            ["6"] = 14,
            ["7"] = 26,
            ["8"] = 42
        },
        ["9"] = {
            ["7"] = 12,
            ["8"] = 22,
            ["9"] = 36
        }
    },
    ["regions"] = {
        {
            ["id"] = 0,
            ["name"] = "青州",
            ["tier"] = 0,
            ["color"] = "#7eaf90",
            ["x"] = 833,
            ["y"] = 692
        },
        {
            ["id"] = 1,
            ["name"] = "徐州",
            ["tier"] = 0,
            ["color"] = "#c2b679",
            ["x"] = 500,
            ["y"] = 884
        },
        {
            ["id"] = 2,
            ["name"] = "荆州",
            ["tier"] = 0,
            ["color"] = "#b5a079",
            ["x"] = 166,
            ["y"] = 692
        },
        {
            ["id"] = 3,
            ["name"] = "益州",
            ["tier"] = 0,
            ["color"] = "#8ca782",
            ["x"] = 166,
            ["y"] = 307
        },
        {
            ["id"] = 4,
            ["name"] = "凉州",
            ["tier"] = 0,
            ["color"] = "#829da7",
            ["x"] = 499,
            ["y"] = 114
        },
        {
            ["id"] = 5,
            ["name"] = "幽州",
            ["tier"] = 0,
            ["color"] = "#a0a1bb",
            ["x"] = 833,
            ["y"] = 307
        },
        {
            ["id"] = 6,
            ["name"] = "河东",
            ["tier"] = 1,
            ["color"] = "#b99862",
            ["x"] = 594,
            ["y"] = 664
        },
        {
            ["id"] = 7,
            ["name"] = "关中",
            ["tier"] = 1,
            ["color"] = "#aa8066",
            ["x"] = 310,
            ["y"] = 500
        },
        {
            ["id"] = 8,
            ["name"] = "河内",
            ["tier"] = 1,
            ["color"] = "#8ca7a1",
            ["x"] = 594,
            ["y"] = 335
        },
        {
            ["id"] = 9,
            ["name"] = "王畿",
            ["tier"] = 2,
            ["color"] = "#d3b56a",
            ["x"] = 500,
            ["y"] = 500
        }
    },
    ["gates"] = {
        {
            ["id"] = "pass-01",
            ["name"] = "临淄关",
            ["x"] = 746,
            ["y"] = 642,
            ["regions"] = {
0,6
},
            ["level"] = 5
        },
        {
            ["id"] = "pass-02",
            ["name"] = "广陵关",
            ["x"] = 500,
            ["y"] = 784,
            ["regions"] = {
1,6
},
            ["level"] = 5
        },
        {
            ["id"] = "pass-03",
            ["name"] = "江陵关",
            ["x"] = 253,
            ["y"] = 642,
            ["regions"] = {
2,7
},
            ["level"] = 5
        },
        {
            ["id"] = "pass-04",
            ["name"] = "剑门关",
            ["x"] = 253,
            ["y"] = 357,
            ["regions"] = {
3,7
},
            ["level"] = 5
        },
        {
            ["id"] = "pass-05",
            ["name"] = "玉门关",
            ["x"] = 499,
            ["y"] = 214,
            ["regions"] = {
4,8
},
            ["level"] = 5
        },
        {
            ["id"] = "pass-06",
            ["name"] = "雁门关",
            ["x"] = 746,
            ["y"] = 357,
            ["regions"] = {
5,8
},
            ["level"] = 5
        },
        {
            ["id"] = "pass-07",
            ["name"] = "虎牢关",
            ["x"] = 550,
            ["y"] = 586,
            ["regions"] = {
6,9
},
            ["level"] = 8
        },
        {
            ["id"] = "pass-08",
            ["name"] = "函谷关",
            ["x"] = 400,
            ["y"] = 500,
            ["regions"] = {
7,9
},
            ["level"] = 8
        },
        {
            ["id"] = "pass-09",
            ["name"] = "孟津关",
            ["x"] = 550,
            ["y"] = 413,
            ["regions"] = {
8,9
},
            ["level"] = 8
        },
        {
            ["id"] = "pass-10",
            ["name"] = "东海隘",
            ["x"] = 904,
            ["y"] = 500,
            ["regions"] = {
5,0
},
            ["level"] = 4
        },
        {
            ["id"] = "pass-11",
            ["name"] = "淮南隘",
            ["x"] = 702,
            ["y"] = 850,
            ["regions"] = {
0,1
},
            ["level"] = 4
        },
        {
            ["id"] = "pass-12",
            ["name"] = "巴蜀隘",
            ["x"] = 297,
            ["y"] = 850,
            ["regions"] = {
1,2
},
            ["level"] = 4
        },
        {
            ["id"] = "pass-13",
            ["name"] = "陇西隘",
            ["x"] = 94,
            ["y"] = 500,
            ["regions"] = {
2,3
},
            ["level"] = 4
        },
        {
            ["id"] = "pass-14",
            ["name"] = "朔方隘",
            ["x"] = 297,
            ["y"] = 149,
            ["regions"] = {
3,4
},
            ["level"] = 4
        },
        {
            ["id"] = "pass-15",
            ["name"] = "渔阳隘",
            ["x"] = 702,
            ["y"] = 149,
            ["regions"] = {
4,5
},
            ["level"] = 4
        },
        {
            ["id"] = "pass-16",
            ["name"] = "蒲坂渡",
            ["x"] = 690,
            ["y"] = 500,
            ["regions"] = {
8,6
},
            ["level"] = 6
        },
        {
            ["id"] = "pass-17",
            ["name"] = "武关",
            ["x"] = 405,
            ["y"] = 664,
            ["regions"] = {
6,7
},
            ["level"] = 6
        },
        {
            ["id"] = "pass-18",
            ["name"] = "潼关",
            ["x"] = 404,
            ["y"] = 335,
            ["regions"] = {
7,8
},
            ["level"] = 6
        }
    },
    ["cities"] = {
        {
            ["name"] = "青州州府",
            ["x"] = 833,
            ["y"] = 692,
            ["level"] = 4,
            ["region"] = 0,
            ["footprintRadius"] = 1,
            ["art"] = "town"
        },
        {
            ["name"] = "徐州州府",
            ["x"] = 500,
            ["y"] = 884,
            ["level"] = 4,
            ["region"] = 1,
            ["footprintRadius"] = 1,
            ["art"] = "town"
        },
        {
            ["name"] = "荆州州府",
            ["x"] = 166,
            ["y"] = 692,
            ["level"] = 4,
            ["region"] = 2,
            ["footprintRadius"] = 1,
            ["art"] = "town"
        },
        {
            ["name"] = "益州州府",
            ["x"] = 166,
            ["y"] = 307,
            ["level"] = 4,
            ["region"] = 3,
            ["footprintRadius"] = 1,
            ["art"] = "town"
        },
        {
            ["name"] = "凉州州府",
            ["x"] = 499,
            ["y"] = 114,
            ["level"] = 4,
            ["region"] = 4,
            ["footprintRadius"] = 1,
            ["art"] = "town"
        },
        {
            ["name"] = "幽州州府",
            ["x"] = 833,
            ["y"] = 307,
            ["level"] = 4,
            ["region"] = 5,
            ["footprintRadius"] = 1,
            ["art"] = "town"
        },
        {
            ["name"] = "河东都城",
            ["x"] = 594,
            ["y"] = 664,
            ["level"] = 7,
            ["region"] = 6,
            ["footprintRadius"] = 2,
            ["art"] = "county"
        },
        {
            ["name"] = "关中都城",
            ["x"] = 310,
            ["y"] = 500,
            ["level"] = 7,
            ["region"] = 7,
            ["footprintRadius"] = 2,
            ["art"] = "county"
        },
        {
            ["name"] = "河内都城",
            ["x"] = 594,
            ["y"] = 335,
            ["level"] = 7,
            ["region"] = 8,
            ["footprintRadius"] = 2,
            ["art"] = "county"
        },
        {
            ["name"] = "洛阳",
            ["x"] = 500,
            ["y"] = 500,
            ["level"] = 10,
            ["region"] = 9,
            ["footprintRadius"] = 4,
            ["art"] = "capital"
        }
    },
    ["spawnZones"] = {
        {
            ["x"] = 24,
            ["y"] = 24,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 24,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 24,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 168,
            ["y"] = 24,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 264,
            ["y"] = 24,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 312,
            ["y"] = 24,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 360,
            ["y"] = 24,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 408,
            ["y"] = 24,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 456,
            ["y"] = 24,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 504,
            ["y"] = 24,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 552,
            ["y"] = 24,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 600,
            ["y"] = 24,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 648,
            ["y"] = 24,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 696,
            ["y"] = 24,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 744,
            ["y"] = 24,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 840,
            ["y"] = 24,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 24,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 24,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 72,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 72,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 72,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 168,
            ["y"] = 72,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 216,
            ["y"] = 72,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 312,
            ["y"] = 72,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 360,
            ["y"] = 72,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 408,
            ["y"] = 72,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 456,
            ["y"] = 72,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 504,
            ["y"] = 72,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 552,
            ["y"] = 72,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 600,
            ["y"] = 72,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 648,
            ["y"] = 72,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 696,
            ["y"] = 72,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 792,
            ["y"] = 72,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 840,
            ["y"] = 72,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 72,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 72,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 120,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 120,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 120,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 168,
            ["y"] = 120,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 216,
            ["y"] = 120,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 312,
            ["y"] = 120,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 360,
            ["y"] = 120,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 408,
            ["y"] = 120,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 456,
            ["y"] = 120,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 552,
            ["y"] = 120,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 600,
            ["y"] = 120,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 648,
            ["y"] = 120,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 696,
            ["y"] = 120,
            ["region"] = 4,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 744,
            ["y"] = 120,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 792,
            ["y"] = 120,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 840,
            ["y"] = 120,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 120,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 120,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 168,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 168,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 168,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 168,
            ["y"] = 168,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 216,
            ["y"] = 168,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 264,
            ["y"] = 168,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 744,
            ["y"] = 168,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 792,
            ["y"] = 168,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 840,
            ["y"] = 168,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 168,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 168,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 216,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 216,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 216,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 168,
            ["y"] = 216,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 216,
            ["y"] = 216,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 792,
            ["y"] = 216,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 840,
            ["y"] = 216,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 216,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 216,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 264,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 264,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 264,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 168,
            ["y"] = 264,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 840,
            ["y"] = 264,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 264,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 264,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 312,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 312,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 312,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 312,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 312,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 360,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 360,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 360,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 360,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 360,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 408,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 408,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 408,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 408,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 408,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 456,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 456,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 456,
            ["region"] = 3,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 456,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 456,
            ["region"] = 5,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 552,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 552,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 552,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 552,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 552,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 600,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 600,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 600,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 600,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 600,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 648,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 648,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 648,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 648,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 648,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 696,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 696,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 696,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 696,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 696,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 744,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 744,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 744,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 168,
            ["y"] = 744,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 792,
            ["y"] = 744,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 840,
            ["y"] = 744,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 744,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 744,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 792,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 792,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 792,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 168,
            ["y"] = 792,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 216,
            ["y"] = 792,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 744,
            ["y"] = 792,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 792,
            ["y"] = 792,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 840,
            ["y"] = 792,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 792,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 792,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 840,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 840,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 840,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 168,
            ["y"] = 840,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 216,
            ["y"] = 840,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 264,
            ["y"] = 840,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 744,
            ["y"] = 840,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 792,
            ["y"] = 840,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 840,
            ["y"] = 840,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 840,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 840,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 888,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 888,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 888,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 168,
            ["y"] = 888,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 216,
            ["y"] = 888,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 312,
            ["y"] = 888,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 360,
            ["y"] = 888,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 408,
            ["y"] = 888,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 456,
            ["y"] = 888,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 552,
            ["y"] = 888,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 600,
            ["y"] = 888,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 648,
            ["y"] = 888,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 696,
            ["y"] = 888,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 792,
            ["y"] = 888,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 840,
            ["y"] = 888,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 888,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 888,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 24,
            ["y"] = 936,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 72,
            ["y"] = 936,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 120,
            ["y"] = 936,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 168,
            ["y"] = 936,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 216,
            ["y"] = 936,
            ["region"] = 2,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 312,
            ["y"] = 936,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 360,
            ["y"] = 936,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 408,
            ["y"] = 936,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 456,
            ["y"] = 936,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 504,
            ["y"] = 936,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 552,
            ["y"] = 936,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 600,
            ["y"] = 936,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 648,
            ["y"] = 936,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 696,
            ["y"] = 936,
            ["region"] = 1,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 792,
            ["y"] = 936,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 840,
            ["y"] = 936,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 888,
            ["y"] = 936,
            ["region"] = 0,
            ["safeRadius"] = 12
        },
        {
            ["x"] = 936,
            ["y"] = 936,
            ["region"] = 0,
            ["safeRadius"] = 12
        }
    },
    ["stages"] = {
        "立足出生州，发展资源与同盟",
        "铺路至关口，集结攻关",
        "控制资源州，争夺渡口与都城",
        "突破王畿三关，会战洛阳"
    }
}
