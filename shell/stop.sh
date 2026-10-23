#!/bin/sh

# 安全关服：经 mcs 按顺序关服务，等所有数据落盘后进程自己退出
# 不要直接 kill，没写完的数据会丢

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_FILE="$SCRIPT_DIR/../config/main_node"
WAIT_SEC=${WAIT_SEC:-60}

# 配置文件可能是 CRLF，先去掉 \r；值取到空白/引号为止，忽略行尾注释
read_cfg() {
	tr -d '\r' < "$CONFIG_FILE" | sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"\{0,1\}\([^\"[:space:]]*\).*/\1/p" | head -n 1
}

HTTP_PORT=$(read_cfg http_port)
HTTP_PORT=${HTTP_PORT:-33023}

PID_LIST=$(pgrep -f "skynet ../config/main_node")
if [ -z "$PID_LIST" ]; then
	echo "服务器没在运行"
	exit 0
fi
if [ "$(echo "$PID_LIST" | wc -l)" -gt 1 ]; then
	echo "错误: 有多个服务器进程在跑: $(echo $PID_LIST)，端口只会被其中一个占用，请先手动确认" >&2
	exit 1
fi
PID=$PID_LIST

echo "正在关服 (pid=$PID, http_port=$HTTP_PORT)..."
# 关服要等所有 agent 落盘，给足时间
OUT=$(curl -sS --max-time 120 -w "\n%{http_code}" "http://127.0.0.1:$HTTP_PORT/?method_tag=1" 2>&1)
CURL_RET=$?
HTTP_CODE=$(echo "$OUT" | tail -n 1)
RESULT=$(echo "$OUT" | sed '$d')
if [ "$CURL_RET" -ne 0 ]; then
	echo "错误: 请求 127.0.0.1:$HTTP_PORT 失败 (curl=$CURL_RET)：$RESULT" >&2
	echo "7=端口没监听（服务器还没起完/端口配置不一致），52=连接被关（来源 IP 不在 mcs 白名单），28=超时（看服务器日志卡在哪一步）" >&2
	exit 1
fi
echo "mcs: $RESULT"
case "$HTTP_CODE:$RESULT" in
	200:stopped*) ;;
	*)
		echo "错误: 关服没有执行 (http=$HTTP_CODE)，进程仍在运行" >&2
		exit 1
		;;
esac

i=0
while kill -0 "$PID" 2>/dev/null; do
	if [ "$i" -ge "$WAIT_SEC" ]; then
		echo "错误: ${WAIT_SEC} 秒后进程仍在，请看日志确认是否卡在某个服务" >&2
		exit 1
	fi
	sleep 1
	i=$((i + 1))
done
echo "已关服"
