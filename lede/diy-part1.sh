#!/bin/bash

echo "🔧 DIY Part 1: 编译前自定义操作"
echo "执行时间：$(date)"

# 1. 更新到最新 LEDE 源码
echo "更新 LEDE 源码..."
cd lede-source
git fetch origin
git reset --hard origin/master

# 2. 修复 vxlan 编译错误
echo "修复 vxlan_find_mac 编译错误..."
# 方法A：添加缺失的头文件包含
find . -name "vxlan_core.c" -type f | while read file; do
    if grep -q "vxlan_find_mac" "$file" && ! grep -q "vxlan_private.h" "$file"; then
        echo "修复文件: $file"
        sed -i 's/#include <net\/vxlan.h>/#include <net\/vxlan.h>\
#include <net\/vxlan_private.h>/' "$file"
    fi
done

# 方法B：如果方法A不行，创建补丁文件
cat > target/linux/generic/patches-6.12/999-fix-vxlan-implicit-declaration.patch << 'EOF'
From: LEDE Compile Fix <fix@lede.org>
Date: $(date)
Subject: Fix implicit declaration of vxlan_find_mac

Add missing header include for vxlan_find_mac declaration.

--- a/drivers/net/vxlan/vxlan_core.c
+++ b/drivers/net/vxlan/vxlan_core.c
@@ -10,6 +10,7 @@
 #include <net/rtnetlink.h>
 #include <net/switchdev.h>
 #include <net/vxlan.h>
+#include <net/vxlan_private.h>
 
 #define VXLAN_FDB_AGE_DEFAULT (10 * 60 * HZ)
 #define VXLAN_FDB_AGE_INTERVAL (10 * HZ)
EOF

# 3. 添加 mosdns 插件
echo "添加 mosdns 插件..."
rm -rf package/luci-app-mosdns
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns.git package/luci-app-mosdns

echo "✅ DIY Part 1 完成"
