#!/bin/sh

# 热更 lua 文件 / 重载配置表
#   sh shell/hot_update.sh logic/service/agent/module/hero/mgr.lua [更多文件...]
#   sh shell/hot_update.sh -c                      # 只重载配置表
#   sh shell/hot_update.sh -c logic/define/const.lua
# 路径相对项目根目录。改 orm/schema/*.td 或协议需要重启

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_FILE="$SCRIPT_DIR/../config/main_node"

# 配置文件可能是 CRLF，先去掉 \r；值取到空白/引号为止，忽略行尾注释
read_cfg() {
	tr -d '\r' < "$CONFIG_FILE" | sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"\{0,1\}\([^\"[:space:]]*\).*/\1/p" | head -n 1
}

HTTP_PORT=$(read_cfg http_port)
HTTP_PORT=${HTTP_PORT:-33023}

CONFIG=0
if [ "$1" = "-c" ]; then
	CONFIG=1
	shift
fi

if [ "$CONFIG" = "0" ] && [ $# -eq 0 ]; then
	echo "用法: $0 [-c] 文件1 [文件2 ...]" >&2
	exit 1
fi

FILES=""
for f in "$@"; do
	f=${f#../}
	f=${f#./}
	if [ ! -f "$SCRIPT_DIR/../$f" ]; then
		echo "错误: 找不到文件 $f（路径相对项目根目录）" >&2
		exit 1
	fi
	FILES="${FILES:+$FILES,}$f"
done

OUT=$(curl -sS --max-time 60 -w "\n%{http_code}" "http://127.0.0.1:$HTTP_PORT/?method_tag=2&config=$CONFIG&files=$FILES" 2>&1)
CURL_RET=$?
HTTP_CODE=$(echo "$OUT" | tail -n 1)
RESULT=$(echo "$OUT" | sed '$d')
if [ "$CURL_RET" -ne 0 ]; then
	echo "错误: 请求 127.0.0.1:$HTTP_PORT 失败 (curl=$CURL_RET)：$RESULT" >&2
	echo "检查服务器是否在跑、http_port 是否一致" >&2
	exit 1
fi
echo "$RESULT"
[ "$HTTP_CODE" = "200" ] && [ "$(echo "$RESULT" | head -n 1)" = "ok" ]
