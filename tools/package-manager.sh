#!/bin/bash
#===============================================================================
# NovaScript 包管理器
# 支持安装、更新、搜索和移除包
#===============================================================================

# 包注册表 URL
NOVA_REGISTRY="${NOVA_REGISTRY:-https://registry.novascript.dev}"
NOVA_PACKAGES_DIR="${NOVA_PACKAGES_DIR:-$HOME/.nova/packages}"

#-------------------------------------------------------------------------------
# 安装包
#-------------------------------------------------------------------------------
nova_pkg_install() {
    local packages=("$@")
    
    for pkg in "${packages[@]}"; do
        echo "Installing package: $pkg"
        
        # 解析包名和版本
        local pkg_name="${pkg%@*}"
        local pkg_version="${pkg#*@}"
        [[ "$pkg_version" == "$pkg" ]] && pkg_version="latest"
        
        # 创建包目录
        local pkg_dir="$NOVA_PACKAGES_DIR/$pkg_name"
        mkdir -p "$pkg_dir"
        
        # 下载包（简化版，实际应该从注册表下载）
        if [[ -n "${NOVA_OFFLINE:-}" ]]; then
            echo "Offline mode: skipping download"
        else
            # 尝试从本地或远程获取
            nova_pkg_download "$pkg_name" "$pkg_version" "$pkg_dir"
        fi
        
        # 安装依赖
        if [[ -f "$pkg_dir/package.json" ]]; then
            nova_pkg_install_deps "$pkg_dir"
        fi
        
        echo "Installed: $pkg_name@$pkg_version"
    done
}

#-------------------------------------------------------------------------------
# 下载包
#-------------------------------------------------------------------------------
nova_pkg_download() {
    local name="$1"
    local version="$2"
    local dest="$3"
    
    # 尝试从本地项目复制（开发模式）
    if [[ -d "./packages/$name" ]]; then
        cp -r "./packages/$name"/* "$dest/"
        return 0
    fi
    
    # 尝试从注册表下载
    if command -v curl &>/dev/null; then
        local url="$NOVA_REGISTRY/$name/$version.tar.gz"
        curl -sL "$url" -o "$dest/package.tar.gz" 2>/dev/null && {
            tar -xzf "$dest/package.tar.gz" -C "$dest"
            rm "$dest/package.tar.gz"
            return 0
        }
    fi
    
    if command -v wget &>/dev/null; then
        local url="$NOVA_REGISTRY/$name/$version.tar.gz"
        wget -q "$url" -O "$dest/package.tar.gz" 2>/dev/null && {
            tar -xzf "$dest/package.tar.gz" -C "$dest"
            rm "$dest/package.tar.gz"
            return 0
        }
    fi
    
    # 创建占位包
    cat > "$dest/package.json" << EOF
{
    "name": "$name",
    "version": "$version",
    "description": "Package placeholder",
    "main": "index.nova"
}
EOF
    
    echo "Created placeholder for: $name"
    return 0
}

#-------------------------------------------------------------------------------
# 安装依赖
#-------------------------------------------------------------------------------
nova_pkg_install_deps() {
    local pkg_dir="$1"
    
    if [[ ! -f "$pkg_dir/package.json" ]]; then
        return 0
    fi
    
    # 简单的 JSON 解析获取依赖
    local deps=$(grep -o '"dependencies"[[:space:]]*:[[:space:]]*{[^}]*}' "$pkg_dir/package.json" 2>/dev/null || echo "")
    
    if [[ -n "$deps" ]]; then
        # 提取依赖包名
        local dep_names=$(echo "$deps" | grep -o '"[^"]*"[[:space:]]*:' | sed 's/"//g' | sed 's/://g' | tr '\n' ' ')
        
        for dep in $dep_names; do
            [[ "$dep" == "dependencies" ]] && continue
            echo "Installing dependency: $dep"
            nova_pkg_install "$dep"
        done
    fi
}

#-------------------------------------------------------------------------------
# 安装所有依赖（项目级别）
#-------------------------------------------------------------------------------
nova_pkg_install_all() {
    if [[ ! -f "nova.json" ]] && [[ ! -f "package.json" ]]; then
        echo "Error: No nova.json or package.json found" >&2
        return 1
    fi
    
    local manifest="nova.json"
    [[ ! -f "$manifest" ]] && manifest="package.json"
    
    echo "Installing dependencies from $manifest..."
    
    # 提取依赖
    local deps=$(grep -o '"dependencies"[[:space:]]*:[[:space:]]*{[^}]*}' "$manifest" 2>/dev/null || echo "")
    
    if [[ -n "$deps" ]]; then
        local dep_names=$(echo "$deps" | grep -o '"[^"]*"[[:space:]]*:' | sed 's/"//g' | sed 's/://g' | tr '\n' ' ')
        
        for dep in $dep_names; do
            [[ "$dep" == "dependencies" ]] && continue
            nova_pkg_install "$dep"
        done
    fi
    
    echo "Dependencies installed"
}

#-------------------------------------------------------------------------------
# 移除包
#-------------------------------------------------------------------------------
nova_pkg_remove() {
    local packages=("$@")
    
    for pkg in "${packages[@]}"; do
        local pkg_dir="$NOVA_PACKAGES_DIR/$pkg"
        
        if [[ -d "$pkg_dir" ]]; then
            rm -rf "$pkg_dir"
            echo "Removed: $pkg"
        else
            echo "Package not found: $pkg" >&2
        fi
    done
}

#-------------------------------------------------------------------------------
# 搜索包
#-------------------------------------------------------------------------------
nova_pkg_search() {
    local query="$1"
    
    echo "Searching for: $query"
    
    # 本地搜索
    if [[ -d "./packages" ]]; then
        local local_results=$(find ./packages -name "*$query*" -type d 2>/dev/null)
        if [[ -n "$local_results" ]]; then
            echo "Local packages:"
            echo "$local_results"
        fi
    fi
    
    # 远程搜索（如果有网络）
    if command -v curl &>/dev/null; then
        local results=$(curl -s "$NOVA_REGISTRY/search?q=$query" 2>/dev/null || echo "")
        if [[ -n "$results" ]]; then
            echo "Remote packages:"
            echo "$results"
        fi
    fi
}

#-------------------------------------------------------------------------------
# 列出已安装的包
#-------------------------------------------------------------------------------
nova_pkg_list() {
    local pattern="${1:-*}"
    
    if [[ -d "$NOVA_PACKAGES_DIR" ]]; then
        for pkg_dir in "$NOVA_PACKAGES_DIR"/*; do
            if [[ -d "$pkg_dir" ]]; then
                local name=$(basename "$pkg_dir")
                local version="unknown"
                
                if [[ -f "$pkg_dir/package.json" ]]; then
                    version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$pkg_dir/package.json" | cut -d'"' -f4)
                fi
                
                if [[ "$name" == *"$pattern"* ]]; then
                    echo "$name@$version"
                fi
            fi
        done
    else
        echo "No packages installed"
    fi
}

#-------------------------------------------------------------------------------
# 更新包
#-------------------------------------------------------------------------------
nova_pkg_update() {
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        # 更新所有包
        packages=($(nova_pkg_list | cut -d'@' -f1))
    fi
    
    for pkg in "${packages[@]}"; do
        local pkg_dir="$NOVA_PACKAGES_DIR/$pkg"
        
        if [[ -d "$pkg_dir" ]]; then
            local current_version="unknown"
            if [[ -f "$pkg_dir/package.json" ]]; then
                current_version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$pkg_dir/package.json" | cut -d'"' -f4)
            fi
            
            echo "Updating: $pkg ($current_version -> latest)"
            
            # 备份
            cp -r "$pkg_dir" "$pkg_dir.bak"
            
            # 重新安装
            rm -rf "$pkg_dir"
            nova_pkg_download "$pkg" "latest" "$pkg_dir"
            
            if [[ -d "$pkg_dir" ]]; then
                rm -rf "$pkg_dir.bak"
                echo "Updated: $pkg"
            else
                # 恢复备份
                mv "$pkg_dir.bak" "$pkg_dir"
                echo "Failed to update: $pkg"
            fi
        fi
    done
    
    echo "Update completed"
}

#-------------------------------------------------------------------------------
# 发布包
#-------------------------------------------------------------------------------
nova_pkg_publish() {
    local pkg_dir="${1:-.}"
    
    if [[ ! -f "$pkg_dir/package.json" ]] && [[ ! -f "$pkg_dir/nova.json" ]]; then
        echo "Error: No package.json or nova.json found" >&2
        return 1
    fi
    
    local manifest="$pkg_dir/package.json"
    [[ ! -f "$manifest" ]] && manifest="$pkg_dir/nova.json"
    
    # 读取包信息
    local name=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest" | cut -d'"' -f4)
    local version=$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$manifest" | cut -d'"' -f4)
    
    echo "Publishing: $name@$version"
    
    # 创建压缩包
    local tarball="$name-$version.tar.gz"
    tar -czf "$tarball" -C "$pkg_dir" .
    
    # 上传到注册表
    if command -v curl &>/dev/null; then
        curl -X PUT "$NOVA_REGISTRY/$name/$version" \
            -H "Content-Type: application/octet-stream" \
            --data-binary "@$tarball" 2>/dev/null && {
            echo "Published: $name@$version"
        } || {
            echo "Failed to publish (offline or registry unavailable)"
        }
    else
        echo "Created tarball: $tarball"
    fi
    
    rm -f "$tarball"
}

#-------------------------------------------------------------------------------
# 初始化包
#-------------------------------------------------------------------------------
nova_pkg_init() {
    local name="${1:-$(basename "$PWD")}"
    
    cat > "nova.json" << EOF
{
    "name": "$name",
    "version": "1.0.0",
    "description": "A NovaScript package",
    "main": "index.nova",
    "type": "library",
    "dependencies": {},
    "devDependencies": {},
    "scripts": {
        "test": "nova test"
    },
    "author": "",
    "license": "MIT",
    "keywords": []
}
EOF
    
    echo "Created nova.json"
}
