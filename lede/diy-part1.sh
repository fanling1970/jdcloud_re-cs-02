#!/bin/bash
echo "🔧 DIY Part 1: 编译前自定义操作"
echo "执行时间: $(date)"
echo "工作目录: $(pwd)"

# 1. 添加通用补丁（如果有）
# patch -p1 < ../patches/some-patch.patch

# 2. 修改通用配置
# sed -i 's/old_value/new_value/g' some-file

# 3. 添加自定义软件包
# cp -r ../custom-packages/* package/

echo "✅ DIY Part 1完成"
