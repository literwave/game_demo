---
name: game-demo-orm-persist
description: >-
  Guides Game Demo Framework ORM schema and Mongo persistence without @ number-key
  prefixes. Use when adding/changing .td schemas, clsXxx _data, saveDoc/saveDocField,
  mongo_slave persist, or migrating modules off opMongoValue/@ paths.
---

# Game Demo ORM 存盘

## 原则

- **OOP 管行为**（`clsObject:Inherit()`），**ORM 管可落库数据**（`self._data`）
- Mongo 路径**禁止**纯数字段；**禁止** `@` 前缀
- `map <number, …>`：内存 number key，`ORM.dump` 转字符串，加载按 schema 还原

## 新增可存盘模块

1. 在 `orm/schema/<name>.td` 写类型（原子类型用 `number` / `string` / `boolean`）
2. 若有「id 当 key 的包」，用命名字段挂 map，例如 `_items` / `_heroes` / `_queues`
3. 把文件名加入 `orm/init.lua` 的 `SCHEMA_FILES`，并导出 `CLS_*` 常量
4. `clsXxx:__init__`：`self._data = ORM.create(CLS_*, oci)`（已是 orm 对象则直接挂）
5. 加载时 `ORM.hold(doc, MONGO_SLAVE.COL.XXX, id)`。集合名只用 `logic/base/mongo_slave.lua` 里的 `COL` 枚举。子对象在 `__init__` 里 `ORM.put` 挂进文档，删除用 `ORM.remove`。不要在模块里再存一份 doc 表。改字段会把根标脏，`flush` 整包写回
6. 不要再写 `save_col.lua`、`persist*` 或在 setter 里 `saveField`。删整份独立文档仍用 `delDoc`

## 禁止

- `opMongoValue` / `string.format("@%s", field)` / `removePreString`
- `$set` 路径形如 `dat.1001.xxx` 或 `dat.@1001.xxx`
- 把玩法方法挂到 orm 对象上，或用 orm 替换 `clsObject`

## 参考形状

```text
UserItemDoc { _items <string, ItemData> }
UserHeroDoc { _heroes <number, HeroData> }
UserQueueDoc { _queues <number, QueueData> }
UserBuildDoc { _builds <number, BuildData> }
```

核心库：`lualib/orm`；游戏入口：`Import("../orm/init.lua")` → `ORM`。
落库：`ORM.bind` 之后标脏，由 `logic/base/mongo_slave.lua` 刷出。
