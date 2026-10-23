#!/bin/sh

# 安全关服后重新启动，参数透传给 start.sh（-f 前台）

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

sh "$SCRIPT_DIR/stop.sh" || exit 1
exec sh "$SCRIPT_DIR/start.sh" "$@"
