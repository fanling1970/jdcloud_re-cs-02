# 京东云雅典娜 OpenWrt 固件编译

基于 [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) 源码的京东云雅典娜（RE-CS-02）固件编译项目。

## 特性

- 专为京东云雅典娜 AX6600（RE-CS-02）优化
- 基于最新的 LEDE 源码
- 支持 GitHub Actions 云端编译
- 包含常用软件包和驱动
- 简化的编译流程

## 快速开始

### GitHub Actions 编译

1. Fork 本仓库
2. 进入 Actions 页面，启用 workflows
3. 点击 "Build Athena OpenWrt Firmware" workflow
4. 点击 "Run workflow" 开始编译
5. 编译完成后在 Artifacts 中下载固件

### 本地编译

```bash
# 克隆仓库
git clone https://github.com/your-username/athena-openwrt-simple.git
cd athena-openwrt-simple

# 给予执行权限
chmod +x build.sh

# 完整编译
./build.sh all

# 或分步编译
./build.sh check      # 检查环境
./build.sh deps       # 安装依赖
./build.sh clone      # 克隆源码
./build.sh config     # 配置编译
./build.sh download   # 下载依赖
./build.sh build      # 开始编译
