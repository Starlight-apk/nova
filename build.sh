#!/bin/bash
#===============================================================================
# NovaScript 构建系统
# 支持 Termux、ARM64、Linux、macOS、Windows
#===============================================================================

set -euo pipefail

NOVA_BUILD_DIR="${NOVA_BUILD_DIR:-build}"
NOVA_DIST_DIR="${NOVA_DIST_DIR:-dist}"

#-------------------------------------------------------------------------------
# 检测构建环境
#-------------------------------------------------------------------------------
detect_build_env() {
    local os_type=""
    local arch_type=""
    local is_termux=false
    
    case "$(uname -s)" in
        Linux*)  os_type="linux" ;;
        Darwin*) os_type="macos" ;;
        CYGWIN*|MINGW*|MSYS*) os_type="windows" ;;
        *)       os_type="unknown" ;;
    esac
    
    arch_type=$(uname -m)
    case "$arch_type" in
        aarch64|arm64) arch_type="arm64" ;;
        x86_64|amd64)  arch_type="x64" ;;
        armv7l|armhf)  arch_type="arm" ;;
    esac
    
    # 检测 Termux
    if [[ -n "${TERMUX_VERSION:-}" ]] || [[ -d "/data/data/com.termux" ]] || [[ -n "${PREFIX:-}" ]]; then
        is_termux=true
    fi
    
    export BUILD_OS="$os_type"
    export BUILD_ARCH="$arch_type"
    export BUILD_TERMUX="$is_termux"
    
    echo "Build Environment:"
    echo "  OS:       $os_type"
    echo "  Arch:     $arch_type"
    echo "  Termux:   $is_termux"
}

#-------------------------------------------------------------------------------
# 构建主程序
#-------------------------------------------------------------------------------
build_all() {
    local optimize="${1:-true}"
    
    echo ""
    echo "=== Building NovaScript ==="
    echo ""
    
    detect_build_env
    
    # 创建构建目录
    mkdir -p "$NOVA_BUILD_DIR"
    mkdir -p "$NOVA_DIST_DIR"
    
    # 复制核心文件
    echo "Copying core files..."
    cp -r bin/ "$NOVA_BUILD_DIR/"
    cp -r lib/ "$NOVA_BUILD_DIR/"
    cp -r src/ "$NOVA_BUILD_DIR/"
    cp -r tools/ "$NOVA_BUILD_DIR/"
    
    # 优化（如果启用）
    if [[ "$optimize" == "true" ]]; then
        echo "Optimizing for $BUILD_ARCH..."
        optimize_for_arch
    fi
    
    # 创建启动脚本
    create_launcher
    
    # 创建文档
    cp -r docs/ "$NOVA_DIST_DIR/" 2>/dev/null || true
    cp README.md "$NOVA_DIST_DIR/" 2>/dev/null || true
    cp LICENSE "$NOVA_DIST_DIR/" 2>/dev/null || true
    
    # 打包
    create_package
    
    echo ""
    echo "✓ Build completed: $NOVA_DIST_DIR"
}

#-------------------------------------------------------------------------------
# 架构优化
#-------------------------------------------------------------------------------
optimize_for_arch() {
    case "$BUILD_ARCH" in
        arm64)
            # ARM64 优化
            echo "  Applying ARM64 optimizations..."
            # 减少内存使用
            export NOVA_MAX_MEMORY="256M"
            # 启用 ARM 特定优化
            export NOVA_ARM_OPTIMIZED="true"
            ;;
        arm)
            # ARMv7 优化
            echo "  Applying ARM optimizations..."
            export NOVA_MAX_MEMORY="128M"
            export NOVA_ARM_OPTIMIZED="true"
            ;;
        x64)
            # x64 优化
            echo "  Applying x64 optimizations..."
            export NOVA_MAX_MEMORY="512M"
            ;;
    esac
    
    # Termux 特定优化
    if [[ "$BUILD_TERMUX" == "true" ]]; then
        echo "  Applying Termux optimizations..."
        # 减少并行处理
        export NOVA_PARALLEL="false"
        # 使用轻量级加密
        export NOVA_LIGHTWEIGHT_CRYPTO="true"
    fi
}

#-------------------------------------------------------------------------------
# 创建启动脚本
#-------------------------------------------------------------------------------
create_launcher() {
    local launcher="$NOVA_BUILD_DIR/nova"
    
    # 确保可执行
    chmod +x "$launcher"
    
    # 创建符号链接到 dist
    ln -sf "$launcher" "$NOVA_DIST_DIR/nova" 2>/dev/null || cp "$launcher" "$NOVA_DIST_DIR/"
}

#-------------------------------------------------------------------------------
# 创建安装包
#-------------------------------------------------------------------------------
create_package() {
    local version="1.0.0"
    local package_name="novascript-$BUILD_OS-$BUILD_ARCH"
    
    echo "Creating package: $package_name..."
    
    # 创建 tar.gz
    tar -czf "$NOVA_DIST_DIR/$package_name.tar.gz" \
        -C "$NOVA_BUILD_DIR" .
    
    # 创建 zip（如果可用）
    if command -v zip &>/dev/null; then
        (cd "$NOVA_BUILD_DIR" && zip -r "../$NOVA_DIST_DIR/$package_name.zip" .)
    fi
    
    # 创建 checksum
    (cd "$NOVA_DIST_DIR" && sha256sum *.tar.gz > checksums.txt 2>/dev/null || true)
}

#-------------------------------------------------------------------------------
# 清理构建
#-------------------------------------------------------------------------------
clean_build() {
    echo "Cleaning build artifacts..."
    
    rm -rf "$NOVA_BUILD_DIR"
    rm -rf "$NOVA_DIST_DIR"
    rm -rf __pycache__ .pytest_cache
    find . -name "*.pyc" -delete 2>/dev/null || true
    find . -name "*.nbc" -delete 2>/dev/null || true
    
    echo "Clean completed"
}

#-------------------------------------------------------------------------------
# 安装到系统
#-------------------------------------------------------------------------------
install_system() {
    local prefix="${1:-/usr/local}"
    
    echo "Installing to $prefix..."
    
    mkdir -p "$prefix/bin"
    mkdir -p "$prefix/lib/nova"
    
    cp "$NOVA_BUILD_DIR/bin/nova" "$prefix/bin/"
    cp -r "$NOVA_BUILD_DIR/lib/"* "$prefix/lib/nova/"
    cp -r "$NOVA_BUILD_DIR/src/"* "$prefix/lib/nova/"
    cp -r "$NOVA_BUILD_DIR/tools/"* "$prefix/lib/nova/"
    
    chmod +x "$prefix/bin/nova"
    
    echo "✓ Installed to $prefix"
}

#-------------------------------------------------------------------------------
# 卸载
#-------------------------------------------------------------------------------
uninstall_system() {
    local prefix="${1:-/usr/local}"
    
    echo "Uninstalling from $prefix..."
    
    rm -f "$prefix/bin/nova"
    rm -rf "$prefix/lib/nova"
    
    echo "✓ Uninstalled from $prefix"
}

#-------------------------------------------------------------------------------
# 开发模式
#-------------------------------------------------------------------------------
dev_mode() {
    echo "Setting up development mode..."
    
    # 创建符号链接到全局
    local bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    
    ln -sf "$PWD/bin/nova" "$bin_dir/nova"
    
    echo "✓ Development mode enabled"
    echo "  Run 'nova --version' to verify"
}

#-------------------------------------------------------------------------------
# 运行测试
#-------------------------------------------------------------------------------
run_tests() {
    echo "Running tests..."
    
    source "$NOVA_HOME/tools/test-framework.sh"
    nova_test
}

#-------------------------------------------------------------------------------
# 生成文档
#-------------------------------------------------------------------------------
generate_docs() {
    echo "Generating documentation..."
    
    mkdir -p "$NOVA_DIST_DIR/docs"
    
    # 生成 API 文档
    cat > "$NOVA_DIST_DIR/docs/API.md" << 'EOF'
# NovaScript API Documentation

## Core Functions

### io.print(...)
Print values to stdout.

### io.input(prompt)
Read input from user.

### math.add(a, b)
Add two numbers.

### string.len(str)
Get string length.

## Standard Library

- std/io - Input/Output operations
- std/string - String manipulation
- std/math - Mathematical functions
- std/json - JSON parsing/generation
- std/os - Operating system functions
EOF
    
    echo "✓ Documentation generated"
}

#-------------------------------------------------------------------------------
# 发布
#-------------------------------------------------------------------------------
release() {
    local version="$1"
    
    if [[ -z "$version" ]]; then
        echo "Error: Version required" >&2
        return 1
    fi
    
    echo "Creating release $version..."
    
    # 更新版本号
    sed -i "s/NOVA_VERSION=\"[^\"]*\"/NOVA_VERSION=\"$version\"/" src/core/init.sh
    
    # 构建
    build_all
    
    # 生成 changelog
    cat > "$NOVA_DIST_DIR/CHANGELOG.md" << EOF
# Changelog

## Version $version

Released: $(date +%Y-%m-%d)

### Changes
- Initial release
- Full feature set
- Termux and ARM64 support
- Complete toolchain
EOF
    
    echo "✓ Release $version created"
}

#-------------------------------------------------------------------------------
# 主函数
#-------------------------------------------------------------------------------
main() {
    local cmd="${1:-build}"
    shift || true
    
    case "$cmd" in
        build|b)
            build_all "$@"
            ;;
        clean)
            clean_build
            ;;
        install)
            install_system "$@"
            ;;
        uninstall)
            uninstall_system "$@"
            ;;
        dev)
            dev_mode
            ;;
        test|t)
            run_tests
            ;;
        docs)
            generate_docs
            ;;
        release)
            release "$@"
            ;;
        *)
            echo "Usage: build.sh {build|clean|install|uninstall|dev|test|docs|release}"
            exit 1
            ;;
    esac
}

# 如果在项目目录外运行，切换到项目目录
if [[ -n "${NOVA_HOME:-}" ]] && [[ "$PWD" != "$NOVA_HOME" ]]; then
    cd "$NOVA_HOME"
fi

main "$@"
