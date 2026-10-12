#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
cd "$PROJECT_ROOT"

if [ ! -f skynet/Makefile ]; then
	echo "错误: 找不到 skynet（请先 git submodule update --init --recursive）" >&2
	exit 1
fi

make
echo "编译完成: skynet/skynet 与 skynet/luaclib/protobuf.so"
