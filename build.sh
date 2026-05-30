#!/bin/bash

# 京东云雅典娜固件编译脚本
# 使用方法: ./build.sh [clean|config|download|build|all]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数
LEDE_REPO="https://github.com/coolsnowwolf/lede"
LEDE_BRANCH="master"
CONFIG_FILE="athena.config"
BUILD_DIR="openwrt"
LOG_FILE="build.log"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查环境
check_environment() {
    print_info "检查编译环境..."
    
    # 检查操作系统
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        print_info "操作系统: $NAME $VERSION"
        
        if [[ "$NAME" != "Ubuntu" ]]; then
            print_warning "推荐使用Ubuntu系统进行编译"
        fi
    fi
    
    # 检查内存
    total_mem=$(free -g | awk '/^Mem:/{print $2}')
    if [ $total_mem -lt 8 ]; then
        print_warning "内存不足8GB，建议增加内存或使用交换分区"
    else
        print_info "内存: ${total_mem}GB"
    fi
    
    # 检查磁盘空间
    disk_space=$(df -h . | awk 'NR==2{print $4}')
    print_info "可用磁盘空间: $disk_space"
    
    # 检查CPU核心数
    cpu_cores=$(nproc)
    print_info "CPU核心数: $cpu_cores"
}

# 安装依赖
install_dependencies() {
    print_info "安装编译依赖..."
    
    sudo apt-get update
    sudo apt-get install -y build-essential ccache ecj fastjar file g++ gawk \
        gettext git java-propose-classpath libelf-dev libncurses5-dev \
        libncursesw5-dev libssl-dev python3 python3-distutils python3-setuptools \
        python3-pip rsync subversion swig time xsltproc zlib1g-dev \
        unzip wget curl
    
    print_success "依赖安装完成"
}

# 克隆源码
clone_source() {
    print_info "克隆LEDE源码..."
    
    if [ -d "$BUILD_DIR" ]; then
        print_info "源码目录已存在，更新中..."
        cd $BUILD_DIR
        git pull origin $LEDE_BRANCH
        cd ..
    else
        git clone --depth=1 $LEDE_REPO $BUILD_DIR
        cd $BUILD_DIR
        git checkout $LEDE_BRANCH
        cd ..
    fi
    
    print_success "源码准备完成"
}

# 配置编译
configure_build() {
    print_info "配置编译参数..."
    
    cd $BUILD_DIR
    
    # 应用京东云雅典娜配置
    if [ -f "../$CONFIG_FILE" ]; then
        cp "../$CONFIG_FILE" .config
        print_success "应用配置文件: $CONFIG_FILE"
    else
        print_error "找不到配置文件: $CONFIG_FILE"
        exit 1
    fi
    
    # 设置feeds源
    cat > feeds.conf.default << 'EOF'
src-git packages https://github.com/coolsnowwolf/packages
src-git luci https://github.com/coolsnowwolf/luci
src-git routing https://git.openwrt.org/feed/routing.git
src-git telephony https://git.openwrt.org/feed/telephony.git
EOF
    
    # 更新feeds
    print_info "更新软件源..."
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    
    # 应用配置
    make defconfig
    
    cd ..
    print_success "配置完成"
}

# 下载依赖
download_dependencies() {
    print_info "下载编译依赖..."
    
    cd $BUILD_DIR
    make -j$(nproc) download 2>&1 | tee ../download.log
    cd ..
    
    print_success "依赖下载完成"
}

# 开始编译
start_build() {
    print_info "开始编译固件..."
    
    cd $BUILD_DIR
    
    # 记录开始时间
    start_time=$(date +%s)
    
    # 开始编译
    print_info "编译命令: make -j$(($(nproc) + 1)) V=s"
    make -j$(($(nproc) + 1)) V=s 2>&1 | tee ../$LOG_FILE
    
    # 记录结束时间
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # 检查编译结果
    if [ $? -eq 0 ]; then
        print_success "编译成功！耗时: $((duration / 60))分钟$((duration % 60))秒"
        
        # 显示生成的固件
        if [ -f "bin/targets/ipq60xx/generic/openwrt-ipq60xx-generic-jdcloud_re-cs-02-squashfs-sysupgrade.bin" ]; then
            print_success "生成的固件:"
            ls -la bin/targets/ipq60xx/generic/*.bin | awk '{print $9, $5}'
            
            # 显示固件大小
            firmware_size=$(ls -la bin/targets/ipq60xx/generic/*.bin | awk '{print $5}')
            firmware_size_mb=$((firmware_size / 1024 / 1024))
            print_info "固件大小: ${firmware_size_mb}MB"
        fi
    else
        print_error "编译失败！"
        print_info "请查看日志文件: $LOG_FILE"
        
        # 显示最后100行错误日志
        tail -100 ../$LOG_FILE
        exit 1
    fi
    
    cd ..
}

# 清理编译
clean_build() {
    print_info "清理编译文件..."
    
    if [ -d "$BUILD_DIR" ]; then
        cd $BUILD_DIR
        make clean
        cd ..
        print_success "清理完成"
    else
        print_warning "编译目录不存在"
    fi
}

# 完全清理
dist_clean() {
    print_info "完全清理..."
    
    if [ -d "$BUILD_DIR" ]; then
        cd $BUILD_DIR
        make distclean
        cd ..
        print_success "完全清理完成"
    else
        print_warning "编译目录不存在"
    fi
}

# 显示帮助
show_help() {
    echo "京东云雅典娜固件编译脚本"
    echo ""
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  all        完整编译流程（默认）"
    echo "  check      检查环境"
    echo "  deps       安装依赖"
    echo "  clone      克隆源码"
    echo "  config     配置编译"
    echo "  download   下载依赖"
    echo "  build      开始编译"
    echo "  clean      清理编译文件"
    echo "  distclean  完全清理"
    echo "  help       显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 all     完整编译"
    echo "  $0 build   仅编译"
    echo "  $0 clean   清理"
}

# 主函数
main() {
    case "$1" in
        "check")
            check_environment
            ;;
        "deps")
            install_dependencies
            ;;
        "clone")
            clone_source
            ;;
        "config")
            configure_build
            ;;
        "download")
            download_dependencies
            ;;
        "build")
            start_build
            ;;
        "clean")
            clean_build
            ;;
        "distclean")
            dist_clean
            ;;
        "help")
            show_help
            ;;
        "all"|"")
            check_environment
            install_dependencies
            clone_source
            configure_build
            download_dependencies
            start_build
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$1"
