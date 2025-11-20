#!/bin/bash

# Skynet 游戏服务器启动脚本

# 获取脚本所在目录的父目录（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 切换到项目根目录
cd "$PROJECT_ROOT" || {
    echo "错误: 无法切换到项目根目录 $PROJECT_ROOT" >&2
    exit 1
}

# 定义路径
SKYNET_DIR="$PROJECT_ROOT/skynet"
SKYNET_BIN="$SKYNET_DIR/skynet"
CONFIG_FILE="../config/main_node"

# 检查 skynet 目录与可执行文件
if [ ! -d "$SKYNET_DIR" ]; then
    echo "错误: 找不到 skynet 目录: $SKYNET_DIR" >&2
    exit 1
fi

if [ ! -f "$SKYNET_BIN" ]; then
    echo "错误: 找不到 skynet 可执行文件: $SKYNET_BIN" >&2
    exit 1
fi

# 检查 skynet 是否有执行权限
if [ ! -x "$SKYNET_BIN" ]; then
    echo "错误: skynet 文件没有执行权限: $SKYNET_BIN" >&2
    exit 1
fi

# 检查配置文件是否存在（相对 skynet 目录）
if [ ! -f "$SKYNET_DIR/$CONFIG_FILE" ]; then
    echo "错误: 找不到配置文件: $SKYNET_DIR/$CONFIG_FILE" >&2
    exit 1
fi

# 启动服务器（从 skynet 目录运行以匹配配置里的相对路径）
echo "正在启动 Skynet 服务器..."
echo "配置文件: $CONFIG_FILE"
echo "工作目录: $SKYNET_DIR"
echo "----------------------------------------"

cd "$SKYNET_DIR" || {
    echo "错误: 无法切换到 Skynet 目录 $SKYNET_DIR" >&2
    exit 1
}

exec "$SKYNET_BIN" "$CONFIG_FILE"