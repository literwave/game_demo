#!/bin/sh

# 压测：起一个独立的 skynet 进程跑机器人，对已经在运行的服务器做完整登录 + 持续请求
#   sh shell/bench.sh                     默认 100 人、30 秒
#   sh shell/bench.sh -u 500 -d 60 -r 20  500 人，60 秒，20 秒内爬坡上完
#   sh shell/bench.sh -i 200              每人每 200ms 发一个请求（发完等回包再等间隔）
#   sh shell/bench.sh --relogin           顶号检查：同账号登两次，旧连接要被踢、新连接要可用
#
# 账号是 <前缀><序号>，同样的参数重复跑会复用同一批玩家，不会一直往库里加人
# 结果同时写到 log/bench_result.txt；通过退出 0，不通过退出 1
#
# 其他参数走环境变量：
#   BENCH_PREFIX          账号前缀，默认 bench_
#   BENCH_WORKERS         机器人服务数，默认 4
#   BENCH_TIMEOUT_MS      单个请求超时，默认 5000
#   BENCH_MAX_ERROR_RATE  失败比例上限，默认 0.01
#   BENCH_MAX_P99_MS      p99 上限，默认 0 不检查

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
CONFIG_FILE="$PROJECT_ROOT/config/main_node"

read_cfg() {
	tr -d '\r' < "$CONFIG_FILE" | sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"\{0,1\}\([^\"[:space:]]*\).*/\1/p" | head -n 1
}

BENCH_MODE=load
while [ $# -gt 0 ]; do
	case "$1" in
		-u) BENCH_USERS=$2; shift 2 ;;
		-d) BENCH_DURATION=$2; shift 2 ;;
		-r) BENCH_RAMP=$2; shift 2 ;;
		-i) BENCH_INTERVAL_MS=$2; shift 2 ;;
		-a) BENCH_LOGIN_ADDR=$2; shift 2 ;;
		--relogin) BENCH_MODE=relogin; shift ;;
		-h|--help) sed -n '3,17p' "$0"; exit 0 ;;
		*) echo "未知参数: $1（-h 看用法）" >&2; exit 1 ;;
	esac
done

LOGIN_PORT=$(read_cfg login_port)
BENCH_LOGIN_ADDR=${BENCH_LOGIN_ADDR:-127.0.0.1:${LOGIN_PORT:-33021}}
BENCH_SERVER_ID=${BENCH_SERVER_ID:-$(read_cfg host_id)}
mkdir -p "$PROJECT_ROOT/log"
BENCH_RESULT="$PROJECT_ROOT/log/bench_result.txt"
rm -f "$BENCH_RESULT"

export BENCH_MODE BENCH_USERS BENCH_DURATION BENCH_RAMP BENCH_INTERVAL_MS BENCH_LOGIN_ADDR BENCH_SERVER_ID BENCH_RESULT
export BENCH_PREFIX BENCH_WORKERS BENCH_TIMEOUT_MS BENCH_MAX_ERROR_RATE BENCH_MAX_P99_MS

cd "$PROJECT_ROOT/skynet" || exit 1
# skynet 自己的 LAUNCH / KILL 行不看；登录服回完包就断开，机器人这边关连接时的 socket 报错也不看
./skynet ../config/bench_node 2>&1 | grep -v -E '^\[:[0-9a-f]+\] (LAUNCH|KILL) |Broken pipe|Connection reset by peer|socket-server: invalid socket'

if [ ! -f "$BENCH_RESULT" ]; then
	echo "错误: 没有生成结果文件，压测进程异常退出" >&2
	exit 1
fi
[ "$(head -n 1 "$BENCH_RESULT")" = "PASS" ]
