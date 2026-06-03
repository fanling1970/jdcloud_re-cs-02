#!/bin/bash
echo "🔧 DIY Part 2: JDCloud RE-CS-02 专用配置"
echo "执行时间: $(date)"

# ==========================================
# 1. 拉取插件（你已有 kenzok8）
# ==========================================
echo "📦 拉取插件..."
git clone --depth=1 https://github.com/kenzok8/openwrt-packages.git package/kenzok8
git clone --depth=1 https://github.com/kenzok8/small.git package/small
echo "✅ 插件完成"

# ==========================================
# 2. 固定管理 IP
# ==========================================
echo "🌐 设置 LAN IP 为 192.168.100.1"
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# ==========================================
# 3. 强制 root 密码为空（编译期）
# ==========================================
echo "🔑 设置 root 密码为空"
mkdir -p package/base-files/files/etc

cat << 'EOF' > package/base-files/files/etc/shadow
root::0:0:99999:7:::
daemon:*:0:0:99999:7:::
ftp:*:0:0:99999:7:::
network:*:0:0:99999:7:::
nobody:*:0:0:99999:7:::
EOF

# ==========================================
# 4. 三频 WiFi（IPQ6018 / ath11k）
# ==========================================
echo "📡 写入三频 WiFi 默认配置"

mkdir -p package/base-files/files/etc/config

cat << 'EOF' > package/base-files/files/etc/config/wireless
config wifi-device 'radio0'
        option type 'mac80211'
        option channel '1'
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

echo "✅ WiFi 配置完成"

# ==========================================
# 5. 可选：Banner 标识
# ==========================================
echo "JDCloud AX6600 | LEDE | $(date '+%Y-%m-%d')" \
  >> package/base-files/files/etc/banner

echo "🎉 DIY Part 2 全部完成"
