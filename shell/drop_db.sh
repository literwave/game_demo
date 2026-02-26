#!/bin/bash

# --- MongoDB 配置 ---
MONGO_USER="root"
MONGO_PWD="a1"
MONGO_AUTH_DB="admin"
TARGET_DB="a120"

# --- Redis 配置 ---
REDIS_PWD="a1"
REDIS_HOST="127.0.0.1"
REDIS_PORT=6379

echo "开始清理数据库数据..."

# 1. 清理 MongoDB (删除指定的业务数据库)
# 使用 mongosh 执行 dropDatabase 操作
mongosh -u $MONGO_USER -p $MONGO_PWD --authenticationDatabase $MONGO_AUTH_DB <<EOF
use $TARGET_DB
db.dropDatabase()
exit
EOF

if [ $? -eq 0 ]; then
    echo "MongoDB: 数据库 $TARGET_DB 已成功删除。"
else
    echo "MongoDB: 删除失败，请检查权限或配置。"
fi

# 2. 清理 Redis (清空所有数据)
# 使用 redis-cli 执行 flushall
redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PWD flushall

if [ $? -eq 0 ]; then
    echo "Redis: 所有数据已清空。"
else
    echo "Redis: 清空失败，请检查密码或服务状态。"
fi

echo "所有清理操作已完成。"
