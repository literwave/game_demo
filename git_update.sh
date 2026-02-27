#!/usr/bin/env bash
set -euo pipefail

BRANCH=${GIT_BRANCH:-master}  # 之前看你日志是 master 分支
INCLUDE_3RD=${INCLUDE_3RD:-no}

# 进入仓库根目录
cd "$(dirname "$0")"

echo "================================"
echo "   Git 助手 - 分支: $BRANCH"
echo "================================"
echo " 1) UPDATE (拉取远端更新)"
echo " 2) COMMIT (提交本地修改)"
echo " q) 退出"
echo "--------------------------------"
read -p "请选择操作 [1/2/q]: " CHOICE

case $CHOICE in
    1)
        echo ">>> 开始更新代码..."
        git fetch origin "$BRANCH"
        git checkout "$BRANCH"
        git pull origin "$BRANCH"
        
        # 询问是否同步 3rd 子模块
        read -p "是否同步更新 3rd 库? (y/n): " PULL_SUB
        if [ "$PULL_SUB" = "y" ]; then
            echo "正在更新子模块..."
            git submodule update --init --remote 3rd || true
        fi
        echo ">>> 更新完成。"
        ;;

    2)
        echo ">>> 准备提交代码..."
        read -p "请输入 Commit Message (直接回车则用 'up'): " MSG
        MSG=${MSG:-"up"}

        # 暂存处理
        if [ "$INCLUDE_3RD" != "yes" ]; then
            git add -A
            if [ -d "3rd" ]; then
                git reset -- "3rd/" >/dev/null 2>&1 || true
            fi
            echo "已添加变更 (已排除 3rd 目录)"
        else
            git add -A
            echo "已添加所有变更 (包含 3rd 目录)"
        fi

        # 检查并推送
        if git diff --cached --quiet; then
            echo "提示: 没有检测到任何变化，无需提交。"
        else
            git commit -m "$MSG"
            echo ">>> 正在推送至 origin/$BRANCH..."
            git push origin "$BRANCH"
            echo ">>> 提交并推送成功！"
        fi
        ;;

    q|Q)
        echo "退出脚本。"
        exit 0
        ;;

    *)
        echo "无效输入，脚本结束。"
        exit 1
        ;;
esac