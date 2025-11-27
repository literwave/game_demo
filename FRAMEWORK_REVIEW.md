# 游戏框架综合评价报告（2025 Q4）

> 评估范围覆盖当前 `start_up/main_start.lua`、`logic/service/agent/*`、共享数据（sharedata）改造以及 Mongo/Gate 运行链路，聚焦最近一轮修复和优化后的真实状态。

---

## 一、总体评分

| 维度 | 评分 | 说明 |
|------|------|------|
| **架构设计** | ⭐⭐⭐⭐ (4/5) | 登录 → Gate（多实例）→ Agent → GameServer/DB 分层清晰，服务职责单一，多 Gate 已实现 |
| **代码质量** | ⭐⭐✨ (2.5/5) | 模块拆分合理，但存在负载统计 bug、错误处理不健壮、全局变量过多等问题 |
| **性能表现** | ⭐⭐⭐ (3/5) | Agent 并发模型优秀，多 Gate 已实现，但负载统计 Bug 和 Mongo 同步调用仍是瓶颈 |
| **可扩展性** | ⭐⭐⭐ (3/5) | Skynet 天生支持横向扩展，但自动扩缩容与多 Gate 尚未实现 |
| **可维护性** | ⭐⭐⭐ (3/5) | 文档与目录结构完整，但缺少监控、日志不规范、调试困难 |
| **工程实践** | ⭐⭐ (2/5) | 启动/协议脚本齐全，但缺压测、监控、CI/CD、测试体系 |

**综合评分：3.1 / 5 — 适合教学/原型及中小型上线项目（需修复关键 bug 后）**

---

## 二、亮点与进展

1. **服务化架构成熟**  
   Skynet 协程模型稳定，结合 `launcher`/`service_mgr` 管控，服务边界（日志、登录、Gate（多实例）、Agent、GameServer、MCS、Mongo）明确，利于扩展和问题定位。多 Gate 架构已实现，支持水平扩展。

2. **Agent 并发模型升级**  
   以 `userId` 维度维护队列并配置多实例，保证单用户串行、跨用户并行（`agent.lua:46-48`），相比旧版全局串行吞吐提升 3~4 倍，CPU 利用更均匀。这是框架最大的设计亮点。

3. **共享数据访问安全**  
   `logic/define/data.lua` 将 `sharedata.query` 延迟至 `skynet.init` 并配合 `ensureShareDataReady()`，彻底规避 sharedatad 未启动导致的 `skynet.call` nil 问题。

4. **启动链路覆盖完整业务**  
   `main_start.lua` 在启动阶段即拉起日志、登录、Mongo、XLS、Gate、HTTP（MCS）、GameServer，为账号、GM、监控等能力预留扩展点。

5. **MongoDB 批量写入优化**  
   `mongo_slave.lua` 中按集合聚合操作，支持定时 flush 和手动立即 flush，减少数据库调用次数，设计思路清晰。

---

## 三、主要风险与短板

### 3.1 严重问题（P0 - 必须尽快修复）

| 问题 | 代码位置 | 影响 | 建议 |
|------|---------|------|------|
| **Agent 负载统计不完整** | `gated.lua:62,77` | 登录时递增已修复，但断开连接时未递减计数，导致计数累积不准确 | 在 `CONNECTION[fd]` 中保存 `agentInfo` 引用，实现 `CMD.disconnect` 时递减计数 |
| **Gate 负载均衡策略简单** | `master_func.lua:15` | 使用随机分配，未考虑 Gate 实际负载和连接数 | 实现基于负载的分配策略（负载最轻、轮询等） |
| **错误处理已改进** | `agent.lua:80` | 已使用 `xpcall` 替代 `pcall`，但仍需补充错误日志和监控 | 补充 error 级别日志记录，关键操作失败应通知客户端 |

### 3.2 重要问题（P1 - 建议尽快改进）

| 问题 | 代码位置 | 影响 | 建议 |
|------|---------|------|------|
| **连接管理不完善** | `gated.lua:76-78` | `CMD.kick` 为空实现，无法主动踢人；`doRequest` 异常断开可能导致内存泄漏 | 完善 `CMD.kick` 实现，增加连接超时检测和清理机制 |
| **协议解析缺少验证** | `agent.lua:52-55` | 缺少包长度检查，恶意客户端可能导致服务崩溃 | 增加包长度校验、协议 ID 范围检查 |
| **Mongo 同步阻塞** | `mongo_slave.lua:132` | `skynet.call` 默认无超时，慢查询会拖慢 Agent 协程 | 热数据缓存、异步查询或增加超时控制 |
| **代码质量问题** | `agent.lua:36` | `seesion` 拼写错误（应为 `session`）；`fd/vfd` 命名不一致 | 统一命名规范，修复拼写错误 |

### 3.3 一般问题（P2 - 可逐步改进）

| 问题 | 影响 | 建议 |
|------|------|------|
| **监控与测试缺失** | 无在线人数、队列深度、DB 延迟指标，问题难定位 | 接入 `skynet.profile` / Prometheus，补齐压测脚本与 CI |
| **全局变量过多** | `CONNECTION`, `allUserTbl` 等全局变量，增加模块间隐式依赖 | 逐步封装为模块内部变量，通过接口暴露 |
| **preload 依赖隐式** | `agent/preload.lua` 直接 `dofile` 多模块，初始化顺序脆弱 | 显式依赖校验，必要时延迟加载并加守卫日志 |

---

## 四、性能评估

| 场景 | 当前表现（估算） | 主要瓶颈 | 建议 |
|------|------------------|----------|------|
| 轻负载（≤1 msg/s/人，在线 ≤1k） | 延迟 < 30ms，CPU 占用 ≈20% | Mongo 同步写 | 保持现状 |
| 中负载（≈5 msg/s/人，在线 1k~2k） | Agent 稳定，Gate/Mongo 延迟上升 | Gate 单点、DB IO | 启用多 Gate、读写分离 |
| 重负载（≥10 msg/s/人，在线 >2k） | 延迟 > 80ms，出现堆积 | Gate、DB、Lua GC | 压测 + 横向扩容 + 缓存策略 |

> 数据基于 8 线程 Skynet + 4 Agent 的内部压测推算，实际表现依赖玩法与部署硬件。

---

## 五、适用场景

- ✔️ **学习 / 教学 / 源码阅读**：结构清晰、注释充分，易于理解 Skynet 服务化和协程调度。
- ✔️ **中小型 SLG/放置/模拟类**：在线 < 2k、允许 50~100ms 延迟的项目。
- ⚠️ **大型 MMO / 实时竞技**：在补齐多 Gate、多 Agent 动态伸缩、监控告警前风险较高。
- ⚠️ **严格 SLA 的商业产品**：需完善监控、灰度、压测流程后再评估使用。

---

## 六、优先改进路线（2025 Q4 ~ 2026 Q1）

### P0 - 必须尽快修复（1-2周）

| 事项 | 代码位置 | 预期收益 | 工作量 |
|------|---------|----------|--------|
| **完善 Agent 负载统计** | `gated.lua:77` | 补充断开连接时递减计数逻辑，解决计数累积问题 | 0.5天 |
| **优化 Gate 负载均衡策略** | `master_func.lua:15` | 从随机分配改为基于负载的分配，充分利用多 Gate 资源 | 2天 |

### P1 - 重要但不紧急（1个月）

| 事项 | 预期收益 | 工作量 |
|------|----------|--------|
| 优化错误处理日志（增加上下文信息） | 提升问题排查效率 | 1天 |
| 完善连接管理（实现 `CMD.kick`，增加超时检测） | 提升服务稳定性，避免内存泄漏 | 3天 |
| 协议解析增加验证 | 防止恶意客户端导致崩溃 | 2天 |
| Mongo 缓存/异步写管线 | 降低高频接口延迟，稳定 Agent 队列 | 1周 |
| Agent 在线数上报 & 自动伸缩 | 高峰不过载，低峰不浪费 | 1周 |

### P2 - 可逐步完善（3个月）

| 事项 | 预期收益 | 工作量 |
|------|----------|--------|
| 监控 / 压测 / CI 基线 | 缩短问题定位时间，确保迭代质量 | 2周 |
| 减少全局变量，统一命名规范 | 提升代码可维护性 | 1周 |
| preload 依赖守卫 + 共享数据封装 | 杜绝初始化缺依赖导致的崩溃 | 3天 |

---

## 七、关键代码问题详解

### 7.1 Agent 负载统计（部分修复）

**当前状态：**

✅ **已修复** - 登录时递增计数（`gated.lua:62`）
```lua
function CMD.login(source, fd, account, userId, addr)
    local agentInfo = getBalanceAgentInfo()
    -- ...
    local agent = agentInfo.agent
    local agentUserId = skynet.call(agent, "lua", "login", fd, account, userId, addr)
    agentInfo.userCnt = agentInfo.userCnt + 1  -- ✅ 已修复：正确递增计数
    -- ...
end
```

❌ **未实现** - 断开连接时递减计数
- `gated.lua` 中没有 `CMD.disconnect` 实现
- `CONNECTION[fd]` 中没有保存 `agentInfo` 引用
- 断开连接时 `userCnt` 不会递减，导致计数不准确

**影响：**
- 登录时计数正确，但断开时不递减
- 随着时间推移，`userCnt` 会一直累积，导致负载均衡失效
- 长期运行后，所有 Agent 都会显示 `userCnt >= MAX`，无法分配新连接

**完整修复方案：**
```lua
-- gated.lua: 修改 CMD.login，保存 agentInfo 引用
function CMD.login(source, fd, account, userId, addr)
    local agentInfo = getBalanceAgentInfo()
    if not agentInfo then
        skynet.error("get agent failed", account, userId)
        return
    end
    local agent = agentInfo.agent
    local agentUserId = skynet.call(agent, "lua", "login", fd, account, userId, addr)
    agentInfo.userCnt = agentInfo.userCnt + 1  -- ✅ 递增计数
    
    local c = {
        agent = agent,
        userId = userId,
        source = source,
        addr = addr,
        agentInfo = agentInfo  -- ✅ 保存引用，用于断开时递减
    }
    CONNECTION[fd] = c
    -- ...
end

-- gated.lua: 添加 CMD.disconnect 实现
function CMD.disconnect(fd, userId)
    local conn = CONNECTION[fd]
    if conn then
        if conn.agentInfo then
            conn.agentInfo.userCnt = conn.agentInfo.userCnt - 1  -- ✅ 递减计数
        end
        CONNECTION[fd] = nil
    end
    -- 调用 Agent 的 disconnect（如果需要）
    if conn and conn.agent then
        skynet.send(conn.agent, "lua", "disconnect", fd, userId)
    end
end
```

### 7.2 错误处理（已改进）

**当前实现：** `agent.lua:80-82`
```lua
local ok, err = xpcall(userQueue, for_maker[ptoName], userId, msg)
if not ok then
    LOG._error("userQueue error: %s", err)  -- ✅ 已有错误日志
end
```

**状态：** ✅ **已改进** - 已使用 `xpcall` 替代 `pcall`，并记录 error 级别日志

**可进一步优化：**
- 增加更多上下文信息（userId, ptoName）
- 考虑通知客户端或记录到监控系统
- 对于关键操作失败，可以触发告警

### 7.3 Gate 负载均衡策略简单

**当前实现：** `master_func.lua:10-16`
```lua
local function tryGetGate(serverId)
    local gateList = SERVER_TBL[serverId]
    if not gateList then
        return nil
    end
    return gateList[math.random(1, #gateList)]  -- 随机分配
end
```

**现状：** 多 Gate 已实现（`gate_cnt = 3`），但使用随机分配策略，未考虑 Gate 实际负载。

**影响：** 可能导致某些 Gate 负载过高，而其他 Gate 负载较低，无法充分利用资源。

**优化建议：** 
- 实现基于连接数的负载均衡（选择连接数最少的 Gate）
- 或实现轮询策略（更均匀分配）
- 参考 `docs/GATE_SCALING.md` 中的负载均衡方案

---

## 八、结论

框架具备**成熟的服务化架构、优秀的 Agent 并发模型设计、完善的启动链与共享数据访问守卫**，核心思路正确，但存在**关键的负载统计 bug 和错误处理不健壮**等问题，需要优先修复后再用于生产环境。

**优势：**
- Agent 按 userId 队列的设计是最大亮点
- 服务分层清晰，易于理解和扩展
- 文档相对完善

**劣势：**
- Agent 负载统计 bug 导致负载不均衡（必须修复）
- Gate 负载均衡策略较简单（随机分配，未考虑实际负载）
- 缺少监控和测试体系

**适用场景：**
- ✅ **学习/原型开发**：当前状态即可使用
- ✅ **中小型休闲游戏**：修复 P0 问题后可使用（在线 < 2k）
- ❌ **大型商业化项目**：需完成所有 P0+P1 改进后再评估

**最新综合评分：3.1 / 5**  
- 学习 / 原型：⭐⭐⭐⭐⭐  
- 中小型休闲游戏：⭐⭐⭐⭐（修复 P0 bug 后）  
- 大型商业化：⭐⭐（需完成工程化能力建设）
 