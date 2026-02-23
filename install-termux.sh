#!/bin/bash
#===============================================================================
# NovaScript Termux 安装脚本
# 专为 Termux/ARM64 设备优化
#===============================================================================

set -euo pipefail

# Termux 特定路径
TERMUX_PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# 打印函数
#-------------------------------------------------------------------------------
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

#-------------------------------------------------------------------------------
# 检查是否在 Termux 中运行
#-------------------------------------------------------------------------------
check_termux() {
    if [[ -z "${TERMUX_VERSION:-}" ]] && [[ ! -d "/data/data/com.termux" ]]; then
        warn "Not running in Termux, some features may not work"
        return 1
    fi
    return 0
}

#-------------------------------------------------------------------------------
# 检查依赖
#-------------------------------------------------------------------------------
check_dependencies() {
    info "Checking dependencies..."
    
    local missing=()
    
    # 必需依赖
    for cmd in bash curl tar gzip; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    # 可选依赖
    local optional=()
    for cmd in git wget zip unzip bc md5sum; do
        if ! command -v "$cmd" &>/dev/null; then
            optional+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing[*]}"
        info "Install with: pkg install ${missing[*]}"
        return 1
    fi
    
    if [[ ${#optional[@]} -gt 0 ]]; then
        warn "Optional dependencies not found: ${optional[*]}"
        info "Install with: pkg install ${optional[*]}"
    fi
    
    success "Dependencies check passed"
}

#-------------------------------------------------------------------------------
# 安装依赖
#-------------------------------------------------------------------------------
install_dependencies() {
    info "Installing dependencies..."
    
    pkg update -y
    pkg install -y \
        bash \
        curl \
        tar \
        gzip \
        git \
        wget \
        bc \
        openssl \
        termux-api
    
    success "Dependencies installed"
}

#-------------------------------------------------------------------------------
# 安装 NovaScript
#-------------------------------------------------------------------------------
install_nova() {
    local install_dir="${1:-$HOME/novascript}"
    
    info "Installing NovaScript to $install_dir..."
    
    # 创建安装目录
    mkdir -p "$install_dir"
    
    # 复制文件
    cp -r bin/ "$install_dir/"
    cp -r lib/ "$install_dir/"
    cp -r src/ "$install_dir/"
    cp -r tools/ "$install_dir/"
    cp build.sh "$install_dir/"
    
    # 设置权限
    chmod +x "$install_dir/bin/nova"
    chmod +x "$install_dir/build.sh"
    
    # 创建符号链接
    ln -sf "$install_dir/bin/nova" "$TERMUX_PREFIX/bin/nova"
    
    # 设置环境变量
    export NOVA_HOME="$install_dir"
    echo "export NOVA_HOME=\"$install_dir\"" >> "$HOME/.bashrc"
    echo "export PATH=\"\$NOVA_HOME/bin:\$PATH\"" >> "$HOME/.bashrc"
    
    success "NovaScript installed"
}

#-------------------------------------------------------------------------------
# 配置 Termux 优化
#-------------------------------------------------------------------------------
configure_termux() {
    info "Configuring Termux optimizations..."
    
    # 创建配置文件
    cat > "$HOME/.nova/config.json" << 'EOF'
{
    "optimize_termux": true,
    "optimize_arm64": true,
    "max_memory": "256M",
    "lightweight_crypto": true,
    "parallel": false,
    "lang": "en"
}
EOF
    
    # 调整 bash 配置
    cat >> "$HOME/.bashrc" << 'EOF'

# NovaScript aliases
alias nova='nova'
alias nr='nova run'
alias nc='nova compile'
alias ni='nova install'
alias nt='nova test'
alias nb='nova build'

EOF
    
    success "Termux configured"
}

#-------------------------------------------------------------------------------
# 验证安装
#-------------------------------------------------------------------------------
verify_install() {
    info "Verifying installation..."
    
    if command -v nova &>/dev/null; then
        nova --version
        success "Installation verified"
    else
        error "NovaScript not found in PATH"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# 运行示例
#-------------------------------------------------------------------------------
run_examples() {
    info "Running examples..."
    
    # Hello World
    cat > /tmp/hello.nova << 'EOF'
import std.io
import std.string

func main() {
    io.print("Hello from NovaScript on Termux!")
    io.print("Architecture: " + os.arch())
    io.print("Version: 1.0.0")
}
EOF
    
    if nova run /tmp/hello.nova; then
        success "Example executed"
    else
        warn "Example failed to run"
    fi
    
    rm -f /tmp/hello.nova
}

#-------------------------------------------------------------------------------
# 卸载
#-------------------------------------------------------------------------------
uninstall() {
    local install_dir="${1:-$HOME/novascript}"
    
    info "Uninstalling NovaScript..."
    
    # 移除符号链接
    rm -f "$TERMUX_PREFIX/bin/nova"
    
    # 移除安装目录
    rm -rf "$install_dir"
    
    # 清理环境变量
    sed -i '/NOVA_HOME/d' "$HOME/.bashrc"
    sed -i '/novascript/d' "$HOME/.bashrc"
    
    success "NovaScript uninstalled"
}

#-------------------------------------------------------------------------------
# 更新
#-------------------------------------------------------------------------------
update() {
    info "Updating NovaScript..."
    
    if [[ -d "$HOME/novascript/.git" ]]; then
        (cd "$HOME/novascript" && git pull)
        success "Updated from git"
    else
        warn "Not a git installation, manual update required"
    fi
}

#-------------------------------------------------------------------------------
# 主函数
#-------------------------------------------------------------------------------
main() {
    echo ""
    echo "========================================"
    echo "  NovaScript Termux Installer"
    echo "  Version 1.0.0"
    echo "========================================"
    echo ""
    
    local cmd="${1:-install}"
    
    case "$cmd" in
        install|i)
            check_termux || true
            check_dependencies || install_dependencies
            install_nova
            configure_termux
            verify_install
            run_examples
            ;;
        uninstall|u)
            uninstall "$2"
            ;;
        update|up)
            update
            ;;
        verify|v)
            verify_install
            ;;
        deps|d)
            install_dependencies
            ;;
        *)
            echo "Usage: install-termux.sh {install|uninstall|update|verify|deps}"
            echo ""
            echo "Commands:"
            echo "  install, i    Install NovaScript"
            echo "  uninstall, u  Remove NovaScript"
            echo "  update, up    Update NovaScript"
            echo "  verify, v     Verify installation"
            echo "  deps, d       Install dependencies"
            exit 1
            ;;
    esac
}

main "$@"
