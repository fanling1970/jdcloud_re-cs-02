#!/bin/bash
# diy-part1.sh - LEDE源码预处理
# 在编译开始前执行

set -e

echo "开始执行 diy-part1.sh..."

# 进入LEDE源码目录
cd lede-src

# 添加第三方软件源
echo "添加第三方软件源..."

# 1. kenzo的软件源（包含常用插件）
if ! grep -q "kenzok8" feeds.conf.default; then
    echo "src-git kenzo https://github.com/kenzok8/openwrt-packages" >> feeds.conf.default
fi

# 2. small的软件源（包含passwall等）
if ! grep -q "small" feeds.conf.default; then
    echo "src-git small https://github.com/kenzok8/small" >> feeds.conf.default
fi

echo "feeds.conf.default 内容:"
cat feeds.conf.default

echo "diy-part1.sh 执行完成"
