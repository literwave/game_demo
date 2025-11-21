# Gate 水平扩展方案

## 📋 目录

- [当前架构](#当前架构)
- [方案概述](#方案概述)
- [方案一：登录服负载均衡（推荐）](#方案一登录服负载均衡推荐)
- [方案二：Gate 管理器服务](#方案二gate-管理器服务)
- [方案三：外部负载均衡器](#方案三外部负载均衡器)
- [方案对比](#方案对比)
- [推荐实现](#推荐实现)

## 🏗️ 当前架构

```
Client → Logind (Master) → Slave → 验证登录 → 转发到 Gate → Agent
```

**关键流程**:
1. 客户端连接登录服（`login_port: 33021`）
2. Master 分配连接给 Slave
3. Slave 验证登录，调用 `socket.abandon(fd)` 放弃连接
4. Master 通过 `serverInfo.gate` 找到 Gate，调用 `gate:login(fd, ...)`
5. Gate 接管连接，转发给 Agent

**问题**: 当前 `SERVER_TBL[serverId].gate` 只存储单个 Gate，无法负载均衡

## 🎯 方案概述

水平扩展 Gate 的核心目标：
- **分散连接压力**：多个 Gate 实例分担客户端连接
- **提高可用性**：单个 Gate 故障不影响整体服务
- **动态扩容**：根据负载动态增加/减少 Gate 实例
- **适配现有架构**：在登录服转发时选择 Gate

## 方案一：登录服负载均衡（推荐）⭐

### 架构图

```
Client → Logind Master → Slave (验证) → 选择 Gate → Gate1/Gate2/Gate3 → Agent
```

### 实现原理

在登录服的 `master_func.lua` 中，维护多个 Gate 的列表，根据负载均衡策略选择一个 Gate 转发连接。

### 实现代码

#### 1. 修改 Gate 注册逻辑

修改 `common/master_func.lua`:

```lua
local skynet = require "skynet"
local socket = require "skynet.socket"
CMD = MASTER_HANDLE.CMD

SERVER_TBL = {
    -- [serverId] = {
    --     gates = {gate1, gate2, gate3},  -- Gate 列表
    --     gateIndex = 1,  -- 轮询索引
    -- }
}

local function getServerInfo(serverId)
    return SERVER_TBL[serverId]
end

-- 注册 Gate（支持多个 Gate）
function CMD.registerGate(gate, serverId)
    local serverInfo = SERVER_TBL[serverId]
    if not serverInfo then
        serverInfo = {
            gates = {},
            gateIndex = 1,
            gateStats = {}  -- {gate_address = {connectionCount, maxConnections}}
        }
        SERVER_TBL[serverId] = serverInfo
    end
    
    -- 添加到 Gate 列表
    table.insert(serverInfo.gates, gate)
    serverInfo.gateStats[gate] = {
        connectionCount = 0,
        maxConnections = tonumber(skynet.getenv("maxonline") or 2000)
    }
    skynet.error(string.format("Gate registered for serverId %s, total gates: %d", 
        serverId, #serverInfo.gates))
end

-- 获取负载最轻的 Gate
local function getBestGate(serverInfo)
    local bestGate = nil
    local minLoad = math.huge
    
    for _, gate in ipairs(serverInfo.gates) do
        local stats = serverInfo.gateStats[gate]
        if stats then
            local load = stats.connectionCount / stats.maxConnections
            if load < minLoad and stats.connectionCount < stats.maxConnections then
                minLoad = load
                bestGate = gate
            end
        end
    end
    
    return bestGate
end

-- 轮询选择 Gate
local function getRoundRobinGate(serverInfo)
    if #serverInfo.gates == 0 then
        return nil
    end
    local gate = serverInfo.gates[serverInfo.gateIndex]
    serverInfo.gateIndex = (serverInfo.gateIndex % #serverInfo.gates) + 1
    return gate
end

-- 根据用户 ID 哈希选择 Gate（会话保持）
local function getGateByUserId(serverInfo, userId)
    if #serverInfo.gates == 0 then
        return nil
    end
    local hash = tonumber(userId) or 0
    local idx = (hash % #serverInfo.gates) + 1
    return serverInfo.gates[idx]
end

function createUserOk(slaveService, account, userId)
    skynet.call(slaveService, "lua", "createUserOk", account, userId)
end

function accept(slaveService, fd, addr)
    local account, userId, serverId = skynet.call(slaveService, "lua", "auth", fd, addr)
    if not account then
        return
    end
    
    local serverInfo = getServerInfo(serverId)
    if not serverInfo or #serverInfo.gates == 0 then
        skynet.error("serverInfo error or no gate available", serverId)
        socket.close(fd)
        return
    end
    
    -- 选择 Gate（可以根据策略选择）
    local gate = getBestGate(serverInfo)  -- 负载均衡
    -- local gate = getRoundRobinGate(serverInfo)  -- 轮询
    -- local gate = getGateByUserId(serverInfo, userId)  -- 会话保持
    
    if not gate then
        skynet.error("No available gate, reject connection")
        socket.close(fd)
        return
    end
    
    -- 更新 Gate 统计
    local stats = serverInfo.gateStats[gate]
    if stats then
        stats.connectionCount = stats.connectionCount + 1
    end
    
    skynet.error(string.format("Forward to gate %s, account=%s, userId=%s", 
        tostring(gate), account, userId))
    
    -- 转发到选中的 Gate
    skynet.send(gate, "lua", "login", fd, account, userId, addr)
end

-- Gate 通知连接断开
function CMD.onGateConnectionClose(serverId, gate)
    local serverInfo = getServerInfo(serverId)
    if serverInfo and serverInfo.gateStats[gate] then
        local stats = serverInfo.gateStats[gate]
        stats.connectionCount = math.max(0, stats.connectionCount - 1)
    end
end

-- 获取 Gate 状态
function CMD.getGateStatus(serverId)
    local serverInfo = getServerInfo(serverId)
    if not serverInfo then
        return nil
    end
    
    local status = {}
    for i, gate in ipairs(serverInfo.gates) do
        local stats = serverInfo.gateStats[gate]
        table.insert(status, {
            index = i,
            address = gate,
            connections = stats.connectionCount,
            maxConnections = stats.maxConnections,
            load = string.format("%.2f%%", (stats.connectionCount / stats.maxConnections) * 100)
        })
    end
    return status
end
```

#### 2. 修改 Gate 服务，通知连接断开

修改 `logic/service/gated/gated.lua`:

```lua
local skynet = require "skynet"
local socket = require "skynet.socket"

local CMD = {}
local SERVER_ID = nil  -- 从配置中获取
local GATE_ID = nil

CONNECTION = {
    -- [vfd] = {agent, userId, source, addr}
}

local AGENT_INIT_CNT = skynet.getenv("agent_init_cnt")
local AGENT_MAX_USER_CNT = tonumber(skynet.getenv("agent_max_user_cnt"))
local AGENT_POOLS = {}

local function getBalanceAgentInfo()
    for _, agentInfo in ipairs(AGENT_POOLS) do
        if agentInfo.userCnt < AGENT_MAX_USER_CNT then
            return agentInfo
        end
    end
end

function CMD.open(source, conf)
    SERVER_ID = conf.serverId
    GATE_ID = conf.gateId or 1
    
    for _ = 1, AGENT_INIT_CNT do
        local agent = {
            userCnt = 0,
            agent = skynet.newservice("agent")
        }
        table.insert(AGENT_POOLS, agent)
    end
    
    -- 注册到登录服（支持多个 Gate）
    skynet.send(".logind", "lua", "registerGate", skynet.self(), SERVER_ID)
    skynet.error(string.format("Gate %d registered for serverId %s", GATE_ID, SERVER_ID))
end

function CMD.login(source, fd, account, userId, addr)
    assert(not CONNECTION[fd])
    local agentInfo = getBalanceAgentInfo()
    skynet.error(string.format("Gate %d: login fd=%d, account=%s", GATE_ID, fd, account))
    
    if not agentInfo then
        skynet.error("get agent failed", account, userId)
        socket.close(fd)
        return
    end
    
    local agent = agentInfo.agent
    local agentUserId = skynet.call(agent, "lua", "login", fd, account, userId, addr)
    
    local c = {
        agent = agent,
        userId = userId,
        source = source,
        addr = addr,
    }
    CONNECTION[fd] = c
    
    if agentUserId ~= userId then
        skynet.send(source, "lua", "createUserOk", account, agentUserId)
    end
    
    socket.start(fd)
end

function CMD.disconnect(fd)
    local c = CONNECTION[fd]
    if c then
        CONNECTION[fd] = nil
        -- 通知登录服连接断开
        if SERVER_ID then
            skynet.send(".logind", "lua", "onGateConnectionClose", SERVER_ID, skynet.self())
        end
    end
end

function CMD.kick(source, fd)
    socket.close(fd)
    CMD.disconnect(fd)
end

skynet.start(function()
    skynet.dispatch("lua", function (session, address, cmd, ...)
        local f = CMD[cmd]
        if f then
            if session ~= 0 then
                skynet.ret(skynet.pack(f(address, ...)))
            else
                f(address, ...)
            end
        end
    end)
end)
```

#### 3. 修改启动脚本，启动多个 Gate

修改 `start_up/main_start.lua`:

```lua
local skynet = require "skynet"

skynet.start(function()
    skynet.error("Server start")
    skynet.newservice("gamelog")
    skynet.newservice("logind")
    skynet.newservice("main_mongodb")
    skynet.call(".mongodb", "lua", "start")
    skynet.newservice("game_sid")
    
    -- 启动多个 Gate 实例
    local gateCount = 3  -- 可以根据配置读取
    local serverId = skynet.getenv("host_id")
    local basePort = skynet.getenv("gate_port") or 8888
    
    for i = 1, gateCount do
        local gate = skynet.newservice("gated")
        local port = basePort + i - 1
        skynet.call(gate, "lua", "open", {
            port = port,
            maxclient = tonumber(skynet.getenv("maxonline") or 2000),
            nodelay = true,
            serverId = serverId,
            gateId = i
        })
        skynet.error(string.format("Gate %d started on port %d", i, port))
    end
    
    -- ... 其他代码
end)
```

#### 4. 添加配置项

修改 `config/main_node`:

```lua
-- Gate 相关配置
gate_port = 8888
gate_count = 3  -- Gate 实例数量
```

### 优点
- ✅ **适配现有架构**，无需大幅改动
- ✅ 登录服统一管理 Gate 列表
- ✅ 支持多种负载均衡策略
- ✅ 可以监控每个 Gate 的状态
- ✅ 实现简单，易于维护

### 缺点
- ⚠️ 登录服需要维护 Gate 状态（轻微开销）
- ⚠️ 需要 Gate 主动通知连接断开

---

## 方案二：Gate 管理器服务

### 架构图

```
Client1 ──┐
Client2 ──┤
Client3 ──┼──> Nginx/HAProxy ──> Gate1 (8888)
Client4 ──┤                      Gate2 (8889)
Client5 ──┘                      Gate3 (8890)
```

### 实现步骤

#### 1. 修改启动脚本，支持多 Gate

创建 `logic/service/gate_mgr/gate_mgr.lua`:

```lua
local skynet = require "skynet"

local CMD = {}
local GATE_POOLS = {}  -- {gate_id = gate_address}
local GATE_COUNT = 3   -- Gate 实例数量
local BASE_PORT = 8888

function CMD.start()
    -- 启动多个 Gate 实例
    for i = 1, GATE_COUNT do
        local gate = skynet.newservice("gated")
        local port = BASE_PORT + i - 1
        skynet.call(gate, "lua", "open", {
            port = port,
            maxclient = tonumber(skynet.getenv("maxonline") or 2000),
            nodelay = true,
            serverId = skynet.getenv("host_id"),
            gateId = i
        })
        GATE_POOLS[i] = {
            id = i,
            address = gate,
            port = port,
            connectionCount = 0
        }
        skynet.error(string.format("Gate %d started on port %d", i, port))
    end
end

function CMD.getGateList()
    return GATE_POOLS
end

function CMD.getGateByHash(hash)
    -- 根据 hash 值选择 Gate（用于会话保持）
    local idx = (hash % GATE_COUNT) + 1
    return GATE_POOLS[idx]
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            if session ~= 0 then
                skynet.ret(skynet.pack(f(...)))
            else
                f(...)
            end
        end
    end)
    skynet.register ".gate_mgr"
end)
```

#### 2. 配置 Nginx 负载均衡

创建 `nginx_gate.conf`:

```nginx
upstream gate_backend {
    # 使用 IP Hash 保持会话（可选）
    ip_hash;
    
    server 127.0.0.1:8888 weight=1;
    server 127.0.0.1:8889 weight=1;
    server 127.0.0.1:8890 weight=1;
    
    # 健康检查
    # keepalive 32;
}

server {
    listen 8888;
    
    location / {
        proxy_pass http://gate_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        
        # TCP 代理配置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

**注意**: Nginx 主要用于 HTTP，TCP 负载均衡需要使用 `stream` 模块：

```nginx
stream {
    upstream gate_backend {
        hash $remote_addr consistent;  # 会话保持
        server 127.0.0.1:8888;
        server 127.0.0.1:8889;
        server 127.0.0.1:8890;
    }
    
    server {
        listen 8888;
        proxy_pass gate_backend;
        proxy_timeout 1s;
        proxy_responses 1;
    }
}
```

#### 3. 使用 HAProxy (更适合 TCP)

创建 `haproxy_gate.cfg`:

```haproxy
global
    daemon
    maxconn 10000

defaults
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend gate_frontend
    bind *:8888
    default_backend gate_backend

backend gate_backend
    balance roundrobin  # 或 source（会话保持）
    server gate1 127.0.0.1:8888 check
    server gate2 127.0.0.1:8889 check
    server gate3 127.0.0.1:8890 check
```

### 优点
- ✅ 成熟稳定，生产环境广泛使用
- ✅ 支持健康检查和自动故障转移
- ✅ 配置简单，易于管理
- ✅ 支持多种负载均衡算法

### 缺点
- ❌ 需要额外的中间件
- ❌ 增加一层网络跳转（轻微延迟）
- ❌ TCP 负载均衡配置相对复杂

---

## 方案二：Gate 管理器服务（推荐）

### 架构图

```
Client ──> Gate Mgr (监听 8888) ──> 选择 Gate ──> Gate1/Gate2/Gate3
                                              └──> Agent Pool
```

### 实现代码

#### 1. Gate 管理器服务

创建 `logic/service/gate_mgr/gate_mgr.lua`:

```lua
local skynet = require "skynet"
local socket = require "skynet.socket"

local CMD = {}
local GATE_POOLS = {}  -- {gate_id = {address, port, connectionCount}}
local GATE_COUNT = 3
local BASE_PORT = 8888
local currentGateId = 1  -- 轮询计数器

-- 启动所有 Gate 实例
function CMD.start()
    for i = 1, GATE_COUNT do
        local gate = skynet.newservice("gated")
        local port = BASE_PORT + i - 1
        skynet.call(gate, "lua", "open", {
            port = port,
            maxclient = tonumber(skynet.getenv("maxonline") or 2000),
            nodelay = true,
            serverId = skynet.getenv("host_id"),
            gateId = i
        })
        GATE_POOLS[i] = {
            id = i,
            address = gate,
            port = port,
            connectionCount = 0,
            maxConnections = tonumber(skynet.getenv("maxonline") or 2000)
        }
        skynet.error(string.format("Gate %d started on port %d", i, port))
    end
end

-- 获取负载最轻的 Gate
local function getBestGate()
    local bestGate = nil
    local minLoad = math.huge
    
    for _, gate in ipairs(GATE_POOLS) do
        local load = gate.connectionCount / gate.maxConnections
        if load < minLoad and gate.connectionCount < gate.maxConnections then
            minLoad = load
            bestGate = gate
        end
    end
    
    return bestGate
end

-- 轮询选择 Gate
local function getRoundRobinGate()
    local gate = GATE_POOLS[currentGateId]
    currentGateId = (currentGateId % GATE_COUNT) + 1
    return gate
end

-- 根据用户 ID 哈希选择 Gate（会话保持）
local function getGateByUserId(userId)
    local hash = tonumber(userId) or 0
    local idx = (hash % GATE_COUNT) + 1
    return GATE_POOLS[idx]
end

-- 处理新连接
function CMD.acceptConnection(fd, addr)
    -- 选择 Gate（可以根据策略选择：负载均衡/轮询/哈希）
    local gate = getBestGate()  -- 或 getRoundRobinGate()
    
    if not gate then
        skynet.error("No available gate, reject connection")
        socket.close(fd)
        return
    end
    
    -- 转发连接到选中的 Gate
    gate.connectionCount = gate.connectionCount + 1
    skynet.send(gate.address, "lua", "acceptConnection", fd, addr)
    
    return gate.id
end

-- Gate 通知连接断开
function CMD.onConnectionClose(gateId)
    local gate = GATE_POOLS[gateId]
    if gate then
        gate.connectionCount = math.max(0, gate.connectionCount - 1)
    end
end

-- 获取 Gate 状态
function CMD.getGateStatus()
    local status = {}
    for _, gate in ipairs(GATE_POOLS) do
        table.insert(status, {
            id = gate.id,
            port = gate.port,
            connections = gate.connectionCount,
            maxConnections = gate.maxConnections,
            load = string.format("%.2f%%", (gate.connectionCount / gate.maxConnections) * 100)
        })
    end
    return status
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            if session ~= 0 then
                skynet.ret(skynet.pack(f(...)))
            else
                f(...)
            end
        end
    end)
    
    -- 监听客户端连接
    local listenPort = skynet.getenv("gate_port") or 8888
    local fd = socket.listen("0.0.0.0", listenPort)
    skynet.error(string.format("Gate Manager listening on port %d", listenPort))
    
    socket.start(fd, function(clientFd, addr)
        skynet.error(string.format("New connection from %s, fd=%d", addr, clientFd))
        CMD.acceptConnection(clientFd, addr)
    end)
    
    skynet.register ".gate_mgr"
end)
```

#### 2. 修改 Gate 服务支持连接转发

修改 `logic/service/gated/gated.lua`:

```lua
-- 添加接受转发的连接
function CMD.acceptConnection(fd, addr)
    -- 直接接受连接，不需要重新 listen
    socket.start(fd)
    socket.limit(fd, 8192)
    
    -- 可以在这里做连接初始化
    skynet.error(string.format("Gate %d accepted connection fd=%d from %s", 
        GATE_ID or 0, fd, addr))
end

-- 连接断开时通知管理器
function CMD.disconnect(fd)
    local c = CONNECTION[fd]
    if c then
        CONNECTION[fd] = nil
        -- 通知管理器连接数减少
        if GATE_MGR then
            skynet.send(GATE_MGR, "lua", "onConnectionClose", GATE_ID)
        end
    end
end
```

#### 3. 修改启动脚本

修改 `start_up/main_start.lua`:

```lua
skynet.start(function()
    skynet.error("Server start")
    skynet.newservice("gamelog")
    skynet.newservice("logind")
    skynet.newservice("main_mongodb")
    skynet.call(".mongodb", "lua", "start")
    skynet.newservice("game_sid")
    
    -- 启动 Gate 管理器（替代直接启动 Gate）
    local gateMgr = skynet.newservice("gate_mgr")
    skynet.call(gateMgr, "lua", "start")
    
    -- ... 其他代码
end)
```

### 优点
- ✅ 纯 Skynet 实现，无需外部依赖
- ✅ 可以动态调整 Gate 数量
- ✅ 支持多种负载均衡策略
- ✅ 可以监控每个 Gate 的状态

### 缺点
- ❌ Gate 管理器成为单点（但可以优化）
- ❌ 需要自己实现负载均衡逻辑

---

## 方案三：Skynet Harbor 模式

### 架构图

```
Node1 (Harbor 1) ──> Gate1 (8888)
Node2 (Harbor 2) ──> Gate2 (8888)
Node3 (Harbor 3) ──> Gate3 (8888)
         │
    Master Node (协调)
```

### 实现步骤

#### 1. 配置 Harbor

修改 `config/main_node`:

```lua
harbor = 1  -- 启用 Harbor 模式
address = "127.0.0.1:2526"  -- 本节点地址
master = "127.0.0.1:2013"   -- Master 节点地址（如果存在）
```

#### 2. 多节点配置

创建多个节点配置文件：

`config/node1`:
```lua
harbor = 1
address = "127.0.0.1:2526"
-- ... 其他配置
gate_port = 8888
```

`config/node2`:
```lua
harbor = 2
address = "127.0.0.1:2527"
-- ... 其他配置
gate_port = 8888
```

#### 3. 服务发现

创建 `logic/service/gate_registry/gate_registry.lua`:

```lua
local skynet = require "skynet"

local CMD = {}
local GATE_LIST = {}  -- {gate_address}

function CMD.register(gateAddress, port)
    table.insert(GATE_LIST, {
        address = gateAddress,
        port = port
    })
    skynet.error(string.format("Gate registered: %s:%d", gateAddress, port))
end

function CMD.getGateList()
    return GATE_LIST
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            if session ~= 0 then
                skynet.ret(skynet.pack(f(...)))
            else
                f(...)
            end
        end
    end)
    skynet.register ".gate_registry"
end)
```

### 优点
- ✅ 真正的分布式架构
- ✅ 支持跨机器部署
- ✅ Skynet 原生支持

### 缺点
- ❌ 配置相对复杂
- ❌ 需要多台机器或配置多个端口
- ❌ 网络延迟可能增加

---

## 方案四：客户端随机选择

### 实现

客户端从服务器获取 Gate 列表，随机选择一个连接。

#### 1. Gate 列表服务

```lua
-- logic/service/gate_list/gate_list.lua
local skynet = require "skynet"

local CMD = {}
local GATE_LIST = {
    {host = "127.0.0.1", port = 8888},
    {host = "127.0.0.1", port = 8889},
    {host = "127.0.0.1", port = 8890},
}

function CMD.getGateList()
    return GATE_LIST
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = CMD[cmd]
        if f then
            skynet.ret(skynet.pack(f(...)))
        end
    end)
    skynet.register ".gate_list"
end)
```

#### 2. 客户端实现

```lua
-- 客户端先获取 Gate 列表
local gateList = httpGet("http://server/gate_list")
-- 随机选择一个
local gate = gateList[math.random(#gateList)]
-- 连接选中的 Gate
socket.connect(gate.host, gate.port)
```

### 优点
- ✅ 实现简单
- ✅ 无需负载均衡器

### 缺点
- ❌ 负载可能不均衡
- ❌ 客户端需要实现重连逻辑
- ❌ 无法动态调整

---

## 📊 方案对比

| 方案 | 复杂度 | 性能 | 可扩展性 | 适配现有架构 | 推荐度 |
|------|--------|------|----------|--------------|--------|
| **登录服负载均衡** | 低 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Gate 管理器 | 中 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| 外部负载均衡器 | 中 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| Harbor 模式 | 高 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| 客户端选择 | 低 | ⭐⭐⭐ | ⭐⭐ | ⭐ | ⭐⭐ |

## 🎯 推荐实现

**推荐使用方案一（登录服负载均衡）**，原因：

1. **完美适配现有架构**：客户端 → 登录服 → Gate 的流程无需改变
2. **实现简单**：只需修改 `master_func.lua` 和 `gated.lua`
3. **集中管理**：登录服统一管理所有 Gate，易于监控
4. **灵活策略**：支持负载均衡、轮询、哈希等多种策略
5. **无外部依赖**：纯 Skynet 实现

### 快速实现步骤

1. **修改 `common/master_func.lua`**
   - 将 `SERVER_TBL[serverId].gate` 改为 `gates` 列表
   - 实现 Gate 选择逻辑（负载均衡/轮询/哈希）
   - 添加 Gate 状态管理

2. **修改 `logic/service/gated/gated.lua`**
   - 添加 `GATE_ID` 标识
   - 连接断开时通知登录服

3. **修改 `start_up/main_start.lua`**
   - 启动多个 Gate 实例
   - 每个 Gate 注册到登录服

4. **测试验证**
   - 验证多个 Gate 都能正常注册
   - 验证负载均衡是否生效
   - 验证连接断开通知是否正常

### 配置示例

```lua
-- config/main_node
gate_port = 8888
gate_count = 3  -- Gate 实例数量
```

### 负载均衡策略选择

- **负载均衡** (`getBestGate`): 选择连接数最少的 Gate，适合大多数场景 ✅
- **轮询** (`getRoundRobinGate`): 简单均匀分配，适合 Gate 性能相近
- **哈希** (`getGateByUserId`): 根据用户 ID 固定分配到某个 Gate，适合需要会话保持的场景

---

**总结**: 水平扩展 Gate 的核心是**分散连接压力**，推荐使用 Gate 管理器服务实现，既简单又高效。

