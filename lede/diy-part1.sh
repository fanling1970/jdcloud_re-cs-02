#!/bin/bash

echo "🔧 DIY Part 1: 编译前自定义操作"
echo "执行时间：$(date)"

# 1. 检查固件文件
if [ -d "bin/targets/qualcommax/ipq60xx" ]; then
  echo "找到固件文件"
  ls -lh bin/targets/qualcommax/ipq60xx/*.bin 2>/dev/null || true
fi

# 2. 克隆 mosdns（LEDE源码不自带）
echo "添加 mosdns 插件..."
rm -rf package/luci-app-mosdns
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns.git package/luci-app-mosdns

echo "✅ DIY Part 1 完成"
