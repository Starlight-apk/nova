#!/bin/bash
#===============================================================================
# NovaScript 核心初始化模块
#===============================================================================

# NovaScript 版本
export NOVA_VERSION="1.0.0"
export NOVA_API_VERSION="1"

# 检测运行环境
detect_environment() {
    local os_type=""
    local arch_type=""
    local is_termux=false
    local is_arm64=false
    
    # 检测操作系统
    case "$(uname -s)" in
        Linux*)
            os_type="linux"
            ;;
        Darwin*)
            os_type="macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            os_type="windows"
            ;;
        *)
            os_type="unknown"
            ;;
    esac
    
    # 检测架构
    arch_type=$(uname -m)
    case "$arch_type" in
        aarch64|arm64)
            is_arm64=true
            arch_type="arm64"
            ;;
        x86_64|amd64)
            arch_type="x64"
            ;;
        armv7l|armhf)
            arch_type="arm"
            ;;
        *)
            arch_type="unknown"
            ;;
    esac
    
    # 检测 Termux
    if [[ -n "${TERMUX_VERSION:-}" ]] || [[ -d "/data/data/com.termux" ]] || [[ -n "${PREFIX:-}" ]]; then
        is_termux=true
    fi
    
    # 导出环境变量
    export NOVA_OS="$os_type"
    export NOVA_ARCH="$arch_type"
    export NOVA_IS_TERMUX="$is_termux"
    export NOVA_IS_ARM64="$is_arm64"
}

# 初始化路径
init_paths() {
    # 标准库路径
    export NOVA_LIB_PATH="$NOVA_HOME/lib"
    export NOVA_SRC_PATH="$NOVA_HOME/src"
    
    # 缓存目录
    export NOVA_CACHE_DIR="${NOVA_CACHE_DIR:-$HOME/.nova/cache}"
    mkdir -p "$NOVA_CACHE_DIR"
    
    # 包目录
    export NOVA_PACKAGES_DIR="${NOVA_PACKAGES_DIR:-$HOME/.nova/packages}"
    mkdir -p "$NOVA_PACKAGES_DIR"
    
    # 配置目录
    export NOVA_CONFIG_DIR="${NOVA_CONFIG_DIR:-$HOME/.nova}"
    mkdir -p "$NOVA_CONFIG_DIR"
}

# 性能优化设置
optimize_performance() {
    # 根据环境优化
    if [[ "$NOVA_IS_ARM64" == "true" ]]; then
        # ARM64 优化
        export NOVA_OPTIMIZE_ARM64="true"
    fi
    
    if [[ "$NOVA_IS_TERMUX" == "true" ]]; then
        # Termux 优化（减少内存使用）
        export NOVA_OPTIMIZE_TERMUX="true"
        export NOVA_MAX_MEMORY="${NOVA_MAX_MEMORY:-256M}"
    else
        # 桌面环境优化
        export NOVA_MAX_MEMORY="${NOVA_MAX_MEMORY:-512M}"
    fi
}

# 信号处理
setup_signal_handlers() {
    trap 'nova_cleanup' EXIT
    trap 'nova_interrupt' INT
    trap 'nova_terminate' TERM
}

nova_cleanup() {
    # 清理临时文件
    rm -f /tmp/nova_*.tmp 2>/dev/null || true
}

nova_interrupt() {
    echo ""
    echo "Interrupted."
    exit 130
}

nova_terminate() {
    echo ""
    echo "Terminated."
    exit 143
}

# 主初始化函数
nova_init() {
    detect_environment
    init_paths
    optimize_performance
    setup_signal_handlers
}

# 执行初始化
nova_init
