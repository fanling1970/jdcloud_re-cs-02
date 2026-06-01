#!/bin/bash

echo "🔧 DIY Part 1: 精简版本 - 只添加 Dockerman"

# 1. 更新 LEDE 源码
cd lede-source
git fetch origin
git reset --hard origin/master

# 2. 不添加任何额外插件（保持纯净）
echo "保持源码纯净，不添加额外插件"

# 3. 应用内核编译修复（如果之前有）
if [ -f target/linux/generic/patches-6.12/999-fix-vxlan.patch ]; then
    echo "移除之前的补丁..."
    rm target/linux/generic/patches-6.12/999-fix-vxlan.patch
fi

echo "✅ DIY Part 1 完成（精简版）"
