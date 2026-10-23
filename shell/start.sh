#!/bin/sh

# Skynet 游戏服务器启动脚本
#   sh shell/start.sh      后台运行，输出写 log/skynet.log，关终端/ctrl+c 不影响
#   sh shell/start.sh -f   前台运行（调试用，ctrl+c 直接杀进程，未落盘数据会丢）
# 关服用 sh shell/stop.sh

FOREGROUND=0
if [ "$1" = "-f" ]; then
	FOREGROUND=1
fi
START_WAIT_SEC=${START_WAIT_SEC:-60}

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

# 配置文件可能是 CRLF，先去掉 \r；值取到空白/引号为止，忽略行尾注释
read_cfg() {
	tr -d '\r' < "$PROJECT_ROOT/config/main_node" | sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"\{0,1\}\([^\"[:space:]]*\).*/\1/p" | head -n 1
}
HTTP_PORT=$(read_cfg http_port)
HTTP_PORT=${HTTP_PORT:-33023}

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

OLD_PID=$(pgrep -f "skynet $CONFIG_FILE")
if [ -n "$OLD_PID" ]; then
	echo "错误: 服务器已在运行 (pid=$(echo $OLD_PID))，先 sh shell/stop.sh" >&2
	exit 1
fi

cd "$SKYNET_DIR" || {
    echo "错误: 无法切换到 Skynet 目录 $SKYNET_DIR" >&2
    exit 1
}

if [ "$FOREGROUND" = "1" ]; then
	exec "$SKYNET_BIN" "$CONFIG_FILE"
fi

LOG_DIR="$PROJECT_ROOT/log"
LOG_FILE="$LOG_DIR/skynet.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
START_LINE=$(($(wc -l < "$LOG_FILE") + 1))
# 新开会话脱离当前终端，ctrl+c / 关终端的信号到不了 skynet
setsid nohup "$SKYNET_BIN" "$CONFIG_FILE" >> "$LOG_FILE" 2>&1 < /dev/null &
PID=$!
echo "后台启动 pid=$PID，日志: $LOG_FILE"

# 问 mcs 要状态，main_start 拉起所有服务后才会变成 ready
i=0
while [ "$i" -lt "$START_WAIT_SEC" ]; do
	if [ "$(curl -s --max-time 2 "http://127.0.0.1:$HTTP_PORT/?method_tag=3")" = "ready" ]; then
		echo "启动完成"
		echo "看日志: tail -f $LOG_FILE"
		exit 0
	fi
	if ! kill -0 "$PID" 2>/dev/null; then
		echo "错误: 进程已退出，最近日志：" >&2
		tail -n +"$START_LINE" "$LOG_FILE" | tail -n 30 >&2
		exit 1
	fi
	sleep 1
	i=$((i + 1))
done
echo "错误: ${START_WAIT_SEC} 秒内没有启动完成（进程仍在 pid=$PID），最近日志：" >&2
tail -n +"$START_LINE" "$LOG_FILE" | tail -n 30 >&2
exit 1