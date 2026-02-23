#!/bin/bash
#===============================================================================
# NovaScript Module API
# 模块和依赖管理系统
#===============================================================================

# 简单的日志函数
_log_info() { echo -e "\033[0;36m[INFO]\033[0m $1"; }
_log_warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
_log_error() { echo -e "\033[1;31m[ERROR]\033[0m $1" >&2; }
_log_success() { echo -e "\033[1;32m[OK]\033[0m $1"; }
_log_debug() { [[ "${NOVA_DEBUG:-}" == "true" ]] && echo -e "\033[0;35m[DEBUG]\033[0m $1"; }

#-------------------------------------------------------------------------------
# 模块注册表
#-------------------------------------------------------------------------------
declare -gA NOVA_MODULES=()
declare -gA NOVA_MODULE_VERSIONS=()
declare -gA NOVA_MODULE_DEPS=()

#-------------------------------------------------------------------------------
# 模块 API
#-------------------------------------------------------------------------------

# 注册模块
api_module_register() {
    local name="$1"
    local version="${2:-1.0.0}"
    local path="${3:-}"
    
    NOVA_MODULES["$name"]="$path"
    NOVA_MODULE_VERSIONS["$name"]="$version"
    
    _log_info "Module registered: $name v$version"
}

# 加载模块
api_module_load() {
    local name="$1"
    local version="${2:-}"
    
    # 检查是否已加载
    if [[ -v NOVA_MODULES["$name"] ]]; then
        _log_debug "Module already loaded: $name"
        return 0
    fi
    
    # 查找模块
    local module_path=""
    local search_paths=(
        "$NOVA_HOME/lib/modules/$name"
        "$NOVA_HOME/packages/$name"
        "$HOME/.nova/packages/$name"
        "./packages/$name"
        "./$name"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path/$name.sh" ]]; then
            module_path="$path/$name.sh"
            break
        elif [[ -f "$path/main.sh" ]]; then
            module_path="$path/main.sh"
            break
        elif [[ -f "$path" ]]; then
            module_path="$path"
            break
        fi
    done
    
    if [[ -z "$module_path" ]]; then
        _log_error "Module not found: $name"
        return 1
    fi
    
    # 加载模块
    source "$module_path"
    NOVA_MODULES["$name"]="$module_path"
    
    _log_info "Module loaded: $name"
    return 0
}

# 卸载模块
api_module_unload() {
    local name="$1"
    
    if [[ -v NOVA_MODULES["$name"] ]]; then
        unset "NOVA_MODULES[$name]"
        unset "NOVA_MODULE_VERSIONS[$name]"
        _log_info "Module unloaded: $name"
    fi
}

# 列出已加载模块
api_module_list() {
    echo "Loaded modules:"
    for name in "${!NOVA_MODULES[@]}"; do
        local version="${NOVA_MODULE_VERSIONS[$name]:-unknown}"
        local path="${NOVA_MODULES[$name]}"
        echo "  $name v$version - $path"
    done
}

# 检查模块是否存在
api_module_exists() {
    local name="$1"
    [[ -v NOVA_MODULES["$name"] ]]
}

# 获取模块版本
api_module_version() {
    local name="$1"
    echo "${NOVA_MODULE_VERSIONS[$name]:-unknown}"
}

#-------------------------------------------------------------------------------
# 依赖管理 API
#-------------------------------------------------------------------------------

# 解析依赖
api_dependency_parse() {
    local manifest="$1"
    
    if [[ ! -f "$manifest" ]]; then
        _log_error "Manifest not found: $manifest"
        return 1
    fi
    
    # 简单的 JSON 解析
    local deps=$(grep -A 20 '"dependencies"' "$manifest" | grep -E '^\s*"[^"]+":' | sed 's/[",]//g' | awk -F: '{print $1":"$2}')
    
    echo "$deps"
}

# 检查依赖
api_dependency_check() {
    local manifest="${1:-nova.json}"
    
    if [[ ! -f "$manifest" ]]; then
        _log_warn "No manifest found, skipping dependency check"
        return 0
    fi
    
    local missing=()
    
    while IFS=: read -r name version; do
        name=$(echo "$name" | tr -d ' ')
        version=$(echo "$version" | tr -d ' ')
        
        if ! api_module_exists "$name"; then
            missing+=("$name@$version")
        fi
    done < <(api_dependency_parse "$manifest")
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        _log_warn "Missing dependencies:"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Run 'nova install' to install missing dependencies"
        return 1
    fi
    
    return 0
}

# 安装依赖
api_dependency_install() {
    local manifest="${1:-nova.json}"
    
    if [[ ! -f "$manifest" ]]; then
        _log_error "Manifest not found: $manifest"
        return 1
    fi
    
    _log_info "Installing dependencies from $manifest..."
    
    while IFS=: read -r name version; do
        name=$(echo "$name" | tr -d ' ')
        version=$(echo "$version" | tr -d ' ')
        
        _log_info "Installing: $name@$version"
        api_package_install "$name" "$version"
    done < <(api_dependency_parse "$manifest")
    
    _log_success "Dependencies installed"
}

#-------------------------------------------------------------------------------
# 包管理 API
#-------------------------------------------------------------------------------

# 安装包
api_package_install() {
    local name="$1"
    local version="${2:-latest}"
    
    _log_info "Installing package: $name@$version"
    
    # 检查包是否存在
    local pkg_dir="$HOME/.nova/packages/$name"
    
    if [[ -d "$pkg_dir" ]]; then
        _log_warn "Package already installed: $name"
        return 0
    fi
    
    # 创建目录
    mkdir -p "$pkg_dir"
    
    # 尝试从多个源下载
    local registries=(
        "https://github.com/novascript/packages/raw/main/$name"
        "https://cdn.novascript.dev/packages/$name"
        "$NOVA_HOME/packages/$name"
    )
    
    local installed=false
    
    for registry in "${registries[@]}"; do
        if [[ -d "$registry" ]]; then
            cp -r "$registry"/* "$pkg_dir/" 2>/dev/null && {
                installed=true
                break
            }
        fi
    done
    
    if [[ "$installed" == "false" ]]; then
        # 创建占位符
        cat > "$pkg_dir/package.json" << EOF
{
    "name": "$name",
    "version": "$version",
    "description": "Package placeholder",
    "main": "index.sh"
}
EOF
        _log_warn "Package not found in registry, created placeholder"
    fi
    
    _log_success "Package installed: $name"
}

# 卸载包
api_package_remove() {
    local name="$1"
    local pkg_dir="$HOME/.nova/packages/$name"
    
    if [[ -d "$pkg_dir" ]]; then
        rm -rf "$pkg_dir"
        _log_success "Package removed: $name"
    else
        _log_error "Package not found: $name"
        return 1
    fi
}

# 列出已安装包
api_package_list() {
    local pkg_dir="$HOME/.nova/packages"
    
    if [[ ! -d "$pkg_dir" ]]; then
        echo "No packages installed"
        return 0
    fi
    
    echo "Installed packages:"
    for dir in "$pkg_dir"/*; do
        if [[ -d "$dir" ]]; then
            local name=$(basename "$dir")
            local version="unknown"
            if [[ -f "$dir/package.json" ]]; then
                version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$dir/package.json" | cut -d'"' -f4)
            fi
            echo "  $name v$version"
        fi
    done
}

# 搜索包
api_package_search() {
    local query="$1"
    
    _log_info "Searching for: $query"
    
    # 本地搜索
    if [[ -d "$NOVA_HOME/packages" ]]; then
        echo ""
        echo "Local packages:"
        for dir in "$NOVA_HOME/packages"/*; do
            if [[ -d "$dir" ]] && [[ "$(basename "$dir")" == *"$query"* ]]; then
                echo "  $(basename "$dir")"
            fi
        done
    fi
    
    # 远程搜索（如果有网络）
    if command -v curl &>/dev/null; then
        echo ""
        echo "Remote packages:"
        curl -s "https://api.novascript.dev/packages/search?q=$query" 2>/dev/null | \
            python3 -c "import sys,json; [print(f'  {p.get(\"name\", \"unknown\")}') for p in json.load(sys.stdin).get('packages', [])]" 2>/dev/null || \
            echo "  (offline or search unavailable)"
    fi
}

# 更新包
api_package_update() {
    local name="${1:-all}"
    
    if [[ "$name" == "all" ]]; then
        _log_info "Updating all packages..."
        for dir in "$HOME/.nova/packages"/*; do
            if [[ -d "$dir" ]]; then
                local pkg_name=$(basename "$dir")
                api_package_install "$pkg_name" "latest"
            fi
        done
    else
        api_package_install "$name" "latest"
    fi
    
    _log_success "Packages updated"
}

#-------------------------------------------------------------------------------
# 项目 API
#-------------------------------------------------------------------------------

# 创建项目
api_project_create() {
    local name="$1"
    local template="${2:-default}"
    
    _log_info "Creating project: $name"
    
    mkdir -p "$name"/{src,lib,test,packages,docs}
    
    cat > "$name/nova.json" << EOF
{
    "name": "$name",
    "version": "1.0.0",
    "description": "A NovaScript project",
    "main": "src/main.nova",
    "type": "application",
    "dependencies": {},
    "devDependencies": {},
    "scripts": {
        "start": "nova run src/main.nova",
        "test": "nova test",
        "build": "nova build"
    },
    "author": "",
    "license": "MIT"
}
EOF
    
    cat > "$name/src/main.nova" << 'EOF'
#!/bin/bash
#===============================================================================
# Main Application
#===============================================================================

import std.io

func main() {
    io.print("Hello from NovaScript!")
}

main
EOF
    
    _log_success "Project created: $name"
    echo ""
    echo "Next steps:"
    echo "  cd $name"
    echo "  nova run src/main.nova"
}

# 构建项目
api_project_build() {
    local output="${1:-dist}"
    
    _log_info "Building project..."
    
    mkdir -p "$output"
    
    # 复制源文件
    if [[ -d "src" ]]; then
        cp -r src/* "$output/" 2>/dev/null
    fi
    
    # 复制依赖
    if [[ -d "packages" ]]; then
        cp -r packages/* "$output/packages/" 2>/dev/null
    fi
    
    _log_success "Build completed: $output"
}

#-------------------------------------------------------------------------------
# 导出函数
#-------------------------------------------------------------------------------
export -f api_module_register api_module_load api_module_unload api_module_list
export -f api_module_exists api_module_version
export -f api_dependency_parse api_dependency_check api_dependency_install
export -f api_package_install api_package_remove api_package_list api_package_search
export -f api_package_update
export -f api_project_create api_project_build
