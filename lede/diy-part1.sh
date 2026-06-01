#!/bin/bash

echo "🔧 DIY Part 1: 强制应用精简配置"

# 1. 更新 LEDE 源码
cd lede-source
git fetch origin
git reset --hard origin/master

# 2. 创建绝对最小化配置
echo "创建绝对最小化配置..."

cat > .config << 'EOF'
# =====================================================
# 绝对最小化配置 - 确保编译通过
# =====================================================
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq60xx=y
CONFIG_TARGET_qualcommax_ipq60xx_DEVICE_jdcloud_re-cs-02=y

# 绝对必要的包（不能再少了）
CONFIG_PACKAGE_base-files=y
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_firewall=y
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_iptables=y
CONFIG_PACKAGE_opkg=y
CONFIG_PACKAGE_procd=y
CONFIG_PACKAGE_uci=y

# 无线驱动
CONFIG_PACKAGE_kmod-ath11k-ahb=y
CONFIG_PACKAGE_ath11k-firmware-ipq6018=y

# 禁用所有非必要包
CONFIG_PACKAGE_luci=n
CONFIG_PACKAGE_luci-compat=n
CONFIG_PACKAGE_default-settings=n
CONFIG_PACKAGE_ddns-scripts_aliyun=n
CONFIG_PACKAGE_ddns-scripts_dnspod=n
CONFIG_PACKAGE_wget-ssl=n

# 禁用导致问题的包
CONFIG_PACKAGE_kmod-vxlan=n

# 内核编译修复
CONFIG_WERROR=n
EOF

# 3. 应用配置
echo "应用配置..."
make defconfig

echo "✅ DIY Part 1 完成（强制应用最小化配置）"
