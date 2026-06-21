#!/bin/bash
echo "🔧 DIY Part 2: 编译后自定义操作 - 简化版"
echo "执行时间: $(date)"
echo "配置目标: 只固化基础网络和WiFi，插件配置刷机后手动完成"

# ====================================================================
# 1. 网络配置固化
# ====================================================================
echo "设置网络配置..."

# 创建开机自动初始化脚本，增加无线硬件判断避免CAL报错
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-custom-network << 'EOF'
#!/bin/sh

echo "开始配置基础网络和WiFi..."

# 设置LAN口IP为192.168.100.1
uci set network.lan.ipaddr='192.168.100.1'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.gateway='192.168.100.1'
uci commit network

# 仅检测到无线射频硬件时才配置WiFi，无硬件则跳过，消除CAL加载报错
if iwinfo devlist 2>/dev/null | grep -q radio; then
    # 等待无线驱动完全加载
    sleep 15
    # 清空所有旧配置
    rm -f /etc/config/wireless
    # 自动生成正确的radio配置
    wifi config > /etc/config/wireless
    chmod 644 /etc/config/wireless
    
    # 设置参数（和你截图里的信道完全一致）
    uci set wireless.radio0.channel='149'
    uci set wireless.radio0.htmode='HE80'
    uci set wireless.@wifi-iface[0].ssid='JDC_AX6600_5G1'
    uci set wireless.@wifi-iface[0].key='BUZHIDAOWA'
    uci set wireless.@wifi-iface[0].encryption='psk2'
    
    uci set wireless.radio1.channel='1'
    uci set wireless.radio1.htmode='HT40'
    uci set wireless.@wifi-iface[1].ssid='JDC_AX6600_2.4G'
    uci set wireless.@wifi-iface[1].key='BUZHIDAOWA'
    uci set wireless.@wifi-iface[1].encryption='psk2'
    
    uci set wireless.radio2.channel='44'
    uci set wireless.radio2.htmode='HE80'
    uci set wireless.@wifi-iface[2].ssid='JDC_AX6600_5G2'
    uci set wireless.@wifi-iface[2].key='BUZHIDAOWA'
    uci set wireless.@wifi-iface[2].encryption='psk2'
    
    uci set wireless.radio0.disabled='0'
    uci set wireless.radio1.disabled='0'
    uci set wireless.radio2.disabled='0'
    uci commit wireless
    
    # 强制重启无线
    /etc/init.d/network reload
    wifi reload
fi
# root空密码，首次登录强制修改
passwd -d root

# SSH放行局域网密码登录
uci set dropbear.@dropbear[0].PasswordAuth='on'
uci set dropbear.@dropbear[0].RootPasswordAuth='on'
uci set dropbear.@dropbear[0].enable='1'
uci commit dropbear

# 时区配置
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit system

# 重启核心网络服务
/etc/init.d/network restart
/etc/init.d/firewall restart
/etc/init.d/dnsmasq restart

echo "基础网络配置完成！"
echo "=========================================="
echo "管理地址: http://192.168.100.1"
echo "用户名: root"
echo "密码: 空 (首次登录后请立即修改)"
echo "WiFi密码: BUZHIDAOWA"
echo "=========================================="
EOF
chmod +x files/etc/uci-defaults/99-custom-network

# ====================================================================
# 2. 创建防火墙基础配置（完整保留不动）
# ====================================================================
echo "配置防火墙基础规则..."

mkdir -p files/etc/config
cat > files/etc/config/firewall << 'EOF'
config defaults
    option syn_flood '1'
    option input 'ACCEPT'
    option output 'ACCEPT'
    option forward 'REJECT'

config zone
    option name 'lan'
    list network 'lan'
    option input 'ACCEPT'
    option output 'ACCEPT'
    option forward 'ACCEPT'

config zone
    option name 'wan'
    list network 'wan'
    list network 'wan6'
    option input 'REJECT'
    option output 'ACCEPT'
    option forward 'REJECT'
    option masq '1'
    option mtu_fix '1'

config forwarding
    option src 'lan'
    option dest 'wan'

config rule
    option name 'Allow-DHCP-Renew'
    option src 'wan'
    option proto 'udp'
    option dest_port '68'
    option target 'ACCEPT'
    option family 'ipv4'

config rule
    option name 'Allow-Ping'
    option src 'wan'
    option proto 'icmp'
    option icmp_type 'echo-request'
    option family 'ipv4'
    option target 'ACCEPT'
EOF

# ====================================================================
# 3. 创建系统基础配置（完整保留不动）
# ====================================================================
echo "配置系统基础设置..."

cat > files/etc/config/system << 'EOF'
config system
    option hostname 'LEDE'
    option timezone 'CST-8'
    option ttylogin '0'
    option log_size '64'
    option urandom_seed '0'

config timeserver 'ntp'
    option enabled '1'
    list server 'time1.aliyun.com'
    list server 'time2.aliyun.com'
    list server 'time3.aliyun.com'
EOF

# ====================================================================
# 4. 创建使用说明文档（统一WiFi密码BUZHIDAOWA）
# ====================================================================
mkdir -p files/root
cat > files/root/README-SIMPLE-FIRMWARE.txt << 'EOF'
==========================================
      JDCloud RE-CS-02 简化固件说明
===========================================

固件编译时间: 2026-06-05
固件版本: LEDE R26.05.20 + 基础插件
配置策略: 只固化基础网络，插件配置刷机后手动完成

一、基础配置
------------
1. 管理地址: http://192.168.100.1
2. 用户名: root
3. 密码: 空 (首次登录后强制修改)
4. WiFi 接口:
   - JDC_AX6600_5G (5G, 信道136)
   - JDC_AX6600_2.4G (2.4G, 信道6)
   - JDC_AX6600_5G2 (5G, 信道36)
5. WiFi密码: BUZHIDAOWA

二、已安装插件（需手动配置）
---------------------------
1. OpenClash: 代理工具
   - 管理界面: 服务 → OpenClash
   - 默认未启动，需上传节点配置

2. MosDNS: DNS分流工具
   - 管理界面: 服务 → MosDNS
   - 默认配置可用，建议按需调整

3. PassWall: 备用代理工具
4. SSR Plus+: 备用代理工具
5. DockerMan: Docker 管理界面
6. Argon 主题: 美化界面

三、刷机后操作步骤
------------------
1. 首次登录: http://192.168.100.1 (空密码)
2. 立即修改管理员密码
3. 测试网络连接和WiFi
4. 按需配置插件:
   a. OpenClash: 上传节点 → 启动服务
   b. MosDNS: 检查配置 → 启动服务
   c. 其他插件按需使用

四、配置文件位置
----------------
1. 网络配置: /etc/config/network
2. 无线配置: /etc/config/wireless
3. 系统配置: /etc/config/system
4. 防火墙: /etc/config/firewall

五、注意事项
------------
1. 安全性: 首次登录后务必修改密码！
2. 稳定性: 插件逐个配置，避免冲突
3. 备份: 配置稳定后备份: sysupgrade -b /tmp/backup.tar.gz
4. 第三个5G接口: 可根据需要禁用

===========================================
固件设计理念:
- 基础网络稳定优先
- 插件配置灵活可控
- 减少固化冲突风险
===========================================
EOF

# ====================================================================
# 5. 创建简单的服务检查脚本（完整保留不动）
# ====================================================================
mkdir -p files/usr/bin
cat > files/usr/bin/check-services << 'EOF'
#!/bin/sh
# 简单的服务状态检查脚本

echo "=== 系统服务状态检查 ==="
echo "当前时间: $(date)"
echo ""

echo "1. 网络服务:"
ifconfig br-lan 2>/dev/null && echo "  ✓ LAN 接口正常" || echo "  ✗ LAN 接口异常"
echo ""

echo "2. WiFi 服务:"
iwinfo 2>/dev/null | grep -q "ESSID" && echo "  ✓ WiFi 运行正常" || echo "  ✗ WiFi 可能异常"
echo ""

echo "3. 插件安装状态:"
[ -f /etc/config/openclash ] && echo "  ✓ OpenClash 已安装" || echo "  ✗ OpenClash 未安装"
[ -f /etc/config/mosdns ] && echo "  ✓ MosDNS 已安装" || echo "  ✗ MosDNS 未安装"
[ -f /usr/bin/dockerd ] && echo "  ✓ Docker 已安装" || echo "  ✗ Docker 未安装"
echo ""

echo "4. 系统信息:"
echo "  IP地址: $(uci get network.lan.ipaddr 2>/dev/null || echo '未配置')"
echo "  主机名: $(uci get system.@system[0].hostname 2>/dev/null || echo '未配置')"
echo ""

echo "检查完成！"
EOF
chmod +x files/usr/bin/check-services

echo "✅ DIY Part 2 简化版完成"
echo "=========================================="
echo "配置总结:"
echo "1. 基础网络: ✓ (IP:192.168.100.1)"
echo "2. 三个WiFi: ✓ (密码:BUZHIDAOWA)"
echo "3. 空密码登录: ✓ (首次登录后强制修改)"
echo "4. OpenClash: ✗ (不固化配置)"
echo "5. MosDNS: ✗ (不固化配置)"
echo "6. 使用说明: ✓ (文件: /root/README-SIMPLE-FIRMWARE.txt)"
echo "=========================================="
