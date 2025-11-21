# Game Demo - Skynet 游戏服务器框架

基于 [Skynet](https://github.com/cloudwu/skynet) 开发的游戏服务器框架，采用 Actor 模型和 ECS 架构设计，支持高并发、分布式部署。

## 📋 目录

- [项目简介](#项目简介)
- [架构设计](#架构设计)
- [目录结构](#目录结构)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [核心服务](#核心服务)
- [协议系统](#协议系统)
- [数据库](#数据库)
- [开发指南](#开发指南)
- [常见问题](#常见问题)

## 🎯 项目简介

Game Demo 是一个基于 Skynet 框架的游戏服务器项目，具有以下特点：

- **高性能**: 基于 Skynet Actor 模型，支持高并发连接
- **模块化**: 采用 ECS 架构，代码结构清晰，易于维护
- **协议驱动**: 使用 Protobuf 进行协议定义和序列化
- **数据持久化**: 支持 MongoDB 数据库存储
- **分布式**: 支持多服务、多节点部署
- **可扩展**: 网关、Agent、登录服务等核心组件可独立扩展
- **共享数据守卫**: 内置 `sharedatad` 服务与封装接口，确保在 Skynet 初始化后再访问配置数据，避免 `skynet.call` 空指针

## 🏗️ 架构设计

### 整体架构

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
┌──────▼──────┐
│    Gate     │ ← 网关服务，处理客户端连接
└──────┬──────┘
       │
┌──────▼──────┐
│    Agent    │ ← 游戏逻辑服务，处理玩家业务
└──────┬──────┘
       │
┌──────▼──────┐
│  MongoDB    │ ← 数据持久化
└─────────────┘

┌─────────────┐
│   Logind    │ ← 登录服务（Master/Slave 模式）
└──────┬──────┘
       │
┌──────▼──────┐
│  MongoDB    │
└─────────────┘
```

### 核心服务

1. **Gate (网关服务)**
   - 处理客户端 TCP 连接
   - 消息路由和转发
   - 连接管理和负载均衡

2. **Agent (游戏逻辑服务)**
   - 玩家游戏逻辑处理
   - 基于 `queue()` 的“单用户串行、跨用户并行”协程模型
   - 用户状态管理
   - 消息分发和处理

3. **Logind (登录服务)**
   - Master/Slave 架构
   - 账号验证和用户创建
   - 登录流程管理

4. **MongoDB (数据服务)**
   - 数据持久化
   - 账号信息存储
   - 游戏数据管理

## 📁 目录结构

```
game_demo/
├── README.md / FRAMEWORK_REVIEW.md / PERFORMANCE_ANALYSIS.md  # 顶层文档
├── doc/                     # 设计 & 进度原始文档
├── docs/                    # 公共方案（如 GATE_SCALING）
├── config/                  # Skynet 配置
│   ├── main_node            # 线上/默认节点配置
│   └── test_node            # 测试节点配置
├── common/                  # 公共库
│   ├── master_func.lua      # 登录 Master 逻辑
│   ├── slave_func.lua       # 登录 Slave 逻辑
│   ├── master_handle.lua    # Master 消息分发
│   ├── slave_handle.lua     # Slave 消息分发
│   └── preload.lua          # 全局预加载入口
├── logic/                   # 业务代码
│   ├── base/                # 基础工具（netPb、Import 等）
│   ├── define/              # 常量 & 数据访问
│   ├── module/              # 玩法模块（account/login/user 等）
│   ├── service/             # Skynet 服务
│   │   ├── agent/           # 玩家逻辑服务
│   │   ├── gamelog/         # 日志写入
│   │   ├── gameserver/      # 游戏主逻辑聚合
│   │   ├── game_sid/        # 服务器 ID 管理
│   │   ├── gated/           # 网关
│   │   ├── http_agent/      # HTTP handler
│   │   ├── load_xls/        # 配置加载
│   │   ├── logind/          # 登录 Master/Slave
│   │   ├── main_mongodb/    # Mongo 访问封装
│   │   └── mcs/             # HTTP 服务（GM/运维）
│   └── protos/              # 旧版协议定义（保留）
├── proto/                   # Protobuf 文件
│   ├── pb/                  # 编译结果
│   └── *.proto              # 原始描述
├── read_config/             # 表格解析后的 Lua 数据
├── shell/                   # 启停脚本（start.sh / stop.sh / gen_proto.sh）
├── skynet/                  # 上游 Skynet 引擎
├── src/                     # 其他实验性代码
├── start_up/                # 启动入口（main_start.lua 等）
├── test/                    # 测试脚本
└── tools/                   # 工具链（ptotools、excel 导入等）
```

## 🚀 快速开始

### 环境要求

- Linux/macOS (Windows 需要 WSL 或 Git Bash)
- Lua 5.3+
- Python 3.x (用于协议生成)
- MongoDB (用于数据存储)
- GCC/Clang (编译 Skynet)

### 编译 Skynet

```bash
cd skynet
make linux  # Linux 系统
# 或 make macosx  # macOS 系统
```

### 配置数据库

编辑 `config/main_node`，修改 MongoDB 连接信息：

```lua
mongodb_host = "127.0.0.1"
mongodb_port = "27017"
mongodb_user = "root"
mongodb_password = "123"
```

### 生成协议

```bash
bash shell/gen_proto.sh
```

### 启动服务器

```bash
bash shell/start.sh
```

启动脚本会自动：
- 读取 `config/main_node`，拉起 `start_up/main_start.lua`
- 依次启动日志、登录、Mongo、Load XLS、Gate、HTTP（MCS）和 GameServer 等服务
- 在 `log/` 目录下输出运行日志，可通过 `tail -f log/skynet.log` 查看启动进度

### 测试登录

```bash
# 在另一个终端运行测试节点
cd skynet
./skynet ../config/test_node
```

## ⚙️ 配置说明

### 主配置文件 (config/main_node)

```lua
-- 基础配置
host_id = "120"            -- 服务器 ID
thread = 8                 -- Skynet 工作线程数
gate_port = 8888           -- 网关端口
login_port = 33021         -- 登录端口
http_port = 33022          -- HTTP 服务端口
https_port = 33023         -- HTTPS 服务端口

-- 登录服务配置
slave_cnt = 3              -- Slave 服务数量
maxonline = 2000           -- 最大在线人数
nodelay = true             -- TCP nodelay

-- Agent 配置
agent_init_cnt = 4         -- 初始 Agent 数量
agent_max_user_cnt = 500   -- 单个 Agent 最大用户数

-- 数据库配置
mongodb_host = "192.168.24.185"
mongodb_port = "27017"
mongodb_user = "root"
mongodb_password = "123"
```

## 🔧 核心服务

### Gate 服务

网关服务，负责客户端连接管理和消息路由。

**主要功能：**
- 接受客户端 TCP 连接
- 消息包解析和转发
- 连接状态管理
- Agent 负载均衡（当前默认单 Gate，可按 `docs/GATE_SCALING.md` 扩展多 Gate）

**关键代码：** `logic/service/gated/gated.lua`

### Agent 服务

游戏逻辑服务，处理玩家业务逻辑。

**主要功能：**
- 玩家登录和登出
- 游戏消息处理
- 用户状态管理
- 数据缓存

**关键代码：** `logic/service/agent/agent.lua`

### Logind 服务

登录服务，采用 Master/Slave 架构。

**Master 服务：**
- 监听登录端口
- 分配连接给 Slave
- 协调登录流程

**Slave 服务：**
- 处理具体登录请求
- 账号验证
- 用户创建

**关键代码：**
- Master: `common/master_func.lua`
- Slave: `common/slave_func.lua`

## 📡 协议系统

### 协议定义

协议使用 Protobuf 定义，存放在 `tools/ptotools/proto/proto_desc/` 目录。

示例 (`login.proto`):
```protobuf
syntax = "proto3";

package Login;

message c2splaylogin {
    string accountType = 1;
    string appId = 2;
    string cchid = 3;
    string account = 4;
    string passwd = 5;
}
```

### 协议生成

运行协议生成脚本：

```bash
bash shell/gen_proto.sh
```

生成的文件：
- `proto/pb/*.pb` - Protobuf 二进制文件
- `logic/base/netPb.lua` - Lua 协议映射表

### 协议使用

**服务端编码：**
```lua
local protobuf = require "protobuf"
local data = {
    accountType = "1",
    account = "test",
    passwd = "123456"
}
local msg = protobuf.encode("Login.c2splaylogin", data)
```

**服务端解码：**
```lua
local loginInfo = protobuf.decode("Login.c2splaylogin", packet)
```

## 💾 数据库

### MongoDB 操作

框架封装了 MongoDB 操作接口：

**插入数据：**
```lua
skynet.call(".mongodb", "lua", "insert", {
    database = "game",
    collection = "users",
    doc = {_id = "user123", name = "test"}
})
```

**查询数据：**
```lua
local result = skynet.call(".mongodb", "lua", "findOne", {
    database = "game",
    collection = "login",
    query = {_id = account}
})
```

**更新数据：**
```lua
skynet.call(".mongodb", "lua", "update", {
    database = "game",
    collection = "login",
    selector = {_id = account},
    update = {
        ["$setOnInsert"] = {_id = account, userTbl = {}},
        ["$set"] = {["userTbl." .. userId] = true}
    },
    upsert = true,
    multi = false
})
```

## 📖 开发指南

### 添加新协议

1. 在 `tools/ptotools/proto/proto_desc/` 创建 `.proto` 文件
2. 运行 `bash shell/gen_proto.sh` 生成协议
3. 在服务中注册协议处理函数

### 添加新服务

1. 在 `logic/service/` 创建服务目录
2. 实现服务主文件（如 `service.lua`）
3. 在 `start_up/main_start.lua` 中启动服务

### 添加新模块

1. 在 `logic/module/` 创建模块目录
2. 实现模块逻辑
3. 在需要的地方 `Import` 模块

### Socket 操作注意事项

⚠️ **重要**: Skynet 的 `socket.read` 返回的是内部 buffer，必须立即使用 `skynet.tostring` 复制：

```lua
-- ✅ 正确
local block = socket.read(fd, 2)
local data = skynet.tostring(block, 2)

-- ❌ 错误 - 会导致段错误
local block = socket.read(fd, 2)
-- ... 其他操作 ...
local data = skynet.tostring(block, 2)  -- block 可能已被复用
```

### 服务间通信

**同步调用 (skynet.call):**
```lua
local result = skynet.call(service, "lua", "command", arg1, arg2)
```

**异步调用 (skynet.send):**
```lua
skynet.send(service, "lua", "command", arg1, arg2)
```

**处理请求：**
```lua
skynet.dispatch("lua", function(session, source, cmd, ...)
    local f = CMD[cmd]
    if session ~= 0 then
        skynet.ret(skynet.pack(f(...)))  -- 需要回复
    else
        f(...)  -- 不需要回复
    end
end)
```

## 📊 运行与监控

- **日志**：所有服务默认写入 `log/`，关键错误使用 `skynet.error` 输出；`gamelog` 服务会记录业务行为。
- **共享数据守卫**：`logic/define/data.lua` 会在 `skynet.init` 后加载 `sharedata`，业务请通过封装接口访问，避免在 preload 阶段直接 `sharedata.query`。
- **性能观察**：推荐在压力测试时打开 `skynet.profile` 或在服务里打印协程队列长度，以便发现 Gate、Agent 或 Mongo 的瓶颈。
- **健康检查**：若要扩展多 Gate，可参考 `docs/GATE_SCALING.md` 的注册/发现流程，并在 HTTP 服务（`mcs`）暴露运维接口。

## 📚 更多文档

- [FRAMEWORK_REVIEW.md](FRAMEWORK_REVIEW.md)：框架综合评估与规划
- [PERFORMANCE_ANALYSIS.md](PERFORMANCE_ANALYSIS.md)：压测与性能分析记录
- [docs/GATE_SCALING.md](docs/GATE_SCALING.md)：多 Gate 扩展方案

## ❓ 常见问题

### 1. 段错误 (Segmentation Fault)

**原因**: 直接使用 `socket.read` 返回的 buffer，没有立即复制。

**解决**: 使用 `skynet.tostring(block, size)` 立即复制数据。

### 2. 协议解析失败

**原因**: 
- 协议未注册
- 协议名称不匹配（注意 package 前缀）

**解决**: 
- 检查 `protobufinit.lua` 是否注册了协议文件
- 确认使用完整的协议名称（如 `Login.c2splaylogin`）

### 3. MongoDB 连接失败

**原因**: 配置错误或 MongoDB 未启动。

**解决**: 
- 检查 `config/main_node` 中的 MongoDB 配置
- 确认 MongoDB 服务已启动
- 检查网络连接和防火墙设置

### 4. 服务启动失败

**原因**: 
- 配置文件路径错误
- 端口被占用
- 依赖服务未启动

**解决**: 
- 检查配置文件路径
- 使用 `netstat` 检查端口占用
- 查看日志文件定位问题

## 📝 开发规范

1. **命名规范**
   - 服务文件使用小写+下划线：`agent.lua`
   - 模块使用小写+下划线：`user_manager.lua`
   - 常量使用大写+下划线：`MAX_USER_COUNT`

2. **代码组织**
   - 每个服务独立目录
   - 公共功能放在 `common/` 或 `logic/base/`
   - 业务逻辑放在 `logic/module/`

3. **错误处理**
   - 使用 `pcall` 包装可能出错的操作
   - 记录详细的错误日志
   - 优雅处理异常情况

## 📄 许可证

本项目基于 Skynet 框架开发，遵循 Skynet 的 MIT 许可证。

## 👥 贡献

欢迎提交 Issue 和 Pull Request！

## 📧 联系方式

如有问题，请提交 Issue 或联系项目维护者。

---

**Happy Coding! 🎮**
