#!/bin/bash

echo "🔧 DIY Part 1: 编译前自定义操作"
echo "执行时间：$(date)"

# 1. 更新到最新 LEDE 源码
echo "更新 LEDE 源码..."
cd lede-source
git fetch origin
git reset --hard origin/master

# 2. 直接修复 vxlan 编译错误
echo "直接修复 vxlan_find_mac 编译错误..."

# 找到 vxlan_core.c 文件并修复
find . -name "vxlan_core.c" -type f | while read file; do
    echo "检查文件: $file"
    if grep -q "vxlan_find_mac" "$file"; then
        echo "发现需要修复的文件: $file"
        
        # 方法1：添加缺失的头文件包含
        if ! grep -q "#include <net/vxlan_private.h>" "$file"; then
            echo "添加缺失的头文件包含..."
            sed -i 's/#include <net\/vxlan.h>/#include <net\/vxlan.h>\
#include <net\/vxlan_private.h>/' "$file"
            echo "已修复 $file"
        fi
        
        # 方法2：如果找不到 vxlan_private.h，创建临时声明
        if ! grep -q "struct vxlan_fdb \*vxlan_find_mac" "$file"; then
            echo "添加 vxlan_find_mac 函数声明..."
            sed -i '1i\
/* 临时修复：添加 vxlan_find_mac 函数声明 */\
struct vxlan_fdb *vxlan_find_mac(struct vxlan_dev *vxlan, const u8 *mac, __be32 vni);\
' "$file"
        fi
    fi
done

# 3. 添加 mosdns 插件
echo "添加 mosdns 插件..."
rm -rf package/luci-app-mosdns
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns.git package/luci-app-mosdns

echo "✅ DIY Part 1 完成"
