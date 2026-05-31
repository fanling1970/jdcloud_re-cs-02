#!/bin/bash

echo "🔧 DIY Part 1: 编译前自定义操作"
echo "执行时间：$(date)"

# 添加 mosdns 插件（LEDE源码不自带）
echo "克隆 mosdns 插件..."
rm -rf package/luci-app-mosdns
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns.git package/luci-app-mosdns

# 可选：添加其他第三方插件
# echo "克隆其他插件..."
# git clone --depth=1 https://github.com/xxx/xxx.git package/xxx

echo "✅ DIY Part 1 完成"
