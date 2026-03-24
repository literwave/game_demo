# Game Demo Framework

基于 [Skynet](https://github.com/cloudwu/skynet) 的 Lua 游戏服务端框架。  
目标是提供一套可运行、可扩展的后端骨架，覆盖登录、网关、玩家逻辑、存储与基础运维能力。

## 框架定位

- 用于学习和实践 Skynet Actor 架构
- 用于快速搭建玩法原型和中小型项目服务端
- 适合作为二次开发底座，不是开箱即用的商业全量方案

## 核心架构

### 进程内服务拓扑

主入口 `start_up/main_start.lua` 启动以下服务：

- `logind`：登录服务（Master/Slave 模式）
- `gated`：WebSocket 网关，负责连接管理和消息转发
- `agent`：玩家业务执行单元（由 `gated` 动态创建池）
- `gameserver`：全局游戏业务协调（登录/登出通知等）
- `main_mongodb`：MongoDB 访问封装，注册为 `.mongodb`
- `game_sid`：玩家 ID 管理
- `load_xls`：配置加载
- `mcs`：HTTP 服务
- `gamelog`、`mail`、`mapserver`：日志/邮件/地图服务

### 登录与消息链路

1. 客户端连接 `logind`（WebSocket）
2. `logind` 校验账号，签发短期 token 并返回可用 gate 地址
3. 客户端带 token 连接 `gated`
4. `gated` 从 Redis 校验 token，并按负载分配 `agent`
5. 后续业务包由 `gated -> agent` 分发；存档通过 `.mongodb`

## 并发模型

- `gated` 维护 `AGENT_POOLS`，按 `userCnt` 选择较空闲的 agent
- `agent` 内为每个 `userId` 建独立 `queue()`，实现：
  - 同一玩家请求串行
  - 不同玩家请求并行
- 连接关闭/异常时，`gated` 会回收连接并下发 `disconnect`

## 协议与通信

- 传输协议：WebSocket（二进制）
- 序列化：protobuf
- 包结构：长度头 + 协议 ID + protobuf 数据
- 协议映射：`3rd/server/proto/netPb.lua`
- 常见协议文件：`3rd/server/proto/pb/*.pb`

## 目录说明

```text
game_demo/
|-- start_up/                         # 启动入口（main_start.lua）
|-- config/                           # 节点配置（main_node/test_node）
|-- logic/
|   |-- service/                      # Skynet 服务实现
|   |   |-- logind/                   # 登录服务
|   |   |-- gated/                    # 网关服务
|   |   |-- agent/                    # 玩家服务
|   |   |-- gameserver/               # 业务协调服务
|   |   `-- main_mongodb/             # Mongo 封装服务
|   |-- module/                       # 通用业务模块
|   |-- define/                       # 常量/数据定义
|   `-- base/                         # 框架基础工具
|-- common/                           # preload、master/slave 通用逻辑
|-- shell/                            # 启动、测试、数据库脚本
|-- 3rd/server/proto/                 # pb 与映射文件
|-- skynet/                           # Skynet 源码
`-- docs/                             # 设计与扩展文档
```

## 快速启动

### 1) 编译 Skynet

```bash
cd skynet
make linux
# macOS: make macosx
```

### 2) 配置服务

编辑 `config/main_node`，重点检查：

- `host_id`
- `gate_port` / `login_port` / `http_port`
- `agent_init_cnt` / `agent_max_user_cnt`
- `mongodb_host` / `mongodb_port` / `mongodb_user` / `mongodb_password`
- `redis_host` / `redis_port` / `redis_password`
- `protocol`（默认 `ws`）

### 3) 启动数据库（可选脚本）

```bash
bash shell/start_db.sh
```

> `start_db.sh` 使用固定安装路径模板，需先改成你机器上的 MongoDB/Redis 路径。

### 4) 启动主节点

```bash
bash shell/start.sh
```

### 5) 启动测试节点（可选）

```bash
bash shell/runtest.sh
```

## 常用脚本

- `shell/start.sh`：启动主节点（`config/main_node`）
- `shell/runtest.sh`：启动测试节点（`config/test_node`）
- `shell/start_db.sh`：启动 MongoDB、Redis
- `shell/stop_db.sh`：停止 MongoDB、Redis
- `shell/drop_db.sh`：清空 Mongo 业务库和 Redis

## 开发扩展指南

### 新增服务

1. 在 `logic/service/` 下新增服务目录和入口文件
2. 在服务中实现 `CMD` + `skynet.dispatch`
3. 在 `start_up/main_start.lua` 注册启动

### 新增 Agent 玩法模块

1. 在 `logic/service/agent/module/` 新增模块
2. 在对应模块管理器`logic/service/agent/global.lua` 中注册处理函数
3. 需要持久化时统一走 `.mongodb` 服务

### 通信建议

- 有返回值使用 `skynet.call`
- 无返回值使用 `skynet.send`
- 高频逻辑避免阻塞式数据库调用

## 已知运行注意点

- 运行环境建议 Linux/macOS（Windows 使用 WSL）
- Redis token 过期时间由登录服控制（当前默认 300 秒）
- 多 gate 分配策略在登录阶段主要按随机可用节点选择

## 相关文档

- [FRAMEWORK_REVIEW.md](FRAMEWORK_REVIEW.md)
- [PERFORMANCE_ANALYSIS.md](PERFORMANCE_ANALYSIS.md)
- [docs/GATE_SCALING.md](docs/GATE_SCALING.md)

## License

MIT（遵循 Skynet 及相关依赖的许可证）。
