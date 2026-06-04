#!/bin/bash
echo "🔧 DIY Part 2: 编译后自定义操作 - 固化配置"
echo "执行时间: $(date)"

# ====================================================================
# 1. 网络配置固化
# ====================================================================
echo "设置网络配置..."

# 创建网络配置脚本（首次启动时执行）
mkdir -p files/etc/uci-defaults
cat > files/etc/uci-defaults/99-custom-network << 'EOF'
#!/bin/sh
# 设置LAN口IP为192.168.100.1
uci set network.lan.ipaddr='192.168.100.1'
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.gateway='192.168.100.1'
uci set network.lan.dns='192.168.100.1'
uci commit network

# 设置无线网络
uci set wireless.radio0.channel='6'
uci set wireless.@wifi-iface[0].ssid='JDC_AX6600_2.4G'
uci set wireless.@wifi-iface[0].key='123456'
uci set wireless.@wifi-iface[0].encryption='psk2'

# 如果有5G radio
if [ -n "$(uci get wireless.radio1 2>/dev/null)" ]; then
    uci set wireless.radio1.channel='36'
    uci set wireless.@wifi-iface[1].ssid='JDC_AX6600_5G'
    uci set wireless.@wifi-iface[1].key='123456'
    uci set wireless.@wifi-iface[1].encryption='psk2'
fi
uci commit wireless

# 设置空密码（不安全，仅测试环境使用）
passwd -d root

echo "网络配置已固化"
EOF
chmod +x files/etc/uci-defaults/99-custom-network

# ====================================================================
# 2. OpenClash 配置固化
# ====================================================================
echo "固化 OpenClash 配置..."

# 创建 OpenClash 配置文件目录
mkdir -p files/etc/openclash

# 主配置文件
cat > files/etc/openclash/config.yaml << 'EOF'
# OpenClash 预配置固件版
# 固化时间: 2026-06-04

port: 7890
socks-port: 7891
redir-port: 7892
mixed-port: 7893
tproxy-port: 7895
ipv6: false
mode: rule
log-level: info
allow-lan: true
bind-address: '*'
external-controller: 0.0.0.0:9090
external-ui: ui
secret: ''
interface-name: br-lan

# DNS 设置
dns:
  enable: true
  listen: 0.0.0.0:7874
  ipv6: false
  default-nameserver:
    - 119.29.29.29
    - 223.5.5.5
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  use-hosts: true
  nameserver:
    - https://doh.pub/dns-query
    - https://dns.alidns.com/dns-query
  fallback:
    - tls://8.8.8.8:853
    - tls://1.1.1.1:853
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4

# 代理组（空配置，用户自行添加节点）
proxy-groups:
  - name: 🚀 节点选择
    type: select
    proxies:
      - DIRECT
      
  - name: 🎯 全球直连
    type: select
    proxies:
      - DIRECT
      
  - name: 🐟 漏网之鱼
    type: select
    proxies:
      - DIRECT

# 基础规则
rules:
  - DOMAIN,clash.razord.top,DIRECT
  - DOMAIN,yacd.haishan.me,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT
  - IP-CIDR,10.0.0.0/8,DIRECT
  - IP-CIDR,172.16.0.0/12,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,🐟 漏网之鱼
EOF

# OpenClash 启动配置
cat > files/etc/config/openclash << 'EOF'
config openclash 'config'
	option enable '0'  # 默认不启动，需要时手动开启
	option config_path '/etc/openclash/config.yaml'
	option log_level 'info'
	option ipv6_enable '0'
	option proxy_port '7890'
	option http_port '7890'
	option socks_port '7891'
	option redir_port '7892'
	option tproxy_port '7895'
	option mixed_port '7893'
	option dashboard_port '9090'
	option secret ''
	option lan_ac_mode '0'
	
config openclash 'settings'
	option auto_update '0'
	option auto_update_time '3'
	option geo_auto_update '0'
	option geo_update_week_time '4'
	option chnr6_auto_update '0'
	option chnr6_update_week_time '4'
EOF

# ====================================================================
# 3. MosDNS 配置固化
# ====================================================================
echo "固化 MosDNS 配置..."

# 创建 MosDNS 配置目录
mkdir -p files/etc/mosdns

# MosDNS 主配置
cat > files/etc/mosdns/config.yaml << 'EOF'
# MosDNS 预配置固件版
log:
  level: info
  file: "/tmp/mosdns.log"

plugins:
  # 缓存
  - tag: cache
    type: cache
    args:
      size: 20000
      lazy_cache_ttl: 86400

  # 本地 DNS
  - tag: local_seq
    type: sequence
    args:
      - exec: $local_ip
      - matches:
          - qtype 12
        exec: accept
      - exec: $local_forward
      - matches:
          - qtype 1
          - qtype 28
        exec: $local_hosts
      - exec: $local_dualstack

  # 远程 DNS
  - tag: remote_seq
    type: sequence
    args:
      - exec: $remote_forward
      - exec: $cache

  # 主查询序列
  - tag: main_sequence
    type: sequence
    args:
      - matches:
          - "!resp_ip 0.0.0.0/0"
        exec: $cache
      - exec: $local_seq
      - exec: $remote_seq

# 服务器配置
servers:
  - exec: $main_sequence
    listeners:
      - protocol: udp
        addr: ":5335"
      - protocol: tcp
        addr: ":5335"
EOF

# 自定义配置（用户可修改）
cat > files/etc/mosdns/config_custom.yaml << 'EOF'
# 自定义 MosDNS 配置
# 此文件会在启动时合并到主配置

local_ip:
  - exec: $local_ipv4
  - exec: $local_ipv6

local_forward:
  - exec: forward
    args:
      upstreams:
        - addr: "119.29.29.29"
        - addr: "223.5.5.5"

remote_forward:
  - exec: forward
    args:
      upstreams:
        - addr: "tls://8.8.8.8:853"
        - addr: "tls://1.1.1.1:853"

local_hosts:
  - exec: hosts
    args:
      hosts:
        - "router.lan 192.168.100.1"

local_dualstack:
  - exec: dualstack_ipv4_first
EOF

# MosDNS LuCI 配置
mkdir -p files/etc/config
cat > files/etc/config/mosdns << 'EOF'
config mosdns
	option enabled '1'
	option configfile '/etc/mosdns/config.yaml'
	option listen_port '5335'
	option logfile '/tmp/mosdns.log'
	option loglevel 'info'
	option dnsmasq_upstream '1'
	option bootstrap_dns '119.29.29.29,223.5.5.5'
	option local_dns '119.29.29.29,223.5.5.5'
	option remote_dns 'tls://8.8.8.8:853,tls://1.1.1.1:853'
	option geoip_url 'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat'
	option geosite_url 'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat'
EOF

# ====================================================================
# 4. 系统服务启动脚本
# ====================================================================
echo "配置系统服务..."

# 创建启动脚本，确保服务正确启动
mkdir -p files/etc/init.d
cat > files/etc/init.d/custom-services << 'EOF'
#!/bin/sh /etc/rc.common
# 自定义服务启动脚本

START=99
STOP=10

start() {
    echo "启动自定义服务..."
    
    # 确保配置目录存在
    mkdir -p /etc/openclash
    mkdir -p /etc/mosdns
    
    # 设置文件权限
    chmod 644 /etc/openclash/config.yaml 2>/dev/null || true
    chmod 644 /etc/mosdns/config.yaml 2>/dev/null || true
    chmod 644 /etc/mosdns/config_custom.yaml 2>/dev/null || true
    
    # 创建符号链接（如果需要）
    ln -sf /etc/config/openclash /etc/config/openclash.bak 2>/dev/null || true
    ln -sf /etc/config/mosdns /etc/config/mosdns.bak 2>/dev/null || true
    
    echo "自定义服务启动完成"
}

stop() {
    echo "停止自定义服务..."
}
EOF
chmod +x files/etc/init.d/custom-services

# 启用服务
ln -sf ../init.d/custom-services files/etc/rc.d/S99custom-services 2>/dev/null || true

# ====================================================================
# 5. 创建使用说明文档
# ====================================================================
mkdir -p files/root
cat > files/root/README-CUSTOM-FIRMWARE.txt << 'EOF'
==========================================
      JDCloud RE-CS-02 定制固件说明
==========================================

固件编译时间: 2026-06-04
固件版本: LEDE R26.05.20 + 定制插件

一、网络配置
------------
1. 管理地址: http://192.168.100.1
2. 用户名: root
3. 密码: 空 (已设置无密码)
4. WiFi SSID: JDC_AX6600_2.4G / JDC_AX6600_5G
5. WiFi密码: 123456

二、预装插件
------------
1. OpenClash: 代理工具
   - 管理界面: http://192.168.100.1/cgi-bin/luci/admin/services/openclash
   - 控制面板: http://192.168.100.1:9090/ui (需先启动)
   - 代理端口: 7890 (HTTP), 7891 (SOCKS)

2. MosDNS: DNS分流工具
   - 管理界面: http://192.168.100.1/cgi-bin/luci/admin/services/mosdns
   - DNS端口: 5335
   - 已配置国内/国外DNS分流

3. PassWall: 备用代理工具
4. Argon主题: 美化界面
5. Docker: 容器运行时

三、配置文件位置
----------------
1. OpenClash: /etc/openclash/config.yaml
2. MosDNS: /etc/mosdns/config.yaml
3. 网络配置: /etc/config/network
4. 无线配置: /etc/config/wireless

四、快速使用
------------
1. 登录管理界面: http://192.168.100.1
2. 进入 OpenClash → 上传你的节点配置
3. 启动 OpenClash 服务
4. 设备设置代理: HTTP 192.168.100.1:7890

五、注意事项
------------
1. OpenClash 默认未启动，需手动开启
2. 首次使用需添加代理节点
3. 建议修改默认密码
4. 配置文件可自行修改

==========================================
EOF

#!/bin/bash
#=============================================
# 第二阶段：可选配置：后台登录默认跳转istoreOS大屏首页
#=============================================
echo '=====================设置默认首页为iStoreOS面板====================='
# 修改luci默认访问路径，打开后台直接进istorehome首页
sed -i 's/\/cgi-bin\/luci/\/cgi-bin\/luci\/admin\/istorehome/g' feeds/luci/modules/luci-base/root/etc/config/luci

echo "✅ DIY Part 2 完成 - 配置已固化到固件"
