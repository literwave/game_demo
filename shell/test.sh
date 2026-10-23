#!/bin/sh

# 不需要起服务器的检查：lua 语法、shell 语法、单元测试。CI 和本地都跑这个
#   sh shell/test.sh
# 需要先编译过 skynet（用它自带的 lua / luac）

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$PROJECT_ROOT" || exit 1

LUA=skynet/3rd/lua/lua
LUAC=skynet/3rd/lua/luac
if [ ! -x "$LUA" ] || [ ! -x "$LUAC" ]; then
	echo "错误: 找不到 $LUA / $LUAC，先 make" >&2
	exit 1
fi

FAIL=0

echo "== lua 语法"
LUA_CNT=0
for f in $(find logic common lualib orm start_up test -name '*.lua' | sort); do
	LUA_CNT=$((LUA_CNT + 1))
	if ! "$LUAC" -p -o /dev/null "$f"; then
		FAIL=1
	fi
done
echo "检查 $LUA_CNT 个文件"

echo "== shell 语法"
for f in shell/*.sh; do
	if head -n 1 "$f" | grep -q bash; then
		bash -n "$f" || FAIL=1
	else
		sh -n "$f" || FAIL=1
	fi
done

echo "== 单元测试"
"$LUA" test/unit/run.lua || FAIL=1

if [ "$FAIL" -ne 0 ]; then
	echo "失败" >&2
	exit 1
fi
echo "全部通过"
