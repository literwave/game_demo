#!/bin/bash

# --- 变量配置 ---
M_USER="root"
M_PWD="a1"
R_PWD="a1"

echo "开始停止服务..."

# 必须连接到 admin 数据库才能执行 shutdownServer
echo "正在通过 mongosh 关闭 MongoDB..."
mongosh -u $M_USER -p $M_PWD --authenticationDatabase admin --eval "db.getSiblingDB('admin').shutdownServer()"

export REDISCLI_AUTH="$R_PWD"
echo "正在关闭 Redis..."
redis-cli shutdown save

echo "所有服务已安全停止。"
