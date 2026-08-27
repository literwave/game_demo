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
5. `saveField` / `saveToDB`：整包 `MGR.persist*(userId)` → `MONGO_SLAVE.saveDoc(col, id, ORM.dump(doc))`
6. 标量字段局部写：仅 `saveDocField(col, id, "fieldName", value)`，`fieldName` 不得 `tonumber` 成功

## 禁止

- `opMongoValue` / `string.format("@%s", field)` / `removePreString`
- `$set` 路径形如 `dat.1001.xxx` 或 `dat.@1001.xxx`
- 把玩法方法挂到 orm 对象上，或用 orm 替换 `clsObject`

## 参考形状

```text
UserItemDoc { _items <string, ItemData> }
UserHeroDoc { _heroes <number, HeroData> }
UserQueueDoc { _queues <number, QueueData> }
```

核心库：`skynet/lualib/orm`；游戏入口：`Import("../orm/init.lua")` → `ORM`。
