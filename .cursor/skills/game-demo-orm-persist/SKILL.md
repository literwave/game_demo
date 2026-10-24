---
name: game-demo-orm-persist
description: >-
  Guides Game Demo Framework ORM schema, Mongo persistence, and gameplay Lua style.
  Use when adding/changing .td schemas, clsXxx _data, saveDoc/saveDocField,
  mongo_slave persist, migrating modules off opMongoValue/@ paths, or writing
  game logic that checks or sends protocol fields. Protocol files live in the
  game_common submodule and must be pulled, not edited here.
---

# Game Demo ORM 存盘

## 原则

- **OOP 管行为**（`clsObject:Inherit()`），**ORM 管可落库数据**（`self._data`）
- Mongo 路径**禁止**纯数字段；**禁止** `@` 前缀
- `map <number, …>`：内存 number key，`ORM.dump` 转字符串，加载按 schema 还原

## 新增可存盘模块

1. 在 `orm/schema/<name>.td` 写类型（原子类型用 `number` / `string` / `boolean`）
2. 若有「id 当 key 的包」，用命名字段挂 map，例如 `_items` / `_heroes` / `_queues`
3. 把文件名加入 `orm/init.lua` 的 `SCHEMA_FILES`，并导出 `CLS_*` 常量。被引用的类型要写在引用者前面
4. `clsXxx:__init__`：`self._data = ORM.new(CLS_*, oci)`（oci 已是该类型 orm 对象时原样返回）
5. mgr 加载用 `local doc, is_loaded = ORM.load(MONGO_SLAVE.COL.XXX, id, CLS_*_DOC)`，`is_loaded` 为 true 时遍历 bag 建对象。集合名只用 `logic/base/mongo_slave.lua` 里的 `COL` 枚举。子对象在 `__init__` 里直接赋值挂进文档：`ORM.get(col, id)._heroes[k] = self._data`，删除赋 `nil`。不要在模块里再存一份 doc 表。改字段会把根标脏，`flush` 整包写回；下线 `ORM.unbind(col, id)`
6. 不要再写 `save_col.lua`、`persist*` 或在 setter 里 `saveField`。删整份独立文档仍用 `delDoc`

## 协议

- 不改 `game_common` 里的协议。`.proto`、`.pb`、`net_pb.lua`，以及 `ptotools` 下的协议描述，都不要在这个仓库里改
- 协议只通过子模块拉取：`git submodule update --init --remote game_common`。不要不带路径的 `--remote`，那会把 `skynet` 拉离开钉住的版本
- 业务可以先加字段。存盘 schema、对象的 getter/setter、发给客户端的 table 里可以先写上新字段。子模块的 pb 还没有该字段时，编码会报未知字段；等协议仓库提交后再拉取，不要为了能发出去去改 pb

## 禁止

- `opMongoValue` / `string.format("@%s", field)` / `removePreString`
- `$set` 路径形如 `dat.1001.xxx` 或 `dat.@1001.xxx`
- 把玩法方法挂到 orm 对象上，或用 orm 替换 `clsObject`
- 不要用 `type()` 判断一个变量的类型。协议字段和配置值按约定直接用，范围判断写 `pos < 1` 这种比较即可

## 参考形状

```text
UserItemDoc { _items <number, ItemData> }
UserHeroDoc { _heroes <number, HeroData> }
UserQueueDoc { _queues <number, QueueData> }
UserBuildDoc { _builds <number, BuildData> }
```

核心库：`lualib/orm`；游戏入口：`Import("../orm/init.lua")` → `ORM`。
落库：`ORM.bind` 之后标脏，由 `logic/base/mongo_slave.lua` 刷出。
