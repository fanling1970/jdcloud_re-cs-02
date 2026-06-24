# ==========================================
# 1. 拉取插件（你已有 kenzok8）
# ==========================================

# ==========================================
# 2. 固定管理 IP（config_generate 会被 firstboot 使用）
# ==========================================
echo "🌐 设置 LAN IP 为 192.168.100.1"
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# ==========================================
# 3. 使用 uci-defaults 机制（首次启动自动执行）
# ==========================================
echo "🛠 创建 uci-defaults 脚本（首次启动生效）"
mkdir -p package/base-files/files/etc/uci-defaults

# ---------- 3.1 强制 root 密码为空 ----------
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-set-root-password-empty
#!/bin/sh
# 强制设置 root 密码为空
sed -i 's/^root:[^:]*:/root::/' /etc/shadow
echo "✅ root 密码已设为空"
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-set-root-password-empty

# ---------- 3.2 三频 WiFi 配置（首次启动执行）----------
cat << 'EOF' > package/base-files/files/etc/uci-defaults/98-setup-wifi
#!/bin/sh
# 等待系统完全启动
sleep 5

# 检测无线设备
for radio in /sys/class/ieee80211/*; do
   [ -e "$radio" ] || continue
   radio_name=$(basename "$radio")
   
   # 判断频段
   if iw phy "$radio_name" info | grep -q "Band 2"; then
       # 2.4G
       uci set wireless.${radio_name}.channel='6'
       uci set wireless.${radio_name}.hwmode='11g'
       uci set wireless.${radio_name}.htmode='HT40'
       uci set wireless.default_${radio_name}.ssid='JDC_AX6600_2.4G'
       uci set wireless.default_${radio_name}.disabled='0'
   elif iw phy "$radio_name" info | grep -q "5180 MHz"; then
       # 5G (36信道附近)
       uci set wireless.${radio_name}.channel='36'
       uci set wireless.${radio_name}.hwmode='11a'
       uci set wireless.${radio_name}.htmode='VHT80'
       uci set wireless.default_${radio_name}.ssid='JDC_AX6600_5G'
       uci set wireless.default_${radio_name}.disabled='0'
   elif iw phy "$radio_name" info | grep -q "5745 MHz"; then
       # 5G2 (149信道附近)
       uci set wireless.${radio_name}.channel='149'
       uci set wireless.${radio_name}.hwmode='11a'
       uci set wireless.${radio_name}.htmode='VHT80'
       uci set wireless.default_${radio_name}.ssid='JDC_AX6600_5G2'
       uci set wireless.default_${radio_name}.disabled='0'
   fi
   
   # 通用设置
   uci set wireless.default_${radio_name}.encryption='psk2'
   uci set wireless.default_${radio_name}.key='12345678'
   uci set wireless.${radio_name}.country='CN'
done

# 提交配置并重启无线
uci commit wireless
wifi reload
echo "✅ WiFi 配置完成"
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/98-setup-wifi

# ==========================================
# 4. 备选方案：直接写入 wireless 配置文件（双重保险）
# ==========================================
echo "📡 直接写入 wireless 配置文件（备选）"
mkdir -p package/base-files/files/etc/config

cat << 'EOF' > package/base-files/files/etc/config/wireless
config wifi-device 'radio0'
       option type 'mac80211'
       option channel '6'
       option hwmode '11g'
       option htmode 'HT40'
       option country 'CN'

config wifi-iface 'default_radio0'
       option device 'radio0'
       option network 'lan'
       option mode 'ap'
       option ssid 'JDC_AX6600_2.4G'
       option encryption 'psk2'
       option key '12345678'
       option disabled '0'

config wifi-device 'radio1'
       option type 'mac80211'
       option channel '36'
       option hwmode '11a'
       option htmode 'VHT80'
       option country 'CN'

config wifi-iface 'default_radio1'
       option device 'radio1'
       option network 'lan'
       option mode 'ap'
       option ssid 'JDC_AX6600_5G'
       option encryption 'psk2'
       option key '12345678'
       option disabled '0'

config wifi-device 'radio2'
       option type 'mac80211'
       option channel '149'
       option hwmode '11a'
       option htmode 'VHT80'
       option country 'CN'

config wifi-iface 'default_radio2'
       option device 'radio2'
       option network 'lan'
       option mode 'ap'
       option ssid 'JDC_AX6600_5G2'
       option encryption 'psk2'
       option key '12345678'
       option disabled '0'
EOF

# ==========================================
# 5. 防止 firstboot 重置密码（关键步骤）
# ==========================================
echo "🔒 防止 firstboot 重置密码"
# 创建一个标记文件，告诉系统已经完成初始设置
mkdir -p package/base-files/files/etc
touch package/base-files/files/etc/.config_initialized

# ==========================================
# 6. Banner 标识
# ==========================================
echo "JDCloud AX6600 | LEDE | $(date '+%Y-%m-%d')" \
>> package/base-files/files/etc/banner

echo "🎉 DIY Part 2 全部完成（修复版）"
