#!/bin/bash
# diy-part2.sh - 简化版本
# 只配置基础网络和WiFi，不固化插件配置
# 适用于 JDCloud RE-CS-02 (AX6600) + LEDE
# 生成时间: 2026-06-05

set -e

echo "开始执行 diy-part2.sh 简化配置..."
echo "配置目标: 基础网络 + 三个WiFi接口，不固化插件配置"

# ========== 1. 网络基础配置 ==========
echo "配置网络基础..."

cat > $FILES/etc/config/network << 'EOF'
config interface 'loopback'
    option ifname 'lo'
    option proto 'static'
    option ipaddr '127.0.0.1'
    option netmask '255.0.0.0'

config globals 'globals'
    option ula_prefix 'fdca:1ede:4578::/48'

config interface 'lan'
    option type 'bridge'
    option ifname 'lan1 lan2 lan3 lan4'
    option proto 'static'
    option ipaddr '192.168.100.1'
    option netmask '255.255.255.0'
    option ip6assign '60'

config interface 'wan'
    option ifname 'wan'
    option proto 'dhcp'

config interface 'wan6'
    option ifname 'wan'
    option proto 'dhcpv6'
EOF

# ========== 2. 无线配置（三个接口） ==========
echo "配置无线网络（三个接口）..."

cat > $FILES/etc/config/wireless << 'EOF'
# 无线配置 - JDCloud AX6600
# 三个无线接口：2.4G + 5G + 5G
# 密码统一：12345678

config wifi-device 'radio0'
    option type 'mac80211'
    option band '5g'
    option htmode 'HE80'
    option channel '136'
    option path 'platform/ahb/18100000.wifi'
    option hwmode '11a'
    option disabled '0'

config wifi-iface 'default_radio0'
    option device 'radio0'
    option network 'lan'
    option mode 'ap'
    option ssid 'JDC_AX6600_5G'
    option encryption 'psk2'
    option key '12345678'

config wifi-device 'radio1'
    option type 'mac80211'
    option band '2g'
    option htmode 'HT40'
    option channel '6'
    option path 'platform/ahb/18100000.wifi+1'
    option hwmode '11g'
    option disabled '0'

config wifi-iface 'default_radio1'
    option device 'radio1'
    option network 'lan'
    option mode 'ap'
    option ssid 'JDC_AX6600_2.4G'
    option encryption 'psk2'
    option key '12345678'

config wifi-device 'radio2'
    option type 'mac80211'
    option band '5g'
    option htmode 'HE80'
    option channel '36'
    option path 'platform/ahb/18100000.wifi+2'
    option hwmode '11a'
    option disabled '0'

config wifi-iface 'default_radio2'
    option device 'radio2'
    option network 'lan'
    option mode 'ap'
    option ssid 'JDC_AX6600_5G2'
    option encryption 'psk2'
    option key '12345678'
EOF

# ========== 3. 基础 DHCP/DNS 配置 ==========
echo "配置 DHCP/DNS 服务..."

cat > $FILES/etc/config/dhcp << 'EOF'
config dnsmasq
    option domainneeded '1'
    option boguspriv '1'
    option filterwin2k '0'
    option localise_queries '1'
    option rebind_protection '1'
    option rebind_localhost '1'
    option local '/lan/'
    option domain 'lan'
    option expandhosts '1'
    option nonegcache '0'
    option authoritative '1'
    option readethers '1'
    option leasefile '/tmp/dhcp.leases'
    option resolvfile '/tmp/resolv.conf.auto'
    option nonwildcard '1'
    option localservice '1'
    list server '223.5.5.5'
    list server '119.29.29.29'

config dhcp 'lan'
    option interface 'lan'
    option start '100'
    option limit '150'
    option leasetime '12h'
    option dhcpv4 'server'
    option dhcpv6 'server'
    option ra 'server'

config dhcp 'wan'
    option interface 'wan'
    option ignore '1'

config odhcpd 'odhcpd'
    option maindhcp '0'
    option leasefile '/tmp/hosts/odhcpd'
    option leasetrigger '/usr/sbin/odhcpd-update'
EOF

# ========== 4. 系统基础配置 ==========
echo "配置系统基础设置..."

cat > $FILES/etc/config/system << 'EOF'
config system
    option hostname 'LEDE'
    option timezone 'CST-8'
    option zonename 'Asia/Shanghai'

config timeserver 'ntp'
    option enabled '1'
    list server 'ntp.aliyun.com'
    list server 'time1.cloud.tencent.com'
    list server 'time.apple.com'

config led 'led_sys'
    option name 'SYS'
    option sysfs 'led_sys'
    option trigger 'heartbeat'
EOF

# ========== 5. 空密码登录配置 ==========
echo "配置空密码登录（首次登录后修改）..."

cat > $FILES/etc/uci-defaults/99-first-login << 'EOF'
#!/bin/sh
# 首次启动配置脚本
# 设置空密码登录，首次登录后请立即修改密码

echo "首次启动配置..."

# 删除 root 密码（设置为空）
passwd -d root 2>/dev/null || true

# 设置 SSH 允许空密码登录
uci set dropbear.@dropbear[0].PasswordAuth='on'
uci set dropbear.@dropbear[0].RootPasswordAuth='on'
uci commit dropbear

# 启用 SSH 服务
/etc/init.d/dropbear enable
/etc/init.d/dropbear start

# 设置默认 DNS
echo "nameserver 223.5.5.5" > /tmp/resolv.conf.auto
echo "nameserver 119.29.29.29" >> /tmp/resolv.conf.auto

# 确保 IP 转发开启
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "首次启动配置完成。请立即登录并修改密码！"
echo "登录地址: http://192.168.100.1"
echo "SSH: root@192.168.100.1 (空密码)"

exit 0
EOF
chmod +x $FILES/etc/uci-defaults/99-first-login

# ========== 6. 基础启动脚本 ==========
echo "配置启动脚本..."

cat > $FILES/etc/rc.local << 'EOF'
#!/bin/sh -e

# 基础启动脚本
# 确保网络转发开启
echo 1 > /proc/sys/net/ipv4/ip_forward

# 设置防火墙基础规则（如果缺失）
if ! iptables -t nat -L POSTROUTING -n | grep -q MASQUERADE; then
    iptables -t nat -A POSTROUTING -o wan -j MASQUERADE
fi

exit 0
EOF
chmod +x $FILES/etc/rc.local

# ========== 7. 创建必要目录 ==========
echo "创建必要目录结构..."
mkdir -p $FILES/var/run
mkdir -p $FILES/tmp
mkdir -p $FILES/etc/uci-defaults
mkdir -p $FILES/root

# ========== 8. 创建刷机后说明文件 ==========
echo "创建刷机后说明文件..."

cat > $FILES/root/README-FIRST.txt << 'EOF'
==========================================
          LEDE 固件刷机后说明
==========================================

固件信息:
- 设备: JDCloud RE-CS-02 (AX6600)
- 源码: coolsnowwolf/lede
- 编译时间: 2026-06-05
- 版本: LEDE 定制版

网络配置:
- 管理地址: 192.168.100.1
- 登录密码: 空（首次登录后请立即修改）
- WiFi SSID: JDC_AX6600_5G / JDC_AX6600_2.4G / JDC_AX6600_5G2
- WiFi 密码: 12345678

已安装插件（需手动配置）:
- OpenClash
- MosDNS
- PassWall
- ShadowSocksR Plus+
- DockerMan
- Argon 主题

刷机后步骤:
1. 连接 WiFi 或网线到 LAN 口
2. 浏览器访问 http://192.168.100.1
3. 使用空密码登录
4. 立即修改管理员密码
5. 按需配置插件

重要提醒:
- 首次登录后务必修改密码！
- 插件需要手动配置才能使用
- 建议备份配置: sysupgrade -b /tmp/backup.tar.gz

技术支持:
- 仓库: github.com/fanling1970/lede-ax6600
-JDC_AX6600_5G2 为第二个5G频段，可根据需要禁用

==========================================
EOF

echo "========================================"
echo "diy-part2.sh 简化版本执行完成！"
echo "配置摘要:"
echo "  1. 网络: 192.168.100.1/24, 空密码"
echo "  2. 无线: 3个接口 (2.4G+5G+5G), 密码 12345678"
echo "  3. 服务: DHCP/DNS, SSH, 空密码登录"
echo "  4. 目录: 创建必要目录结构"
echo "  5. 说明: 刷机后说明文件"
echo "  6. 未固化: OpenClash/MosDNS 等插件配置"
echo "========================================"
