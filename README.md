# Game Demo Framework

基于 [Skynet](https://github.com/cloudwu/skynet) 的 Lua 游戏服务端骨架。

面向学习、原型验证与中小型玩法服务端二次开发，提供可运行的登录、网关、玩家逻辑、持久化与基础运维能力。

> **不是**开箱即用的商业全量方案。请先读完 [快速开始](#快速开始) 与 [架构总览](#架构总览)。

---

## 目录

- [特性](#特性)
- [技术栈](#技术栈)
- [架构总览](#架构总览)
- [仓库结构](#仓库结构)
- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [数据与 ORM](#数据与-orm)
- [开发指南](#开发指南)
- [脚本一览](#脚本一览)
- [文档索引](#文档索引)
- [已知限制](#已知限制)
- [License](#license)

---

## 特性

| 能力 | 说明 |
|------|------|
| Actor 服务拆分 | 登录 / 网关 / Agent / 全局业务 / DB 职责清晰 |
| WebSocket 网关 | 二进制帧 + protobuf，适合实时客户端 |
| 玩家级串行队列 | 同 `userId` 串行、跨玩家并行，降低竞态 |
| Agent 池 | `gated` 按负载分配 agent，支持水平扩连接 |
| MongoDB 持久化 | 统一走 `.mongodb`；业务侧 schema 驱动存盘 |
| 配置热加载入口 | `load_xls` + 导表产物 |

---

## 技术栈

- **运行时**：Skynet（Lua 5.4）
- **传输**：WebSocket
- **协议**：Protobuf（`3rd/server/proto`）
- **存储**：MongoDB、Redis（登录 token 等）
- **数据模型**：自研精简 ORM（`skynet/lualib/orm` + `orm/schema/*.td`）

---

## 架构总览

### 服务拓扑

入口：`start_up/main_start.lua`

```text
                    +-----------+
                    |  Client   |
                    +-----+-----+
                          |
            WebSocket     |     WebSocket
         (login_port)     |    (gate_port)
                          v
                    +-----------+         +------------+
                    |  logind   | ------> |   Redis    |  (token)
                    +-----+-----+         +------------+
                          | 签发 token + gate 地址
                          v
                    +-----------+
                    |   gated   |  连接管理 / 转发 / Agent 池
                    +-----+-----+
                          |
              +-----------+-----------+
              v           v           v
          +-------+   +-------+   +-------+
          | agent |   | agent |   |  ...  |  玩家业务
          +---+---+   +---+---+   +---+---+
              |           |
              +-----+-----+
                    v
            +---------------+     +------------+
            | main_mongodb  | --> |  MongoDB   |
            |   (.mongodb)  |     +------------+
            +---------------+

  旁路服务: gameserver / game_sid / mail / mapserver / mcs(HTTP) / gamelog / load_xls
```

### 登录与消息链路

1. 客户端连接 **logind**，完成账号校验  
2. logind 写入 Redis token，返回可用 **gate** 地址  
3. 客户端携带 token 连接 **gated**  
4. gated 校验 token，按负载分配 **agent**  
5. 业务包：`gated → agent`；存档：`agent → .mongodb`

### 并发约定

- **gated**：维护 `AGENT_POOLS`，优先选择玩家数较少的 agent  
- **agent**：每个 `userId` 独立 `queue()` —— 同玩家串行，异玩家并行  
- 断线 / 异常时由 gated 回收连接并通知 `disconnect`

---

## 仓库结构

```text
game_demo/
├── README.md                 # 本文件
├── start_up/                 # Skynet 启动脚本
│   └── main_start.lua
├── config/                   # 节点配置
│   ├── main_node             # 主节点
│   └── test_node             # 测试节点
├── shell/                    # 启停 / 编译 / 清库脚本
├── logic/
│   ├── service/              # Skynet 服务实现
│   │   ├── logind/           # 登录
│   │   ├── gated/            # 网关
│   │   ├── agent/            # 玩家逻辑（模块在 module/ 下）
│   │   ├── gameserver/       # 全局协调
│   │   ├── main_mongodb/     # Mongo 访问（注册 .mongodb）
│   │   ├── game_sid/         # 玩家 ID
│   │   ├── mail/ mapserver/ mcs/ ...
│   ├── define/               # 常量与表数据访问
│   └── base/                 # OOP / 工具基础库
├── common/                   # preload、Import、通用工具
├── orm/
│   ├── init.lua              # 游戏侧 ORM 入口（加载 .td）
│   └── schema/               # 持久化 schema（user.td / hero.td）
├── skynet/                   # Skynet 及 lualib（含 orm 核心）
│   └── lualib/orm/           # create / dump / typedef
├── 3rd/server/               # protobuf、导表配置等
├── docs/                     # 专题设计文档
└── test/                     # 简易客户端 / 联调脚本
```

---

## 环境要求

| 项目 | 建议 |
|------|------|
| OS | Linux / macOS；Windows 请用 **WSL2** |
| 编译器 | gcc / clang（按 Skynet 文档） |
| 依赖服务 | MongoDB、Redis |
| 网络 | 默认可本机：`login 33021` / `gate 33022` / `http 33023` |

---

## 快速开始

### 1. 获取代码

```bash
git clone <your-repo-url> game_demo
cd game_demo
```

### 2. 编译 Skynet

编译产物（`skynet/skynet`、`luaclib/*.so` 等）已加入 `.gitignore`，克隆后需本地编译：

```bash
cd skynet
make linux          # macOS: make macosx
cd ..
```

确认存在可执行文件：`skynet/skynet`。

### 3. 准备 MongoDB / Redis

```bash
# 脚本内路径多为模板，请先改成你机器上的安装路径
bash shell/start_db.sh
```

### 4. 修改配置

编辑 [`config/main_node`](config/main_node)，至少核对：

- `host_id`
- `gate_port` / `login_port` / `http_port`
- `mongodb_*` / `redis_*`
- `agent_init_cnt` / `agent_max_user_cnt`
- `protocol`（默认 `ws`）

### 5. 启动主节点

```bash
bash shell/start.sh
```

看到 ASCII logo / `server start` 相关日志即表示主链路已拉起。

### 6.（可选）测试节点

```bash
bash shell/runtest.sh
```

---

## 配置说明

主配置文件：`config/main_node`（相对 `skynet/` 目录加载）。

| 配置项 | 含义 |
|--------|------|
| `host_id` | 本服 ID |
| `gate_port` / `login_port` / `http_port` | 网关 / 登录 / HTTP |
| `agent_init_cnt` | 启动时预创建 agent 数 |
| `agent_max_user_cnt` | 单 agent 建议承载上限 |
| `mongodb_*` | Mongo 连接 |
| `redis_*` | Redis 连接 |
| `rootdir` / `workdir` | 工程与 logic 相对路径 |

测试配置见 `config/test_node`。

---

## 数据与 ORM

持久化采用 **schema + OOP 行为分离**：

- **Schema**：`orm/schema/*.td` 描述可落库结构（`number` / `string` / `boolean` / `struct` / `list` / `map`）
- **核心库**：`skynet/lualib/orm`（`create` / `dump` / `dump_field`）
- **游戏入口**：`Import("../orm/init.lua")` → 全局 `ORM`
- **行为类**：`clsUser` / `clsHero` 等通过 `self._data` 持有 ORM 对象，方法仍用 `clsObject:Inherit()`

约定：

1. Mongo 文档字段名只能是字符串；`map <number, …>` 的 key 在 **dump** 时转为字符串，**create** 时按 schema 还原为 number  
2. **不要**在 `$set` 路径中使用纯数字段（如 `dat.1001.xxx`）；用户英雄等挂在 `dat._heroes` 下整包更新  
3. 不兼容旧版 `@` 数字前缀存档；换库或清集合后使用  

示例（概念）：

```lua
self._data = ORM.create(ORM.CLS_USER_DATA, oci)
MONGO_SLAVE.saveDoc(col, userId, ORM.dump(self._data))
MONGO_SLAVE.saveDocField(col, userId, "_name", ORM.dump_field(self._data, "_name"))
```

新增可存盘类型：先写 `orm/schema/xxx.td`，再在 `orm/init.lua` 的 `SCHEMA_FILES` 中注册。

---

## 开发指南

### 新增 Skynet 服务

1. 在 `logic/service/<name>/` 增加入口与 `CMD`  
2. `skynet.dispatch("lua", …)` 处理消息  
3. 在 `start_up/main_start.lua` 中 `newservice` / `call` 启动  

### 新增 Agent 玩法模块

1. 在 `logic/service/agent/module/<mod>/` 增加 `base.lua` / `mgr.lua`  
2. 在 `logic/service/agent/global.lua` 中 `Import` 挂到全局（如 `FOO_MGR = Import(...)`）  
3. 需要落库时：补 `.td` → `self._data` → `saveDoc` / `saveDocField`  

### 进程间通信

| 场景 | API |
|------|-----|
| 需要返回值 | `skynet.call` |
| 单向通知 | `skynet.send` |
| 高频路径 | 避免同步打满 DB；批量或异步落盘 |

### 协议

- 包格式：`长度(2) + 协议ID(2) + protobuf`  
- 映射：`3rd/server/proto/netPb.lua`  
- `.pb` 文件：`3rd/server/proto/pb/`  

---

## 脚本一览

| 脚本 | 作用 |
|------|------|
| `shell/start.sh` | 启动主节点（`config/main_node`） |
| `shell/stop.sh` | 停止主节点 |
| `shell/restart.sh` | 重启主节点 |
| `shell/runtest.sh` | 启动测试节点 |
| `shell/start_db.sh` | 启动 MongoDB / Redis（需改路径） |
| `shell/stop_db.sh` | 停止 DB |
| `shell/restart_db.sh` | 重启 DB |
| `shell/drop_db.sh` | 清空业务库与 Redis（慎用） |

---

## 文档索引

| 文档 | 内容 |
|------|------|
| [FRAMEWORK_REVIEW.md](FRAMEWORK_REVIEW.md) | 架构评价与改进建议 |
| [PERFORMANCE_ANALYSIS.md](PERFORMANCE_ANALYSIS.md) | 性能与负载分析 |
| [docs/GATE_SCALING.md](docs/GATE_SCALING.md) | Gate 水平扩展方案 |

上游参考：[Skynet Wiki](https://github.com/cloudwu/skynet/wiki)

---

## 已知限制

- 面向教学 / 原型 / 中小型项目；大型 MMO 需补监控、压测与工程化  
- Redis 登录 token 默认约 **300s** 过期（以登录服实现为准）  
- 多 Gate 分配策略相对简单，扩展见 `docs/GATE_SCALING.md`

---

## License

本仓库示例代码可按 **MIT** 使用与修改；**Skynet** 及第三方组件请遵循其各自许可证。
