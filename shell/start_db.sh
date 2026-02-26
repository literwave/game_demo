#!/bin/bash

# --- 路径配置 (请根据你实际安装路径修改) ---
MONGOD_PATH="/usr/local/mongodb/bin/mongod"
MONGO_CONF="/usr/local/mongodb/conf/mongodb.conf"

REDIS_SERVER="/usr/local/redis/redis-server"
REDIS_CONF="/usr/local/redis/conf/redis.conf"

echo "--- 正在启动所有服务 ---"

# 1. 启动 MongoDB
# 必须显式指定 --config，否则 auth = true 不会生效
if [ -f "$MONGO_CONF" ]; then
    echo "正在启动 MongoDB..."
    $MONGOD_PATH --config $MONGO_CONF & 
else
    echo "错误: 找不到 MongoDB 配置文件 $MONGO_CONF"
fi

# 2. 启动 Redis
# 必须带上配置文件路径，否则 requirepass a1 不会生效
if [ -f "$REDIS_CONF" ]; then
    echo "正在启动 Redis..."
    $REDIS_SERVER $REDIS_CONF &
else
    echo "错误: 找不到 Redis 配置文件 $REDIS_CONF"
fi

# 等待数据库初始化
sleep 2
echo "--- 所有服务已在后台启动 ---"
