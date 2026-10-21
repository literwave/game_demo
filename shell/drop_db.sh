#!/bin/bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_FILE="$SCRIPT_DIR/../config/main_node"

read_cfg() {
	sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"\{0,1\}\([^\"]*\)\"\{0,1\}.*/\1/p" "$CONFIG_FILE" | head -n 1
}

if [ ! -f "$CONFIG_FILE" ]; then
	echo "错误: 找不到配置文件 $CONFIG_FILE" >&2
	exit 1
fi

MONGO_HOST=$(read_cfg mongodb_host)
MONGO_PORT=$(read_cfg mongodb_port)
MONGO_USER=$(read_cfg mongodb_user)
MONGO_PWD=$(read_cfg mongodb_password)
REDIS_HOST=$(read_cfg redis_host)
REDIS_PORT=$(read_cfg redis_port)
REDIS_PWD=$(read_cfg redis_password)
GAME=$(read_cfg game)
HOST_ID=$(read_cfg host_id)

MONGO_HOST=${MONGO_HOST:-127.0.0.1}
MONGO_PORT=${MONGO_PORT:-27017}
REDIS_HOST=${REDIS_HOST:-127.0.0.1}
REDIS_PORT=${REDIS_PORT:-6379}
TARGET_DB="${GAME}${HOST_ID}"

if [ -z "$TARGET_DB" ]; then
	echo "错误: config/main_node 里没有 game 或 host_id" >&2
	exit 1
fi

echo "开始清理数据库数据..."

mongo_args=(--host "$MONGO_HOST" --port "$MONGO_PORT" --quiet)
if [ -n "$MONGO_USER" ] && [ -n "$MONGO_PWD" ]; then
	mongo_args+=(-u "$MONGO_USER" -p "$MONGO_PWD" --authenticationDatabase admin)
fi

mongosh "${mongo_args[@]}" --eval "db.getSiblingDB('$TARGET_DB').dropDatabase()"
if [ $? -eq 0 ]; then
	echo "MongoDB: 数据库 $TARGET_DB 已成功删除。"
else
	echo "MongoDB: 删除失败，请检查权限或配置。"
fi

redis_args=(-h "$REDIS_HOST" -p "$REDIS_PORT")
if [ -n "$REDIS_PWD" ]; then
	redis_args+=(-a "$REDIS_PWD")
fi

redis-cli "${redis_args[@]}" flushall
if [ $? -eq 0 ]; then
	echo "Redis: 所有数据已清空。"
else
	echo "Redis: 清空失败，请检查密码或服务状态。"
fi

echo "所有清理操作已完成。"
