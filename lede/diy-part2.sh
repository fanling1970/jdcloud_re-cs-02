#!/bin/bash

echo "🔧 DIY Part 2: 编译前重新应用配置"

# 1. 检查是否有备份配置
if [ -f .config.backup ]; then
    echo "发现备份配置，恢复配置..."
    cp .config.backup .config
    make defconfig
    echo "✅ 配置已恢复"
else
    echo "⚠️ 未找到备份配置，使用当前配置"
fi

# 2. 确保关键配置被应用
echo "确保关键配置被应用..."

# 创建临时脚本来强制应用配置
cat > apply_fix.sh << 'EOF'
#!/bin/bash
# 强制禁用问题包
sed -i 's/CONFIG_PACKAGE_luci=y/# CONFIG_PACKAGE_luci=y/' .config 2>/dev/null || true
sed -i 's/CONFIG_PACKAGE_luci-compat=y/# CONFIG_PACKAGE_luci-compat=y/' .config 2>/dev/null || true
sed -i 's/CONFIG_PACKAGE_default-settings=y/# CONFIG_PACKAGE_default-settings=y/' .config 2>/dev/null || true
sed -i 's/CONFIG_PACKAGE_ddns-scripts_aliyun=y/# CONFIG_PACKAGE_ddns-scripts_aliyun=y/' .config 2>/dev/null || true
sed -i 's/CONFIG_PACKAGE_ddns-scripts_dnspod=y/# CONFIG_PACKAGE_ddns-scripts_dnspod=y/' .config 2>/dev/null || true
sed -i 's/CONFIG_PACKAGE_wget-ssl=y/# CONFIG_PACKAGE_wget-ssl=y/' .config 2>/dev/null || true
sed -i 's/CONFIG_PACKAGE_kmod-vxlan=y/# CONFIG_PACKAGE_kmod-vxlan=y/' .config 2>/dev/null || true

# 确保 WERROR 被禁用
echo "CONFIG_WERROR=n" >> .config
EOF

chmod +x apply_fix.sh
./apply_fix.sh

# 3. 重新应用配置
make defconfig

echo "✅ DIY Part 2 完成（配置已锁定）"
