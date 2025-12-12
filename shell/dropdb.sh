#!/bin/bash

# MongoDB 清档脚本（仅使用 mongo shell）

# 获取脚本所在目录的父目录（项目根目录）
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# 切换到项目根目录
cd "$PROJECT_ROOT" || {
    echo "错误: 无法切换到项目根目录 $PROJECT_ROOT" >&2
    exit 1
}

# 配置文件路径
CONFIG_FILE="$PROJECT_ROOT/config/main_node"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误: 找不到配置文件: $CONFIG_FILE" >&2
    exit 1
fi

# 从配置文件读取 MongoDB 连接信息
MONGO_HOST=$(grep "^mongodb_host" "$CONFIG_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/' | head -1)
MONGO_PORT=$(grep "^mongodb_port" "$CONFIG_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/' | head -1)
MONGO_USER=$(grep "^mongodb_user" "$CONFIG_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/' | head -1)
MONGO_PASS=$(grep "^mongodb_password" "$CONFIG_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/' | head -1)
GAME_NAME=$(grep "^game" "$CONFIG_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/' | head -1)
HOST_ID=$(grep "^host_id" "$CONFIG_FILE" | sed 's/.*= *"\([^"]*\)".*/\1/' | head -1)

# 默认值
MONGO_HOST=${MONGO_HOST:-"127.0.0.1"}
MONGO_PORT=${MONGO_PORT:-"27017"}
MONGO_USER=${MONGO_USER:-""}
MONGO_PASS=${MONGO_PASS:-""}
GAME_NAME=${GAME_NAME:-"a"}
HOST_ID=${HOST_ID:-"120"}

# 计算数据库名（game + host_id，例如 a120）
DB_NAME="${GAME_NAME}${HOST_ID}"

# 查找 mongo 命令（优先 PATH，其次上一级目录）
MONGO_CMD=""
# 优先检查系统 PATH 中的命令
if command -v mongo &> /dev/null; then
    MONGO_CMD=$(command -v mongo)
# 检查上一级目录中的 mongo（转换为绝对路径）
elif [ -f "$PROJECT_ROOT/../mongo" ] && [ -x "$PROJECT_ROOT/../mongo" ]; then
    MONGO_CMD=$(cd "$PROJECT_ROOT/.." && pwd)/mongo
elif [ -f "$PROJECT_ROOT/../mongo.exe" ] && [ -x "$PROJECT_ROOT/../mongo.exe" ]; then
    MONGO_CMD=$(cd "$PROJECT_ROOT/.." && pwd)/mongo.exe
# 检查当前目录的 mongo
elif [ -f "$PROJECT_ROOT/mongo" ] && [ -x "$PROJECT_ROOT/mongo" ]; then
    MONGO_CMD="$PROJECT_ROOT/mongo"
elif [ -f "$PROJECT_ROOT/mongo.exe" ] && [ -x "$PROJECT_ROOT/mongo.exe" ]; then
    MONGO_CMD="$PROJECT_ROOT/mongo.exe"
else
    echo "错误: 未找到 mongo 命令" >&2
    echo "已检查以下位置:" >&2
    echo "  - 系统 PATH" >&2
    echo "  - $PROJECT_ROOT/../mongo" >&2
    echo "  - $PROJECT_ROOT/mongo" >&2
    echo "请先安装 MongoDB shell (mongo) 或将其放到上述位置" >&2
    exit 1
fi

# 验证 mongo 命令是否真的存在且可执行
if [ ! -f "$MONGO_CMD" ] && ! command -v "$MONGO_CMD" &> /dev/null; then
    echo "错误: mongo 命令路径无效: $MONGO_CMD" >&2
    exit 1
fi

echo "使用 MongoDB Shell: $MONGO_CMD"

# 显示清档信息
echo "=========================================="
echo "MongoDB 清档脚本"
echo "=========================================="
echo "MongoDB 地址: $MONGO_HOST:$MONGO_PORT"
echo "数据库名称: $DB_NAME"
echo "=========================================="
echo ""
echo "⚠️  警告: 此操作将删除数据库 '$DB_NAME' 中的所有数据！"
echo ""

# 确认操作
read -p "确认要清空数据库吗？(输入 'yes' 继续): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "操作已取消"
    exit 0
fi

echo ""
echo "正在连接 MongoDB..."
echo ""

# 构建清档 JS 脚本
MONGO_JS_SCRIPT=$(cat <<MONGO_SCRIPT
// 显示当前数据库的所有集合
print("当前数据库集合列表:");
db.getCollectionNames().forEach(function(collection) {
    var count = db[collection].count();
    print("  - " + collection + " (" + count + " 条文档)");
});

print("\\n开始清空数据库...");

// 删除所有集合
db.getCollectionNames().forEach(function(collection) {
    if (collection.indexOf("system.") !== 0) {
        db[collection].drop();
        print("已删除集合: " + collection);
    }
});

print("\\n✅ 数据库 '$DB_NAME' 清空完成！");
MONGO_SCRIPT
)

# 执行清档
if [ -n "$MONGO_USER" ] && [ -n "$MONGO_PASS" ]; then
    echo "$MONGO_JS_SCRIPT" | "$MONGO_CMD" --host "$MONGO_HOST" --port "$MONGO_PORT" \
        -u "$MONGO_USER" -p "$MONGO_PASS" \
        --authenticationDatabase admin \
        --quiet "$DB_NAME"
else
    echo "$MONGO_JS_SCRIPT" | "$MONGO_CMD" --host "$MONGO_HOST" --port "$MONGO_PORT" \
        --quiet "$DB_NAME"
fi

# 检查执行结果
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 清档操作成功完成"
    exit 0
else
    echo ""
    echo "❌ 清档操作失败，请检查 MongoDB 连接和权限"
    exit 1
fi

