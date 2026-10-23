# 网关扩展

## 已实现：进程内多个 worker

`.gated` 监听 `gate_port`，只做 `accept`。连接轮流交给 `gate_cnt` 个 `gate_worker`，每个 worker 是独立的 skynet 服务，各自做 WebSocket 读写、token 校验和转发。客户端仍连接同一个地址，登录服不感知 worker。

agent 池由 `.gated` 统一创建，所有 worker 共用。玩家按 `userId % agent 数` 固定分配，所以同一次在线期间换 worker（重连被分到另一个 worker）仍然进同一个 agent，不会两份数据同时在内存里。

同一玩家再登录时，agent 踢掉旧连接再接受新的。旧连接可能在另一个 worker 上，踢人和随后到达的断线通知都按 fd 区分，不会把新会话登出。

配置在 `config/main_node`：

| 项 | 作用 |
|----|------|
| `gate_cnt` | worker 数量，默认 3 |
| `agent_init_cnt` | agent 数量，默认 4。改它会改变玩家落点，必须重启，不能在运行中改 |

关服顺序：停掉监听，worker 停止转发，agent 逐个下线落盘，worker 再断开客户端连接。

验证过的范围：单独起网关，3 个 worker、2 个 agent、两个 WebSocket 客户端。两条连接分到不同 worker，两个玩家落到各自固定的 agent，登录过程中 agent 推的包能到达客户端，关服按上面的顺序执行。顶号和完整登录流程还没在这个测试里覆盖。

## 还没做：跨进程、跨机器

登录服从已注册的网关列表里随机挑一个（`common/slave_func.lua` 的 `try_get_gate_info`），但 `start_up/main_start.lua` 只启动一个 `.gated`，所以现在永远挑到它。

跨进程时每个进程一个 `.gated`、各自注册即可让登录服挑不同的地址，但 agent 池就不再共享：同一个玩家两次登录可能进不同进程的 agent，两份数据一起写。所以扩之前要先保证玩家固定落到同一个进程，例如按 `userId` 选进程，或者把 agent 单独部署、用 cluster 调用。

用多端口加外部负载均衡（HAProxy 等）也是同样的前提：先固定玩家落点，再谈流量怎么分。
