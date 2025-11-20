#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
    if command -v bash >/dev/null 2>&1; then
        exec bash "$0" "$@"
    else
        echo "[gen_proto][错误] 当前 shell 不支持 bash 特性且未找到 bash 可执行文件" >&2
        exit 1
    fi
fi

COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
COLOR_RESET="\033[0m"

log() {
    echo -e "${COLOR_GREEN}[gen_proto]${COLOR_RESET} $*"
}

error() {
    echo -e "${COLOR_RED}[gen_proto][错误]${COLOR_RESET} $*" >&2
}

warn() {
    echo -e "${COLOR_YELLOW}[gen_proto][警告]${COLOR_RESET} $*"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PTOTOOL_DIR="$PROJECT_ROOT/tools/ptotools"
PROTO_DESC_DIR="$PTOTOOL_DIR/proto/proto_desc"
PROTO_DESC_ARG="${PROTO_DESC_DIR}/"
OUT_PB_DIR="$PTOTOOL_DIR/proto/outlua"
DEST_PB_DIR="$PROJECT_ROOT/proto/pb"
DEST_NETPB_DIR="$PROJECT_ROOT/logic/base"

if [ ! -d "$PTOTOOL_DIR" ]; then
    error "未找到 ptotools 目录: $PTOTOOL_DIR"
    exit 1
fi

if [ ! -d "$PROTO_DESC_DIR" ]; then
    error "未找到 proto 描述目录: $PROTO_DESC_DIR"
    exit 1
fi

if [ ! -d "$OUT_PB_DIR" ]; then
    error "未找到 proto 输出目录: $OUT_PB_DIR"
    exit 1
fi

mkdir -p "$DEST_PB_DIR" "$DEST_NETPB_DIR"

detect_python() {
    if [ -n "${PYTHON_BIN:-}" ] && command -v "$PYTHON_BIN" >/dev/null 2>&1; then
        return
    fi
    if [ -n "${PYTHON:-}" ] && command -v "$PYTHON" >/dev/null 2>&1; then
        PYTHON_BIN="$PYTHON"
        return
    fi
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_BIN="python3"
        return
    fi
    if command -v python >/dev/null 2>&1; then
        PYTHON_BIN="python"
        return
    fi
    error "未找到 python 解释器，请设置 PYTHON_BIN 或安装 python3/python"
    exit 1
}

detect_python

log "使用 Python: $PYTHON_BIN"
log "切换到: $PTOTOOL_DIR"

# 切换到 ptotools 目录执行 Python 脚本（因为脚本使用相对路径生成文件）
pushd "$PTOTOOL_DIR" >/dev/null || {
    error "无法切换到 ptotools 目录: $PTOTOOL_DIR"
    exit 1
}

run_python() {
    local script="$1"
    shift
    log "执行 $script $*"
    if ! "$PYTHON_BIN" "$script" "$@"; then
        error "执行失败: $script"
        popd >/dev/null
        exit 1
    fi
}

# 使用相对路径（因为已经在 PTOTOOL_DIR 了）
run_python "script/extractluapb.py" "proto/proto_desc/"
run_python "script/extractlua.py" "proto/proto_desc/"

popd >/dev/null

shopt -s nullglob
pb_files=("$OUT_PB_DIR"/*.pb)
if [ ${#pb_files[@]} -eq 0 ]; then
    error "在 $OUT_PB_DIR 未找到任何 .pb 文件"
    exit 1
fi

log "复制 ${#pb_files[@]} 个 .pb 文件到 $DEST_PB_DIR"
cp -f "${pb_files[@]}" "$DEST_PB_DIR/"

NETPB_FILE="$PTOTOOL_DIR/netPb.lua"
if [ ! -f "$NETPB_FILE" ]; then
    error "未生成 netPb.lua"
    exit 1
fi

log "复制 netPb.lua 到 $DEST_NETPB_DIR"
cp -f "$NETPB_FILE" "$DEST_NETPB_DIR/"

log "完成协议导出"