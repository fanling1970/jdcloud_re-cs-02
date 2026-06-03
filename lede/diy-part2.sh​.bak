#!/bin/bash
echo "🔧 DIY Part 2: 编译后自定义操作"
echo "执行时间: $(date)"

# 1. 检查固件文件
if [ -d "bin/targets/qualcommax/ipq60xx" ]; then
  echo "找到固件文件"
  ls -lh bin/targets/qualcommax/ipq60xx/*.bin 2>/dev/null || true
fi

# 2. 添加自定义文件到固件
# mkdir -p files/etc/config
# echo "custom config" > files/etc/config/custom

# 3. 修改固件信息
# sed -i 's/OpenWrt/JDCloud-OpenWrt/g' package/base-files/files/etc/banner

echo "✅ DIY Part 2完成"
