# Game Demo

一个基于 [Skynet](https://github.com/cloudwu/skynet) 的 Lua 游戏服务端示例项目，聚焦于**可快速运行**和**可持续扩展**。

适合：

- 学习 Skynet 服务化架构
- 快速验证玩法原型
- 搭建中小型游戏后端基础骨架

---

## Highlights

- **服务解耦**：登录、网关、业务、存储分层清晰
- **扩展友好**：模块化玩法目录，便于迭代功能
- **工程可用**：提供主节点与测试节点配置
- **存储支持**：内置 MongoDB、Redis 接入能力

---

## Architecture

核心服务由 `start_up/main_start.lua` 启动：

- `logind`：登录服务
- `gated`：网关服务
- `gameserver`：业务聚合服务
- `main_mongodb`：数据库封装服务（`.mongodb`）
- `game_sid` / `load_xls` / `gamelog` / `mcs` / `mail`

简化链路：

`Client -> Gate -> Login/Agent Logic -> MongoDB/Redis`

---

## Quick Start

### 1. Build Skynet

```bash
cd skynet
make linux
# macOS: make macosx
```

### 2. Configure

编辑 `config/main_node`，确认：

- `host_id`
- `mongodb_*`
- `redis_*`
- `gate_port` / `login_port` / `http_port`

### 3. Start Services

```bash
bash shell/start.sh
```

可选：启动测试节点

```bash
bash shell/runtest.sh
```

---

## Project Layout

```text
game_demo/
|-- config/          # 运行配置（main_node / test_node）
|-- start_up/        # 启动入口
|-- logic/           # 核心业务与服务代码
|-- common/          # 公共逻辑
|-- shell/           # 启停脚本
|-- proto/           # 协议文件
|-- skynet/          # Skynet 引擎
`-- docs/            # 扩展文档
```

---

## Script Reference

- `shell/start.sh`：启动主节点
- `shell/runtest.sh`：启动测试节点
- `shell/start_db.sh`：启动 MongoDB + Redis（默认路径需按本机调整）
- `shell/stop_db.sh`：停止 MongoDB + Redis
- `shell/drop_db.sh`：清空业务数据

---

## Notes

- 推荐在 Linux/macOS 或 WSL 环境运行
- `start_db.sh` 里数据库安装路径是示例值，使用前请先改为本机路径
- 此项目定位为示例/原型骨架，不是完整商业服方案

---

## More Docs

- [FRAMEWORK_REVIEW.md](FRAMEWORK_REVIEW.md)
- [PERFORMANCE_ANALYSIS.md](PERFORMANCE_ANALYSIS.md)
- [docs/GATE_SCALING.md](docs/GATE_SCALING.md)

## License

遵循 Skynet 相关开源许可证（MIT）。
