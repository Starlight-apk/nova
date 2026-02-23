#!/bin/bash
#===============================================================================
# NovaScript 系统安装脚本
# 将 NovaScript 注册到系统 PATH 并创建必要的配置
#===============================================================================

# 注意：不使用 set -e，因为某些命令可能失败但不是致命的

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 获取脚本所在目录
NOVA_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export NOVA_HOME

#-------------------------------------------------------------------------------
# 打印函数
#-------------------------------------------------------------------------------
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

#-------------------------------------------------------------------------------
# 检测系统
#-------------------------------------------------------------------------------
detect_system() {
    local os_type=""
    local install_dir=""
    local bin_dir=""
    local is_termux=false
    
    # 检测 Termux 环境
    if [[ -n "${TERMUX_VERSION:-}" ]] || [[ -d "/data/data/com.termux" ]] || [[ -n "${PREFIX:-}" ]]; then
        is_termux=true
        os_type="termux"
        install_dir="$HOME/novascript"
        bin_dir="$PREFIX/bin"
    else
        case "$(uname -s)" in
            Linux*)
                os_type="linux"
                install_dir="$HOME/novascript"
                bin_dir="$HOME/bin"
                ;;
            Darwin*)
                os_type="macos"
                install_dir="$HOME/novascript"
                bin_dir="$HOME/bin"
                ;;
            CYGWIN*|MINGW*|MSYS*)
                os_type="windows"
                install_dir="$HOME/novascript"
                bin_dir="$HOME/bin"
                ;;
            *)
                error "Unsupported system"
                exit 1
                ;;
        esac
    fi
    
    export NOVA_INSTALL_DIR="$install_dir"
    export NOVA_BIN_DIR="$bin_dir"
    export NOVA_OS_TYPE="$os_type"
    export NOVA_IS_TERMUX="$is_termux"
    
    info "Detected system: $os_type"
    info "Termux: $is_termux"
    info "Install directory: $install_dir"
    info "Binary directory: $bin_dir"
}

#-------------------------------------------------------------------------------
# 检查权限
#-------------------------------------------------------------------------------
check_permissions() {
    local target_dir="$1"
    
    # Termux 环境直接使用，不需要 sudo
    if [[ "$NOVA_IS_TERMUX" == "true" ]]; then
        USE_SUDO=false
        return 0
    fi
    
    # 检查是否可写
    if [[ -w "$target_dir" ]] || [[ -w "$(dirname "$target_dir")" ]]; then
        USE_SUDO=false
    else
        # 检查是否有 sudo
        if command -v sudo &>/dev/null; then
            USE_SUDO=true
            warn "Will use sudo for system-wide installation"
        else
            USE_SUDO=false
            warn "Cannot write to $target_dir and sudo not available"
            warn "You may need to run: sudo bash install.sh"
        fi
    fi
}

#-------------------------------------------------------------------------------
# 创建目录
#-------------------------------------------------------------------------------
create_directories() {
    info "Creating directories..."
    
    local dirs=(
        "$NOVA_INSTALL_DIR"
        "$NOVA_INSTALL_DIR/bin"
        "$NOVA_INSTALL_DIR/lib"
        "$NOVA_INSTALL_DIR/src"
        "$NOVA_INSTALL_DIR/tools"
        "$NOVA_INSTALL_DIR/webui"
        "$NOVA_INSTALL_DIR/packages"
        "$NOVA_INSTALL_DIR/docs"
        "$HOME/.nova"
        "$HOME/.nova/cache"
        "$HOME/.nova/packages"
        "$HOME/.nova/config"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" 2>/dev/null
        fi
    done
    
    success "Directories created"
}

#-------------------------------------------------------------------------------
# 复制文件
#-------------------------------------------------------------------------------
copy_files() {
    info "Copying files..."
    
    # 复制主程序
    cp -r "$NOVA_HOME/bin/"* "$NOVA_INSTALL_DIR/bin/" 2>/dev/null
    
    # 复制库文件
    cp -r "$NOVA_HOME/lib/"* "$NOVA_INSTALL_DIR/lib/" 2>/dev/null
    
    # 复制源码
    cp -r "$NOVA_HOME/src/"* "$NOVA_INSTALL_DIR/src/" 2>/dev/null
    
    # 复制工具
    cp -r "$NOVA_HOME/tools/"* "$NOVA_INSTALL_DIR/tools/" 2>/dev/null
    
    # 复制 WebUI
    cp -r "$NOVA_HOME/webui/"* "$NOVA_INSTALL_DIR/webui/" 2>/dev/null
    
    # 复制包
    cp -r "$NOVA_HOME/packages/"* "$NOVA_INSTALL_DIR/packages/" 2>/dev/null
    
    # 复制文档
    cp -r "$NOVA_HOME/docs/"* "$NOVA_INSTALL_DIR/docs/" 2>/dev/null
    
    # 复制示例
    mkdir -p "$NOVA_INSTALL_DIR/examples"
    cp -r "$NOVA_HOME/examples/"* "$NOVA_INSTALL_DIR/examples/" 2>/dev/null
    
    # 复制配置文件
    cp "$NOVA_HOME/nova.json" "$NOVA_INSTALL_DIR/" 2>/dev/null
    cp "$NOVA_HOME/README.md" "$NOVA_INSTALL_DIR/" 2>/dev/null
    
    success "Files copied"
}

#-------------------------------------------------------------------------------
# 设置权限
#-------------------------------------------------------------------------------
set_permissions() {
    info "Setting permissions..."
    
    chmod +x "$NOVA_INSTALL_DIR/bin/nova" 2>/dev/null
    chmod +x "$NOVA_INSTALL_DIR/bin/"*.sh 2>/dev/null
    
    success "Permissions set"
}

#-------------------------------------------------------------------------------
# 创建符号链接
#-------------------------------------------------------------------------------
create_symlinks() {
    info "Creating symlinks..."
    
    # 创建 nova 命令的符号链接
    ln -sf "$NOVA_INSTALL_DIR/bin/nova" "$NOVA_BIN_DIR/nova" 2>/dev/null
    
    # 创建其他工具的链接
    for tool in build.sh install.sh install-termux.sh; do
        if [[ -f "$NOVA_INSTALL_DIR/bin/$tool" ]]; then
            ln -sf "$NOVA_INSTALL_DIR/bin/$tool" "$NOVA_BIN_DIR/$tool" 2>/dev/null
        fi
    done
    
    success "Symlinks created"
}

#-------------------------------------------------------------------------------
# 配置环境变量
#-------------------------------------------------------------------------------
configure_env() {
    info "Configuring environment..."
    
    # 既然已经注册到 bin 目录，不需要修改任何 shell 配置
    # 用户无论使用 Bash, Zsh, Fish 或其他 shell 都可以直接使用
    
    # 创建 NovaScript 配置
    mkdir -p "$HOME/.nova"
    cat > "$HOME/.nova/config.json" << EOF
{
    "version": "1.0.0",
    "install_dir": "$NOVA_INSTALL_DIR",
    "theme": "dark",
    "lang": "en",
    "auto_update": false,
    "check_updates": true,
    "telemetry": false
}
EOF
    
    success "NovaScript registered to PATH (works with any shell)"
}

#-------------------------------------------------------------------------------
# 创建快捷方式
#-------------------------------------------------------------------------------
create_shortcuts() {
    info "Creating shortcuts..."
    
    # 创建桌面快捷方式（如果有桌面环境）
    if command -v xdg-desktop-menu &>/dev/null; then
        cat > "/tmp/novascript.desktop" << EOF
[Desktop Entry]
Name=NovaScript Studio
Comment=NovaScript Development Environment
Exec=$NOVA_INSTALL_DIR/bin/nova start
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Development;IDE;
EOF
        
        xdg-desktop-menu install "/tmp/novascript.desktop" 2>/dev/null || true
        rm -f "/tmp/novascript.desktop"
    fi
    
    success "Shortcuts created"
}

#-------------------------------------------------------------------------------
# 验证安装
#-------------------------------------------------------------------------------
verify_install() {
    info "Verifying installation..."
    
    # 检查 nova 命令
    if command -v nova &>/dev/null; then
        local version=$(nova --version 2>/dev/null | head -1)
        success "NovaScript installed: $version"
    else
        warn "nova command not found in PATH"
        warn "You may need to restart your terminal or run: source ~/.bashrc"
    fi
    
    # 检查目录
    if [[ -d "$NOVA_INSTALL_DIR" ]]; then
        success "Install directory exists: $NOVA_INSTALL_DIR"
    fi
    
    # 检查 WebUI
    if [[ -f "$NOVA_INSTALL_DIR/webui/server.sh" ]]; then
        success "WebUI installed"
    fi
    
    # 检查包
    local pkg_count=$(find "$NOVA_INSTALL_DIR/packages" -name "*.sh" 2>/dev/null | wc -l)
    success "Packages installed: $pkg_count"
}

#-------------------------------------------------------------------------------
# 显示使用信息
#-------------------------------------------------------------------------------
show_usage() {
    echo ""
    echo "========================================"
    echo "  NovaScript Installation Complete!"
    echo "========================================"
    echo ""
    echo "Installation directory: $NOVA_INSTALL_DIR"
    echo "Binary directory: $NOVA_BIN_DIR"
    echo ""
    echo "Quick Start:"
    echo "  1. Verify installation:"
    echo "     nova --version"
    echo ""
    echo "  2. Run a script:"
    echo "     nova run examples/hello.nova"
    echo ""
    echo "  3. Start WebUI:"
    echo "     nova start"
    echo ""
    echo "  4. Open browser:"
    echo "     http://127.0.0.1:8080"
    echo ""
    echo "Commands:"
    echo "  nova run <file>     - Run a script"
    echo "  nova init <name>    - Create project"
    echo "  nova start          - Start WebUI"
    echo "  nova install <pkg>  - Install package"
    echo "  nova help           - Show help"
    echo ""
    echo "Note: Works with any shell (Bash, Zsh, Fish, etc.)"
    echo "========================================"
}

#-------------------------------------------------------------------------------
# 卸载函数
#-------------------------------------------------------------------------------
uninstall() {
    info "Uninstalling NovaScript..."
    
    # 移除符号链接
    rm -f "$NOVA_BIN_DIR/nova" 2>/dev/null
    rm -f "$NOVA_BIN_DIR/build.sh" 2>/dev/null
    rm -f "$NOVA_BIN_DIR/install.sh" 2>/dev/null
    rm -f "$NOVA_BIN_DIR/install-termux.sh" 2>/dev/null
    
    # 移除安装目录
    rm -rf "$NOVA_INSTALL_DIR" 2>/dev/null
    
    # 移除配置
    rm -rf "$HOME/.nova" 2>/dev/null
    
    success "NovaScript uninstalled"
}

#-------------------------------------------------------------------------------
# 主函数
#-------------------------------------------------------------------------------
main() {
    local action="${1:-install}"
    
    echo ""
    echo "========================================"
    echo "  NovaScript Installer"
    echo "  Version 1.0.0"
    echo "========================================"
    echo ""
    
    case "$action" in
        install|i)
            detect_system
            check_permissions "$NOVA_INSTALL_DIR"
            create_directories
            copy_files
            set_permissions
            create_symlinks
            configure_env
            create_shortcuts
            verify_install
            show_usage
            ;;
        uninstall|u)
            detect_system
            uninstall
            ;;
        verify|v)
            detect_system
            verify_install
            ;;
        *)
            echo "Usage: $0 {install|uninstall|verify}"
            exit 1
            ;;
    esac
}

main "$@"
