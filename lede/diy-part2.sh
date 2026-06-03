#!/bin/bash
echo "🔧 DIY Part 2: 编译前自定义操作（拉取插件与修改默认配置）"
echo "执行时间: $(date)"

# ==========================================
# 1. 添加自定义插件源码
# ==========================================
echo "开始拉取自定义插件..."

# 添加 kenzok8 插件库（包含 SSR Plus+ 和 MosDNS）
git clone --depth=1 https://github.com/kenzok8/openwrt-packages.git package/kenzok8
git clone --depth=1 https://github.com/kenzok8/small.git package/small

echo "✅ 插件源码拉取完成"

# ====================================================================
# 1. 修改默认管理 IP 为 192.168.100.1
# ====================================================================
echo "🌐 正在修改默认 IP 地址..."
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate
# 兼容部分新源码的写法
sed -i 's/192\.168\.1\.1/192.168.100.1/g' package/base-files/files/bin/config_generate
echo "✅ 默认 IP 已修改为 192.168.100.1"

# ====================================================================
# 2. 设置默认密码为空 (Root 无密码登录)
# ====================================================================
echo "🔑 正在清除默认密码..."
# 方法A：直接修改底层的 shadow 文件 (最稳妥)
if [ -f "package/base-files/files/etc/shadow" ]; then
    # 将 root 用户的密码哈希替换为空 (格式: root::19000:0:99999:7:::)
    sed -i 's/^root:[^:]*:/root::/' package/base-files/files/etc/shadow
fi

# 方法B：清理 zzz-default-settings 中可能强制设置密码的脚本 (Lean 源码特有)
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
    sed -i '/passwd/d' package/lean/default-settings/files/zzz-default-settings
    sed -i '/shadow/d' package/lean/default-settings/files/zzz-default-settings
fi
echo "✅ 默认密码已清空"

# ====================================================================
# 4. 设置默认 WiFi 名称 (JDC_AX6600) 和密码 (12345678)
# ====================================================================
echo "📶 正在配置默认 WiFi..."
# 使用 heredoc 创建一个独立的 WiFi 初始化脚本
# 这个脚本会在路由器首次启动时执行，确保 WiFi 配置绝对生效
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-custom-wifi <<'EOF'
#!/bin/sh
# 仅在首次启动时执行 (执行后系统会自动删除此脚本)

# 删除系统自动生成的默认无线配置
rm -f /etc/config/wireless

# 重新生成无线配置
wifi detect > /etc/config/wireless

# 修改 SSID 为 JDC_AX6600
sed -i 's/ssid=.*/ssid=JDC_AX6600/g' /etc/config/wireless
# 兼容没有引号的写法
sed -i "s/option ssid 'OpenWrt'/option ssid 'JDC_AX6600'/g" /etc/config/wireless
sed -i "s/option ssid 'LEDE'/option ssid 'JDC_AX6600'/g" /etc/config/wireless

# 开启无线 (将 disabled 1 改为 0)
sed -i 's/option disabled.*/option disabled 0/g' /etc/config/wireless

# 设置加密方式为 WPA2-PSK (psk2)
sed -i "s/option encryption 'none'/option encryption 'psk2'/g" /etc/config/wireless
sed -i 's/option encryption none/option encryption psk2/g' /etc/config/wireless

# 设置 WiFi 密码为 12345678
# 如果已有 key 字段则替换，没有则在 encryption 下方添加
if grep -q "option key" /etc/config/wireless; then
    sed -i "s/option key.*/option key '12345678'/g" /etc/config/wireless
else
    sed -i "/option encryption/a\\        option key '12345678'" /etc/config/wireless
fi

# 重启网络使配置生效
wifi reload
EOF

# 赋予执行权限
chmod +x package/base-files/files/etc/uci-defaults/99-custom-wifi
echo "✅ WiFi 配置已注入 (SSID: JDC_AX6600, 密码: 12345678)"



# ==========================================
# 3. 其他自定义操作
# ==========================================
# 例如：修改固件信息
# sed -i 's/OpenWrt/JDC-AX6600-OpenWrt/g' package/base-files/files/etc/banner

echo "✅ DIY Part 2 全部完成"
