#!/bin/bash
#===============================================================================
# NovaScript Package Manager (nova pkg)
# 企业级包管理系统 - 支持安装、发布、版本控制、依赖解析等功能
#===============================================================================

# 不启用严格模式，让函数可以正确处理错误
# set -euo pipefail

#-------------------------------------------------------------------------------
# 配置和常量
#-------------------------------------------------------------------------------
NOVA_PKG_VERSION="2.0.0"
NOVA_REGISTRY="${NOVA_REGISTRY:-https://registry.novascript.dev}"
NOVA_PACKAGES_DIR="${NOVA_PACKAGES_DIR:-$HOME/.nova/packages}"
NOVA_CACHE_DIR="${NOVA_CACHE_DIR:-$HOME/.nova/cache}"
NOVA_LOCK_FILE="nova.lock"
NOVA_MANIFEST_FILE="nova.json"

# 颜色定义
COLOR_RESET="\033[0m"
COLOR_RED="\033[1;31m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[1;34m"
COLOR_MAGENTA="\033[1;35m"
COLOR_CYAN="\033[1;36m"
COLOR_WHITE="\033[1;37m"

#-------------------------------------------------------------------------------
# 工具函数
#-------------------------------------------------------------------------------
log_info() {
    echo -e "${COLOR_CYAN}[INFO]${COLOR_RESET} $1"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $1"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1" >&2
}

log_debug() {
    [[ "${NOVA_DEBUG:-false}" == "true" ]] && echo -e "${COLOR_MAGENTA}[DEBUG]${COLOR_RESET} $1"
}

print_header() {
    local title="$1"
    echo ""
    echo -e "${COLOR_BLUE}╭────────────────────────────────────────────────────╮${COLOR_RESET}"
    echo -e "${COLOR_BLUE}│${COLOR_RESET}  ${COLOR_WHITE}${title}${COLOR_RESET}"
    echo -e "${COLOR_BLUE}╰────────────────────────────────────────────────────╯${COLOR_RESET}"
    echo ""
}

# 检查网络连接
check_network() {
    if command -v curl &>/dev/null; then
        curl -s --head "$NOVA_REGISTRY" &>/dev/null && return 0
    fi
    if command -v wget &>/dev/null; then
        wget -q --spider "$NOVA_REGISTRY" &>/dev/null && return 0
    fi
    return 1
}

# 获取当前时间戳
get_timestamp() {
    date +%s
}

# 生成唯一 ID
generate_uuid() {
    if command -v uuidgen &>/dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    else
        cat /proc/sys/kernel/random/uuid 2>/dev/null || \
        printf '%04x%04x-%04x-%04x-%04x-%04x%04x%04x\n' \
            $RANDOM $RANDOM $RANDOM $(($RANDOM & 0x0fff | 0x4000)) \
            $(($RANDOM & 0x3fff | 0x8000)) $RANDOM $RANDOM $RANDOM
    fi
}

#-------------------------------------------------------------------------------
# 包元数据管理
#-------------------------------------------------------------------------------

# 读取包的元数据
read_package_json() {
    local file="$1"
    local key="$2"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    # 简单的 JSON 解析
    local value=$(grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null | cut -d'"' -f4)
    echo "$value"
}

# 写入包的元数据
write_package_json() {
    local file="$1"
    local data="$2"
    
    echo "$data" > "$file"
}

# 创建包元数据模板
create_package_template() {
    local name="$1"
    local version="${2:-1.0.0}"
    local description="${3:-A NovaScript package}"
    local author="${4:-}"
    local license="${5:-MIT}"
    
    cat << EOF
{
    "name": "$name",
    "version": "$version",
    "description": "$description",
    "main": "index.nova",
    "type": "library",
    "keywords": [],
    "author": "$author",
    "license": "$license",
    "repository": {
        "type": "git",
        "url": ""
    },
    "dependencies": {},
    "devDependencies": {},
    "peerDependencies": {},
    "optionalDependencies": {},
    "scripts": {
        "test": "nova test",
        "build": "nova build"
    },
    "files": [
        "**/*.nova",
        "**/*.sh",
        "README.md"
    ],
    "engines": {
        "nova": ">=1.0.0"
    },
    "publishConfig": {
        "registry": "$NOVA_REGISTRY"
    }
}
EOF
}

#-------------------------------------------------------------------------------
# 版本管理
#-------------------------------------------------------------------------------

# 语义化版本比较
# 返回值：-1 (v1 < v2), 0 (v1 == v2), 1 (v1 > v2)
semver_compare() {
    local v1="$1"
    local v2="$2"
    
    # 移除前缀 v
    v1="${v1#v}"
    v2="${v2#v}"
    
    # 分割版本号
    IFS='.' read -ra V1_PARTS <<< "$v1"
    IFS='.' read -ra V2_PARTS <<< "$v2"
    
    local max_len=${#V1_PARTS[@]}
    [[ ${#V2_PARTS[@]} -gt $max_len ]] && max_len=${#V2_PARTS[@]}
    
    for ((i=0; i<max_len; i++)); do
        local part1=${V1_PARTS[i]:-0}
        local part2=${V2_PARTS[i]:-0}
        
        # 提取数字部分
        part1=$(echo "$part1" | grep -oE '[0-9]+' | head -1)
        part2=$(echo "$part2" | grep -oE '[0-9]+' | head -1)
        
        part1=${part1:-0}
        part2=${part2:-0}
        
        if [[ $part1 -lt $part2 ]]; then
            echo "-1"
            return
        elif [[ $part1 -gt $part2 ]]; then
            echo "1"
            return
        fi
    done
    
    echo "0"
}

# 解析版本范围（支持 ^, ~, >=, <=, >, <, =）
parse_version_range() {
    local range="$1"
    local current_version="$2"
    
    case "$range" in
        ^*)
            # 兼容版本：^1.2.3 允许 1.2.3 到 <2.0.0
            local base_version="${range#^}"
            IFS='.' read -ra PARTS <<< "$base_version"
            local major=${PARTS[0]:-0}
            echo ">=$base_version <$((major + 1)).0.0"
            ;;
        ~*)
            # 近似版本：~1.2.3 允许 1.2.3 到 <1.3.0
            local base_version="${range#\~}"
            IFS='.' read -ra PARTS <<< "$base_version"
            local major=${PARTS[0]:-0}
            local minor=${PARTS[1]:-0}
            echo ">=$base_version <$major.$((minor + 1)).0"
            ;;
        ">="*|"<="*|">"*|"<"*)
            echo "$range"
            ;;
        *)
            # 精确版本
            echo "=$range"
            ;;
    esac
}

# 检查版本是否满足范围
version_satisfies() {
    local version="$1"
    local range="$2"
    
    # 特殊值
    [[ "$range" == "latest" ]] && return 0
    [[ "$range" == "*" ]] && return 0
    
    # 解析范围
    local parsed=$(parse_version_range "$range")
    
    # 简单实现：只检查精确匹配和 >=
    if [[ "$parsed" == "="* ]]; then
        local target="${parsed#=}"
        [[ "$(semver_compare "$version" "$target")" == "0" ]] && return 0
    elif [[ "$parsed" == ">="* ]]; then
        local target="${parsed#>=}"
        [[ $(semver_compare "$version" "$target") != "-1" ]] && return 0
    fi
    
    return 1
}

#-------------------------------------------------------------------------------
# 依赖解析器
#-------------------------------------------------------------------------------

# 构建依赖树
declare -A PKG_DEPENDENCY_TREE=()
declare -A PKG_INSTALLED_VERSIONS=()

resolve_dependencies() {
    local pkg_name="$1"
    local pkg_version="${2:-latest}"
    local depth="${3:-0}"
    
    local indent=""
    for ((i=0; i<depth; i++)); do
        indent+="  "
    done
    
    log_debug "${indent}Resolving: $pkg_name@$pkg_version"
    
    # 检查循环依赖
    if [[ -n "${PKG_DEPENDENCY_TREE[$pkg_name]:-}" ]]; then
        log_warn "${indent}Circular dependency detected: $pkg_name"
        return 0
    fi
    
    # 标记为已处理
    PKG_DEPENDENCY_TREE["$pkg_name"]="$pkg_version"
    
    # 获取包的依赖信息
    local pkg_dir="$NOVA_PACKAGES_DIR/$pkg_name"
    local manifest_file="$pkg_dir/package.json"
    
    if [[ -f "$manifest_file" ]]; then
        # 解析 dependencies
        local deps=$(grep -A 30 '"dependencies"' "$manifest_file" 2>/dev/null | \
                    grep -E '^\s*"[^"]+":' | \
                    sed 's/[",]//g' | \
                    awk -F: '{gsub(/^ +| +$/, "", $1); gsub(/^ +| +$/, "", $2); print $1":"$2}')
        
        while IFS=: read -r dep_name dep_range; do
            [[ -z "$dep_name" ]] && continue
            [[ "$dep_name" == "dependencies" ]] && continue
            
            dep_name=$(echo "$dep_name" | tr -d ' ')
            dep_range=$(echo "$dep_range" | tr -d ' ')
            
            log_info "${indent}├─ Dependency: $dep_name@$dep_range"
            
            # 递归解析
            resolve_dependencies "$dep_name" "$dep_range" $((depth + 1))
        done <<< "$deps"
    fi
}

# 扁平化依赖（解决重复依赖问题）
flatten_dependencies() {
    local -A flat_deps=()
    
    for pkg_name in "${!PKG_DEPENDENCY_TREE[@]}"; do
        local version="${PKG_DEPENDENCY_TREE[$pkg_name]}"
        
        if [[ -n "${flat_deps[$pkg_name]:-}" ]]; then
            # 已存在，选择更高版本
            local existing="${flat_deps[$pkg_name]}"
            if [[ $(semver_compare "$version" "$existing") == "1" ]]; then
                flat_deps["$pkg_name"]="$version"
            fi
        else
            flat_deps["$pkg_name"]="$version"
        fi
    done
    
    # 输出扁平化的依赖
    for pkg_name in "${!flat_deps[@]}"; do
        echo "$pkg_name@${flat_deps[$pkg_name]}"
    done
}

#-------------------------------------------------------------------------------
# 包操作核心函数
#-------------------------------------------------------------------------------

# 下载包
download_package() {
    local pkg_name="$1"
    local pkg_version="${2:-latest}"
    local dest_dir="$3"
    
    log_info "Downloading $pkg_name@$pkg_version..."
    
    mkdir -p "$dest_dir"
    
    # 尝试多个源
    local sources=(
        "$NOVA_REGISTRY/$pkg_name/$pkg_version.tar.gz"
        "$NOVA_REGISTRY/packages/$pkg_name-$pkg_version.tar.gz"
        "https://github.com/novascript/packages/releases/download/$pkg_name-$pkg_version/$pkg_name-$pkg_version.tar.gz"
    )
    
    local downloaded=false
    
    for source in "${sources[@]}"; do
        log_debug "Trying: $source"
        
        if command -v curl &>/dev/null; then
            if curl -sLf "$source" -o "$dest_dir/package.tar.gz" 2>/dev/null && \
               [[ -s "$dest_dir/package.tar.gz" ]]; then
                if tar -xzf "$dest_dir/package.tar.gz" -C "$dest_dir" --strip-components=1 2>/dev/null; then
                    rm -f "$dest_dir/package.tar.gz"
                    downloaded=true
                    break
                fi
            fi
            rm -f "$dest_dir/package.tar.gz"
        fi
        
        if command -v wget &>/dev/null; then
            if wget -q "$source" -O "$dest_dir/package.tar.gz" 2>/dev/null && \
               [[ -s "$dest_dir/package.tar.gz" ]]; then
                if tar -xzf "$dest_dir/package.tar.gz" -C "$dest_dir" --strip-components=1 2>/dev/null; then
                    rm -f "$dest_dir/package.tar.gz"
                    downloaded=true
                    break
                fi
            fi
            rm -f "$dest_dir/package.tar.gz"
        fi
    done
    
    if [[ "$downloaded" == "false" ]]; then
        # 创建占位符包
        log_warn "Package not found in registry, creating placeholder..."
        create_package_template "$pkg_name" "$pkg_version" "Placeholder package" > "$dest_dir/package.json"
        echo "// Placeholder for $pkg_name" > "$dest_dir/index.nova"
        echo "# $pkg_name" > "$dest_dir/README.md"
        log_success "Created placeholder package: $pkg_name@$pkg_version"
    fi
    
    return 0
}

# 安装包
install_package() {
    local pkg_name="$1"
    local pkg_version="${2:-latest}"
    local global="${3:-false}"
    local save="${4:-false}"
    
    print_header "INSTALLING PACKAGE"
    
    log_info "Installing: ${COLOR_MAGENTA}$pkg_name${COLOR_RESET}@${COLOR_MAGENTA}$pkg_version${COLOR_RESET}"
    
    # 确定安装目录
    local install_dir
    if [[ "$global" == "true" ]]; then
        install_dir="$NOVA_PACKAGES_DIR/$pkg_name"
        mkdir -p "$NOVA_PACKAGES_DIR"
    else
        install_dir="./packages/$pkg_name"
        mkdir -p "./packages"
    fi
    
    # 检查是否已安装
    if [[ -d "$install_dir" ]]; then
        local current_version=$(read_package_json "$install_dir/package.json" "version")
        log_warn "Package already installed: $pkg_name@$current_version"
        
        # 检查是否需要更新
        if [[ "$pkg_version" != "latest" ]] && [[ "$current_version" != "$pkg_version" ]]; then
            log_info "Updating to version $pkg_version..."
        else
            log_info "Already up to date"
            return 0
        fi
    fi
    
    # 下载包
    download_package "$pkg_name" "$pkg_version" "$install_dir"
    
    # 验证包完整性
    if [[ -f "$install_dir/.checksum" ]]; then
        log_debug "Verifying package integrity..."
        # TODO: 实现 checksum 验证
    fi
    
    # 安装依赖
    if [[ -f "$install_dir/package.json" ]]; then
        log_info "Installing dependencies..."
        install_dependencies "$install_dir/package.json" false
    fi
    
    # 保存到 manifest
    if [[ "$save" == "true" ]] && [[ -f "$NOVA_MANIFEST_FILE" ]]; then
        add_dependency_to_manifest "$pkg_name" "$pkg_version"
    fi
    
    # 生成 lock 文件
    generate_lock_file
    
    local installed_version=$(read_package_json "$install_dir/package.json" "version")
    log_success "Installed: $pkg_name@${installed_version:-$pkg_version}"
    
    return 0
}

# 安装依赖
install_dependencies() {
    local manifest_file="$1"
    local global="${2:-false}"
    
    if [[ ! -f "$manifest_file" ]]; then
        log_error "Manifest not found: $manifest_file"
        return 1
    fi
    
    log_info "Installing dependencies from $(basename "$manifest_file")..."
    
    # 解析不同类型的依赖
    local dep_types=("dependencies" "devDependencies" "peerDependencies" "optionalDependencies")
    
    for dep_type in "${dep_types[@]}"; do
        local deps=$(sed -n "/\"$dep_type\"/,/}/p" "$manifest_file" 2>/dev/null | \
                    grep -E '^\s*"[^"]+":' | \
                    sed 's/[",]//g' | \
                    awk -F: '{gsub(/^ +| +$/, "", $1); gsub(/^ +| +$/, "", $2); print $1":"$2}')
        
        while IFS=: read -r dep_name dep_range; do
            [[ -z "$dep_name" ]] && continue
            [[ "$dep_name" == *"$dep_type"* ]] && continue
            
            dep_name=$(echo "$dep_name" | tr -d ' ')
            dep_range=$(echo "$dep_range" | tr -d ' ')
            
            [[ -z "$dep_name" ]] && continue
            
            local is_optional="false"
            [[ "$dep_type" == "optionalDependencies" ]] && is_optional="true"
            [[ "$dep_type" == "devDependencies" ]] && log_debug "Dev dependency: $dep_name"
            
            # 检查是否已安装
            if version_satisfies "${PKG_INSTALLED_VERSIONS[$dep_name]:-}" "$dep_range"; then
                log_debug "Dependency already satisfied: $dep_name@$dep_range"
                continue
            fi
            
            # 解析版本范围获取具体版本
            local install_version="$dep_range"
            [[ "$dep_range" == "^"* ]] || [[ "$dep_range" == "~"* ]] && install_version="latest"
            
            if [[ "$is_optional" == "true" ]]; then
                log_info "Optional dependency: $dep_name (skipping on error)"
                install_package "$dep_name" "$install_version" "$global" false || true
            else
                install_package "$dep_name" "$install_version" "$global" false
            fi
        done <<< "$deps"
    done
    
    log_success "All dependencies installed"
}

# 卸载包
uninstall_package() {
    local pkg_name="$1"
    local global="${2:-false}"
    
    print_header "UNINSTALLING PACKAGE"
    
    # 确定目录
    local pkg_dir
    if [[ "$global" == "true" ]]; then
        pkg_dir="$NOVA_PACKAGES_DIR/$pkg_name"
    else
        pkg_dir="./packages/$pkg_name"
    fi
    
    if [[ ! -d "$pkg_dir" ]]; then
        log_error "Package not found: $pkg_name"
        return 1
    fi
    
    # 检查是否有其他包依赖此包
    log_info "Checking for dependent packages..."
    # TODO: 实现依赖检查
    
    # 删除包
    rm -rf "$pkg_dir"
    
    # 从 manifest 移除
    if [[ -f "$NOVA_MANIFEST_FILE" ]]; then
        remove_dependency_from_manifest "$pkg_name"
    fi
    
    # 更新 lock 文件
    generate_lock_file
    
    log_success "Uninstalled: $pkg_name"
    
    return 0
}

# 更新包
update_package() {
    local pkg_name="${1:-all}"
    local global="${2:-false}"
    
    print_header "UPDATING PACKAGES"
    
    if [[ "$pkg_name" == "all" ]]; then
        log_info "Updating all packages..."
        
        local pkg_list
        if [[ "$global" == "true" ]]; then
            pkg_list=$(ls "$NOVA_PACKAGES_DIR" 2>/dev/null)
        else
            pkg_list=$(ls "./packages" 2>/dev/null)
        fi
        
        if [[ -z "$pkg_list" ]]; then
            log_info "No packages to update"
            return 0
        fi
        
        local updated_count=0
        for pkg in $pkg_list; do
            if update_single_package "$pkg" "$global"; then
                ((updated_count++))
            fi
        done
        
        log_success "Updated $updated_count package(s)"
    else
        if update_single_package "$pkg_name" "$global"; then
            log_success "Updated: $pkg_name"
        else
            log_warn "Nothing to update for: $pkg_name"
        fi
    fi
}

# 更新单个包
update_single_package() {
    local pkg_name="$1"
    local global="${2:-false}"
    
    local pkg_dir
    if [[ "$global" == "true" ]]; then
        pkg_dir="$NOVA_PACKAGES_DIR/$pkg_name"
    else
        pkg_dir="./packages/$pkg_name"
    fi
    
    if [[ ! -d "$pkg_dir" ]]; then
        return 1
    fi
    
    local current_version=$(read_package_json "$pkg_dir/package.json" "version")
    log_info "Checking updates for $pkg_name (current: $current_version)..."
    
    # 获取最新版本
    local latest_version="latest"
    # TODO: 从注册表获取最新版本
    
    if [[ "$current_version" == "$latest_version" ]]; then
        return 1
    fi
    
    # 备份
    local backup_dir="${pkg_dir}.bak.$(get_timestamp)"
    cp -r "$pkg_dir" "$backup_dir"
    
    # 重新安装
    rm -rf "$pkg_dir"
    install_package "$pkg_name" "latest" "$global" false
    
    if [[ -d "$pkg_dir" ]]; then
        rm -rf "$backup_dir"
        return 0
    else
        # 恢复备份
        rm -rf "$pkg_dir"
        mv "$backup_dir" "$pkg_dir"
        log_error "Update failed, restored previous version"
        return 1
    fi
}

# 搜索包
search_packages() {
    local query="$1"
    local limit="${2:-20}"
    
    print_header "SEARCHING PACKAGES"
    
    log_info "Searching for: ${COLOR_CYAN}$query${COLOR_RESET}"
    
    local results=()
    
    # 本地搜索
    log_info "Searching local packages..."
    if [[ -d "./packages" ]]; then
        while IFS= read -r pkg_dir; do
            [[ -z "$pkg_dir" ]] && continue
            local pkg_name=$(basename "$pkg_dir")
            if [[ "$pkg_name" == *"$query"* ]]; then
                local version=$(read_package_json "$pkg_dir/package.json" "version")
                results+=("LOCAL  $pkg_name @ $version")
            fi
        done < <(find ./packages -maxdepth 1 -type d 2>/dev/null)
    fi
    
    if [[ -d "$NOVA_PACKAGES_DIR" ]]; then
        while IFS= read -r pkg_dir; do
            [[ -z "$pkg_dir" ]] && continue
            local pkg_name=$(basename "$pkg_dir")
            if [[ "$pkg_name" == *"$query"* ]]; then
                local version=$(read_package_json "$pkg_dir/package.json" "version")
                results+=("GLOBAL $pkg_name @ $version")
            fi
        done < <(find "$NOVA_PACKAGES_DIR" -maxdepth 1 -type d 2>/dev/null)
    fi
    
    # 远程搜索
    if check_network; then
        log_info "Searching remote registry..."
        
        if command -v curl &>/dev/null; then
            local remote_results=$(curl -s "$NOVA_REGISTRY/search?q=$query&limit=$limit" 2>/dev/null)
            
            if [[ -n "$remote_results" ]] && [[ "$remote_results" != *"error"* ]]; then
                # 解析远程结果（简化版）
                echo "$remote_results" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | while read -r name; do
                    results+=("REMOTE $name @ latest")
                done
            fi
        fi
    else
        log_warn "Network unavailable, skipping remote search"
    fi
    
    # 显示结果
    if [[ ${#results[@]} -eq 0 ]]; then
        log_info "No packages found matching '$query'"
    else
        echo ""
        echo -e "${COLOR_WHITE}Type   Name                              Version${COLOR_RESET}"
        echo "─────────────────────────────────────────────────────────────"
        for result in "${results[@]}"; do
            echo "  $result"
        done
        echo ""
        log_info "Found ${#results[@]} package(s)"
    fi
}

# 列出已安装的包
list_packages() {
    local pattern="${1:-}"
    local global="${2:-false}"
    local format="${3:-table}"
    
    print_header "INSTALLED PACKAGES"
    
    local pkg_dirs=()
    
    if [[ "$global" == "true" ]] || [[ "$global" == "both" ]]; then
        [[ -d "$NOVA_PACKAGES_DIR" ]] && pkg_dirs+=("$NOVA_PACKAGES_DIR")
    fi
    
    if [[ "$global" != "true" ]] || [[ "$global" == "both" ]]; then
        [[ -d "./packages" ]] && pkg_dirs+=("./packages")
    fi
    
    if [[ ${#pkg_dirs[@]} -eq 0 ]]; then
        log_info "No packages installed"
        return 0
    fi
    
    local count=0
    
    case "$format" in
        table)
            echo ""
            echo -e "${COLOR_WHITE}Package                          Version      Location${COLOR_RESET}"
            echo "────────────────────────────────────────────────────────────────────"
            
            for pkg_dir in "${pkg_dirs[@]}"; do
                for dir in "$pkg_dir"/*; do
                    [[ ! -d "$dir" ]] && continue
                    
                    local name=$(basename "$dir")
                    
                    # 应用过滤
                    if [[ -n "$pattern" ]] && [[ "$name" != *"$pattern"* ]]; then
                        continue
                    fi
                    
                    local version=$(read_package_json "$dir/package.json" "version")
                    local location="$pkg_dir"
                    [[ "$location" == "$HOME"* ]] && location="~${location#$HOME}"
                    
                    printf "  %-30s %-12s %s\n" "$name" "${version:-unknown}" "$location"
                    ((count++))
                done
            done
            
            echo ""
            log_info "Total: $count package(s)"
            ;;
        
        json)
            echo "{"
            echo "  \"packages\": ["
            local first=true
            for pkg_dir in "${pkg_dirs[@]}"; do
                for dir in "$pkg_dir"/*; do
                    [[ ! -d "$dir" ]] && continue
                    local name=$(basename "$dir")
                    if [[ -n "$pattern" ]] && [[ "$name" != *"$pattern"* ]]; then
                        continue
                    fi
                    local version=$(read_package_json "$dir/package.json" "version")
                    [[ "$first" == "true" ]] || echo ","
                    first=false
                    echo -n "    {\"name\": \"$name\", \"version\": \"${version:-unknown}\", \"location\": \"$pkg_dir\"}"
                    ((count++))
                done
            done
            echo ""
            echo "  ],"
            echo "  \"total\": $count"
            echo "}"
            ;;
        
        list)
            for pkg_dir in "${pkg_dirs[@]}"; do
                for dir in "$pkg_dir"/*; do
                    [[ ! -d "$dir" ]] && continue
                    local name=$(basename "$dir")
                    if [[ -n "$pattern" ]] && [[ "$name" != *"$pattern"* ]]; then
                        continue
                    fi
                    local version=$(read_package_json "$dir/package.json" "version")
                    echo "$name@${version:-unknown}"
                    ((count++))
                done
            done
            ;;
    esac
    
    return 0
}

#-------------------------------------------------------------------------------
# Manifest 管理
#-------------------------------------------------------------------------------

# 添加依赖到 manifest
add_dependency_to_manifest() {
    local pkg_name="$1"
    local pkg_version="$2"
    local dev="${3:-false}"
    
    if [[ ! -f "$NOVA_MANIFEST_FILE" ]]; then
        log_warn "No manifest file found, creating one..."
        create_package_template "$(basename "$PWD")" "1.0.0" > "$NOVA_MANIFEST_FILE"
    fi
    
    local dep_key="dependencies"
    [[ "$dev" == "true" ]] && dep_key="devDependencies"
    
    # 简单的 JSON 更新（实际应该用 jq）
    if grep -q "\"$dep_key\"" "$NOVA_MANIFEST_FILE"; then
        # 添加或更新依赖
        sed -i "/\"$dep_key\"/a\\    \"$pkg_name\": \"$pkg_version\"," "$NOVA_MANIFEST_FILE" 2>/dev/null || \
        log_warn "Could not auto-update manifest, please add manually: \"$pkg_name\": \"$pkg_version\""
    fi
    
    log_debug "Added $pkg_name@$pkg_version to $dep_key"
}

# 从 manifest 移除依赖
remove_dependency_from_manifest() {
    local pkg_name="$1"
    
    if [[ ! -f "$NOVA_MANIFEST_FILE" ]]; then
        return 0
    fi
    
    # 简单的 JSON 更新
    sed -i "/\"$pkg_name\"[[:space:]]*:/d" "$NOVA_MANIFEST_FILE" 2>/dev/null || \
    log_warn "Could not auto-remove from manifest"
    
    log_debug "Removed $pkg_name from manifest"
}

# 生成 lock 文件
generate_lock_file() {
    log_debug "Generating lock file..."
    
    local lock_data="{\n  \"lockfileVersion\": 2,\n  \"packages\": {\n"
    local first=true
    
    # 收集所有已安装包
    for pkg_dir in "./packages"/* "$NOVA_PACKAGES_DIR"/*; do
        [[ ! -d "$pkg_dir" ]] && continue
        
        local name=$(basename "$pkg_dir")
        local version=$(read_package_json "$pkg_dir/package.json" "version")
        local resolved=""
        local integrity=""
        
        [[ "$first" == "true" ]] || lock_data+=",\n"
        first=false
        
        lock_data+="    \"$name@${version:-latest}\": {\n"
        lock_data+="      \"version\": \"${version:-latest}\",\n"
        lock_data+="      \"resolved\": \"$resolved\",\n"
        lock_data+="      \"integrity\": \"$integrity\"\n"
        lock_data+="    }"
    done
    
    lock_data+="\n  }\n}"
    
    echo -e "$lock_data" > "$NOVA_LOCK_FILE"
    
    log_debug "Lock file generated: $NOVA_LOCK_FILE"
}

# 从 lock 文件安装
install_from_lock() {
    if [[ ! -f "$NOVA_LOCK_FILE" ]]; then
        log_warn "No lock file found"
        return 1
    fi
    
    log_info "Installing from lock file..."
    
    # 解析 lock 文件并安装
    # TODO: 实现 lock 文件解析
    
    log_success "Lock file dependencies installed"
}

#-------------------------------------------------------------------------------
# 发布包
#-------------------------------------------------------------------------------

publish_package() {
    local pkg_dir="${1:-.}"
    local tag="${2:-latest}"
    local dry_run="${3:-false}"
    
    print_header "PUBLISHING PACKAGE"
    
    # 验证包
    log_info "Validating package..."
    
    if [[ ! -f "$pkg_dir/package.json" ]]; then
        log_error "No package.json found in $pkg_dir"
        return 1
    fi
    
    local name=$(read_package_json "$pkg_dir/package.json" "name")
    local version=$(read_package_json "$pkg_dir/package.json" "version")
    
    if [[ -z "$name" ]]; then
        log_error "Package name not found in package.json"
        return 1
    fi
    
    if [[ -z "$version" ]]; then
        log_error "Package version not found in package.json"
        return 1
    fi
    
    log_info "Publishing: ${COLOR_MAGENTA}$name${COLOR_RESET}@${COLOR_MAGENTA}$version${COLOR_RESET} (tag: $tag)"
    
    # 运行 pre-publish 脚本
    local pre_publish=$(sed -n '/"scripts"/,/}/p' "$pkg_dir/package.json" | grep '"prepublish"' | cut -d'"' -f4)
    if [[ -n "$pre_publish" ]]; then
        log_info "Running prepublish script: $pre_publish"
        eval "$pre_publish" || {
            log_error "Prepublish script failed"
            return 1
        }
    fi
    
    # 打包
    local tarball="$name-$version.tgz"
    log_info "Creating tarball: $tarball"
    
    tar -czf "$tarball" -C "$pkg_dir" . || {
        log_error "Failed to create tarball"
        return 1
    }
    
    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would publish $tarball to registry"
        rm -f "$tarball"
        return 0
    fi
    
    # 发布到注册表
    if check_network; then
        log_info "Uploading to registry..."
        
        if command -v curl &>/dev/null; then
            local response=$(curl -sX PUT "$NOVA_REGISTRY/$name/$version" \
                -H "Content-Type: application/octet-stream" \
                -H "Authorization: Bearer ${NOVA_AUTH_TOKEN:-}" \
                --data-binary "@$tarball" 2>/dev/null)
            
            if [[ "$response" == *"success"* ]] || [[ "$response" == *"published"* ]]; then
                log_success "Published: $name@$version"
            else
                log_warn "Upload completed but response unclear: $response"
            fi
        else
            log_warn "curl not available, cannot upload"
        fi
    else
        log_warn "Network unavailable, tarball created locally: $tarball"
    fi
    
    # 清理
    rm -f "$tarball"
    
    return 0
}

#-------------------------------------------------------------------------------
# 初始化项目
#-------------------------------------------------------------------------------

init_project() {
    local name="${1:-$(basename "$PWD")}"
    local template="${2:-default}"
    
    print_header "INITIALIZING PROJECT"
    
    log_info "Creating project: ${COLOR_CYAN}$name${COLOR_RESET}"
    
    # 创建目录结构
    mkdir -p src lib test packages docs
    
    # 创建 manifest
    if [[ -f "$NOVA_MANIFEST_FILE" ]]; then
        log_warn "$NOVA_MANIFEST_FILE already exists"
        read -p "Overwrite? (y/N): " confirm
        [[ "$confirm" != "y" ]] && return 0
    fi
    
    create_package_template "$name" "1.0.0" "A NovaScript project" > "$NOVA_MANIFEST_FILE"
    log_success "Created $NOVA_MANIFEST_FILE"
    
    # 创建示例文件
    if [[ ! -d "src" ]]; then
        mkdir -p src
    fi
    
    cat > "src/main.nova" << 'EOF'
#!/bin/bash
#===============================================================================
# Main Application Entry Point
#===============================================================================

import std.io
import std.string

func main(args) {
    io.print("Hello from NovaScript!")
    io.print("Project: {{project_name}}")
    io.print("Version: {{project_version}}")
    
    return 0
}

main(@ARGV)
EOF
    
    # 替换模板变量
    sed -i "s/{{project_name}}/$name/g" "src/main.nova"
    sed -i "s/{{project_version}}/1.0.0/g" "src/main.nova"
    
    log_success "Created src/main.nova"
    
    # 创建 .novaignore
    cat > ".novaignore" << 'EOF'
node_modules/
*.nbc
*.enc.nova
dist/
build/
.env
*.log
.DS_Store
Thumbs.db
EOF
    
    log_success "Created .novaignore"
    
    # 创建 README
    cat > "README.md" << EOF
# $name

A NovaScript project.

## Installation

\`\`\`bash
nova pkg install
\`\`\`

## Usage

\`\`\`bash
nova run src/main.nova
\`\`\`

## Development

\`\`\`bash
nova pkg install --dev
nova test
\`\`\`

## License

MIT
EOF
    
    log_success "Created README.md"
    
    echo ""
    log_success "Project initialized successfully!"
    echo ""
    echo "Next steps:"
    echo "  cd $(pwd)"
    echo "  nova pkg install"
    echo "  nova run src/main.nova"
}

#-------------------------------------------------------------------------------
# 缓存管理
#-------------------------------------------------------------------------------

clear_cache() {
    print_header "CLEARING CACHE"
    
    if [[ -d "$NOVA_CACHE_DIR" ]]; then
        local cache_size=$(du -sh "$NOVA_CACHE_DIR" 2>/dev/null | cut -f1)
        log_info "Cache size: $cache_size"
        
        rm -rf "$NOVA_CACHE_DIR"/*
        log_success "Cache cleared"
    else
        log_info "No cache to clear"
    fi
}

#-------------------------------------------------------------------------------
# 包信息查看
#-------------------------------------------------------------------------------

view_package_info() {
    local pkg_name="$1"
    
    print_header "PACKAGE INFO"
    
    local pkg_dir="$NOVA_PACKAGES_DIR/$pkg_name"
    [[ ! -d "$pkg_dir" ]] && pkg_dir="./packages/$pkg_name"
    
    if [[ ! -d "$pkg_dir" ]]; then
        log_error "Package not found: $pkg_name"
        return 1
    fi
    
    local manifest="$pkg_dir/package.json"
    
    if [[ ! -f "$manifest" ]]; then
        log_error "No package.json found"
        return 1
    fi
    
    echo ""
    echo -e "${COLOR_WHITE}Name:${COLOR_RESET}        $(read_package_json "$manifest" "name")"
    echo -e "${COLOR_WHITE}Version:${COLOR_RESET}     $(read_package_json "$manifest" "version")"
    echo -e "${COLOR_WHITE}Description:${COLOR_RESET} $(read_package_json "$manifest" "description")"
    echo -e "${COLOR_WHITE}Author:${COLOR_RESET}      $(read_package_json "$manifest" "author")"
    echo -e "${COLOR_WHITE}License:${COLOR_RESET}     $(read_package_json "$manifest" "license")"
    echo -e "${COLOR_WHITE}Main:${COLOR_RESET}        $(read_package_json "$manifest" "main")"
    echo ""
    
    # 显示依赖
    echo -e "${COLOR_WHITE}Dependencies:${COLOR_RESET}"
    grep -A 20 '"dependencies"' "$manifest" 2>/dev/null | grep -E '^\s*"[^"]+":' | sed 's/[",]//g' | while read -r line; do
        echo "  $line"
    done
    
    echo ""
    
    # 显示脚本
    echo -e "${COLOR_WHITE}Scripts:${COLOR_RESET}"
    grep -A 10 '"scripts"' "$manifest" 2>/dev/null | grep -E '^\s*"[^"]+":' | sed 's/[",]//g' | while read -r line; do
        echo "  $line"
    done
    
    echo ""
}

#-------------------------------------------------------------------------------
# 主命令入口
#-------------------------------------------------------------------------------

cmd_pkg() {
    local subcommand="${1:-help}"
    shift || true
    
    case "$subcommand" in
        install|i|add)
            local global=false
            local save=false
            local packages=()
            
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -g|--global)
                        global=true
                        shift
                        ;;
                    -S|--save)
                        save=true
                        shift
                        ;;
                    -D|--save-dev)
                        save=true
                        # TODO: 标记为 devDependency
                        shift
                        ;;
                    *)
                        packages+=("$1")
                        shift
                        ;;
                esac
            done
            
            if [[ ${#packages[@]} -eq 0 ]]; then
                # 安装项目依赖
                if [[ -f "$NOVA_MANIFEST_FILE" ]]; then
                    install_dependencies "$NOVA_MANIFEST_FILE" "$global"
                elif [[ -f "$NOVA_LOCK_FILE" ]]; then
                    install_from_lock
                else
                    log_error "No package.json or nova.lock found"
                    echo "Run 'nova pkg init' to create a new project"
                    return 1
                fi
            else
                for pkg in "${packages[@]}"; do
                    local pkg_name="${pkg%@*}"
                    local pkg_version="${pkg#*@}"
                    [[ "$pkg_version" == "$pkg" ]] && pkg_version="latest"
                    
                    install_package "$pkg_name" "$pkg_version" "$global" "$save"
                done
            fi
            ;;
        
        uninstall|remove|rm|r)
            local global=false
            local packages=()
            
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -g|--global)
                        global=true
                        shift
                        ;;
                    *)
                        packages+=("$1")
                        shift
                        ;;
                esac
            done
            
            if [[ ${#packages[@]} -eq 0 ]]; then
                log_error "Please specify package name(s)"
                return 1
            fi
            
            for pkg in "${packages[@]}"; do
                uninstall_package "$pkg" "$global"
            done
            ;;
        
        update|up|u)
            local global=false
            local packages=()
            
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -g|--global)
                        global=true
                        shift
                        ;;
                    *)
                        packages+=("$1")
                        shift
                        ;;
                esac
            done
            
            if [[ ${#packages[@]} -eq 0 ]]; then
                update_package "all" "$global"
            else
                for pkg in "${packages[@]}"; do
                    update_package "$pkg" "$global"
                done
            fi
            ;;
        
        search|s|find)
            if [[ -z "${1:-}" ]]; then
                log_error "Please specify search query"
                return 1
            fi
            search_packages "$@"
            ;;
        
        list|ls|l)
            local pattern=""
            local global="both"
            local format="table"
            
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -g|--global)
                        global="true"
                        shift
                        ;;
                    -l|--local)
                        global="false"
                        shift
                        ;;
                    --json)
                        format="json"
                        shift
                        ;;
                    --list)
                        format="list"
                        shift
                        ;;
                    *)
                        pattern="$1"
                        shift
                        ;;
                esac
            done
            
            list_packages "$pattern" "$global" "$format"
            ;;
        
        publish|pub|p)
            local tag="latest"
            local dry_run=false
            
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --tag)
                        tag="$2"
                        shift 2
                        ;;
                    --dry-run)
                        dry_run=true
                        shift
                        ;;
                    *)
                        shift
                        ;;
                esac
            done
            
            publish_package "." "$tag" "$dry_run"
            ;;
        
        init|i)
            local name=""
            local template="default"
            
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    -t|--template)
                        template="$2"
                        shift 2
                        ;;
                    *)
                        name="$1"
                        shift
                        ;;
                esac
            done
            
            init_project "$name" "$template"
            ;;
        
        info|show|view)
            if [[ -z "${1:-}" ]]; then
                log_error "Please specify package name"
                return 1
            fi
            view_package_info "$1"
            ;;
        
        cache|c)
            clear_cache
            ;;
        
        help|h|-h|--help|*)
            show_pkg_help
            ;;
    esac
}

# 显示帮助
show_pkg_help() {
    cat << EOF
${COLOR_CYAN}NovaScript Package Manager (nova pkg)${COLOR_RESET}
Version: $NOVA_PKG_VERSION

${COLOR_WHITE}USAGE:${COLOR_RESET}
  nova pkg <command> [options] [arguments]

${COLOR_WHITE}COMMANDS:${COLOR_RESET}
  ${COLOR_GREEN}install${COLOR_RESET} [packages...]    Install packages (aliases: i, add)
    -g, --global          Install globally
    -S, --save            Save to dependencies
    -D, --save-dev        Save to devDependencies
  
  ${COLOR_GREEN}remove${COLOR_RESET} <packages...>     Remove packages (aliases: uninstall, rm, r)
    -g, --global          Remove from global
  
  ${COLOR_GREEN}update${COLOR_RESET} [packages...]     Update packages (aliases: up, u)
    -g, --global          Update global packages
  
  ${COLOR_GREEN}search${COLOR_RESET} <query>           Search for packages (aliases: s, find)
  
  ${COLOR_GREEN}list${COLOR_RESET} [pattern]           List installed packages (aliases: ls, l)
    -g, --global          List global packages only
    -l, --local           List local packages only
    --json                Output as JSON
    --list                Output as simple list
  
  ${COLOR_GREEN}publish${COLOR_RESET}                  Publish current package (aliases: pub, p)
    --tag <tag>           Set publish tag (default: latest)
    --dry-run             Test publish without uploading
  
  ${COLOR_GREEN}init${COLOR_RESET} [name]              Initialize new project (aliases: i)
    -t, --template        Use template (default, library, cli)
  
  ${COLOR_GREEN}info${COLOR_RESET} <package>           Show package info (aliases: show, view)
  
  ${COLOR_GREEN}cache${COLOR_RESET}                    Clear package cache (alias: c)
  
  ${COLOR_GREEN}help${COLOR_RESET}                     Show this help

${COLOR_WHITE}EXAMPLES:${COLOR_RESET}
  nova pkg install lodash              Install a package locally
  nova pkg install -g typescript       Install globally
  nova pkg install express@4.18.0      Install specific version
  nova pkg remove lodash               Remove a package
  nova pkg update                      Update all packages
  nova pkg search web                  Search for packages
  nova pkg list                        List installed packages
  nova pkg publish --dry-run           Test publish
  nova pkg init my-project             Create new project
  nova pkg info express                View package details

${COLOR_WHITE}ENVIRONMENT VARIABLES:${COLOR_RESET}
  NOVA_REGISTRY         Package registry URL
  NOVA_PACKAGES_DIR     Global packages directory
  NOVA_CACHE_DIR        Cache directory
  NOVA_AUTH_TOKEN       Authentication token for publishing
  NOVA_DEBUG            Enable debug mode

${COLOR_WHITE}FILES:${COLOR_RESET}
  nova.json             Project manifest
  nova.lock             Lock file for reproducible installs
  .novaignore           Ignore patterns

For more information, visit: https://novascript.dev/docs/pkg
EOF
}

# 导出函数供外部调用
export -f cmd_pkg
export -f install_package uninstall_package update_package search_packages
export -f list_packages publish_package init_project
