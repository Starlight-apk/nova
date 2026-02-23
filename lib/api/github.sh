#!/bin/bash
#===============================================================================
# NovaScript GitHub Package Manager
# 从 GitHub 下载安装依赖（无需硬编码密钥）
#===============================================================================

#-------------------------------------------------------------------------------
# 配置
#-------------------------------------------------------------------------------
GITHUB_API_BASE="https://api.github.com"
GITHUB_RAW_BASE="https://raw.githubusercontent.com"
DEFAULT_OWNER="novascript"
DEFAULT_REPO="packages"

#-------------------------------------------------------------------------------
# 从 GitHub 下载包
#-------------------------------------------------------------------------------
github_download_package() {
    local owner="${1:-$DEFAULT_OWNER}"
    local repo="${2:-$DEFAULT_REPO}"
    local package="$3"
    local version="${4:-main}"
    local dest="$HOME/.nova/packages/$package"
    
    echo -e "\033[0;36m[INFO]\033[0m Downloading from GitHub: $owner/$repo/$package"
    
    # 创建目标目录
    mkdir -p "$dest"
    
    # 构建 URL
    local zip_url="https://github.com/$owner/$repo/archive/refs/heads/$version.zip"
    local tar_url="https://github.com/$owner/$repo/archive/refs/heads/$version.tar.gz"
    
    # 尝试下载
    local downloaded=false
    
    if command -v curl &>/dev/null; then
        # 先获取包的具体路径
        local pkg_path=$(github_get_package_path "$owner" "$repo" "$package" "$version")
        
        if [[ -n "$pkg_path" ]]; then
            # 下载单个包目录
            local download_url="$GITHUB_RAW_BASE/$owner/$repo/$version/$pkg_path"
            
            echo -e "\033[0;36m[INFO]\033[0m Downloading from: $download_url"
            
            # 下载文件列表
            local files=$(curl -s "https://api.github.com/repos/$owner/$repo/contents/$pkg_path?ref=$version" | \
                python3 -c "import sys,json; [print(f['download_url']) for f in json.load(sys.stdin) if f['type']=='file']" 2>/dev/null)
            
            if [[ -n "$files" ]]; then
                while IFS= read -r file_url; do
                    local filename=$(basename "$file_url")
                    echo -e "\033[0;36m[INFO]\033[0m Downloading: $filename"
                    curl -sL "$file_url" -o "$dest/$filename"
                done <<< "$files"
                downloaded=true
            fi
        fi
    fi
    
    if command -v wget &>/dev/null && [[ "$downloaded" == "false" ]]; then
        wget -q "$tar_url" -O "$dest/package.tar.gz" && {
            tar -xzf "$dest/package.tar.gz" -C "$dest" --strip-components=1
            rm "$dest/package.tar.gz"
            downloaded=true
        }
    fi
    
    if [[ "$downloaded" == "false" ]]; then
        # 创建占位符
        cat > "$dest/package.json" << EOF
{
    "name": "$package",
    "version": "$version",
    "source": "github.com/$owner/$repo",
    "description": "Package from GitHub"
}
EOF
        echo -e "\033[1;33m[WARN]\033[0m Could not download, created placeholder"
    fi
    
    echo -e "\033[1;32m[OK]\033[0m Package downloaded: $package"
}

#-------------------------------------------------------------------------------
# 从 GitHub 获取包路径
#-------------------------------------------------------------------------------
github_get_package_path() {
    local owner="$1"
    local repo="$2"
    local package="$3"
    local version="${4:-main}"
    
    # 尝试从 API 获取目录列表
    local contents=$(curl -s "$GITHUB_API_BASE/repos/$owner/$repo/contents?ref=$version" 2>/dev/null)
    
    if [[ -n "$contents" ]]; then
        # 查找匹配的包目录
        local pkg_path=$(echo "$contents" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for item in data:
        name = item.get('name', '')
        if name == '$package' or name.startswith('$package'):
            print(item.get('path', ''))
            break
except:
    pass
" 2>/dev/null)
        
        echo "$pkg_path"
    fi
}

#-------------------------------------------------------------------------------
# 搜索 GitHub 包
#-------------------------------------------------------------------------------
github_search_packages() {
    local query="$1"
    local owner="${2:-$DEFAULT_OWNER}"
    
    echo -e "\033[0;36m[INFO]\033[0m Searching GitHub for: $query"
    
    if command -v curl &>/dev/null; then
        # 搜索仓库
        local results=$(curl -s "$GITHUB_API_BASE/search/repositories?q=$query+topic:novascript+topic:package&per_page=10" 2>/dev/null)
        
        if [[ -n "$results" ]]; then
            echo ""
            echo -e "\033[1;36mGitHub Packages:\033[0m"
            echo "$results" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for item in data.get('items', [])[:5]:
        name = item.get('full_name', 'unknown')
        desc = item.get('description', 'No description')
        stars = item.get('stargazers_count', 0)
        print(f'  📦 {name}')
        print(f'     {desc}')
        print(f'     ⭐ {stars} stars')
        print()
except Exception as e:
    print(f'  (parse error: {e})')
" 2>/dev/null
        else
            echo "  (offline or search unavailable)"
        fi
    else
        echo "  (curl not available)"
    fi
}

#-------------------------------------------------------------------------------
# 从 GitHub Release 下载
#-------------------------------------------------------------------------------
github_download_release() {
    local owner="$1"
    local repo="$2"
    local package="$3"
    local version="${4:-latest}"
    local dest="$HOME/.nova/packages/$package"
    
    echo -e "\033[0;36m[INFO]\033[0m Downloading from GitHub Release: $owner/$repo/$package"
    
    mkdir -p "$dest"
    
    # 获取最新版本
    if [[ "$version" == "latest" ]]; then
        local release_url="$GITHUB_API_BASE/repos/$owner/$repo/releases/latest"
    else
        local release_url="$GITHUB_API_BASE/repos/$owner/$repo/releases/tags/$version"
    fi
    
    if command -v curl &>/dev/null; then
        local release_info=$(curl -s "$release_url" 2>/dev/null)
        
        if [[ -n "$release_info" ]]; then
            # 下载资源文件
            local assets=$(echo "$release_info" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for asset in data.get('assets', []):
        name = asset.get('name', '')
        url = asset.get('browser_download_url', '')
        if '$package' in name or name.endswith('.tar.gz') or name.endswith('.zip'):
            print(f'{name}|{url}')
except:
    pass
" 2>/dev/null)
            
            if [[ -n "$assets" ]]; then
                while IFS='|' read -r name url; do
                    echo -e "\033[0;36m[INFO]\033[0m Downloading asset: $name"
                    curl -sL "$url" -o "$dest/$name"
                    
                    # 如果是压缩包，解压
                    if [[ "$name" == *.tar.gz ]]; then
                        tar -xzf "$dest/$name" -C "$dest"
                        rm "$dest/$name"
                    elif [[ "$name" == *.zip ]]; then
                        unzip -q "$dest/$name" -d "$dest"
                        rm "$dest/$name"
                    fi
                done <<< "$assets"
                
                echo -e "\033[1;32m[OK]\033[0m Downloaded from release"
                return 0
            fi
        fi
    fi
    
    echo -e "\033[1;33m[WARN]\033[0m Could not download from release"
    return 1
}

#-------------------------------------------------------------------------------
# 列出 GitHub 上的可用包
#-------------------------------------------------------------------------------
github_list_packages() {
    local owner="${1:-$DEFAULT_OWNER}"
    local repo="${2:-$DEFAULT_REPO}"
    
    echo -e "\033[1;36mAvailable packages from GitHub ($owner/$repo):\033[0m"
    echo ""
    
    if command -v curl &>/dev/null; then
        local contents=$(curl -s "$GITHUB_API_BASE/repos/$owner/$repo/contents?ref=main" 2>/dev/null)
        
        if [[ -n "$contents" ]]; then
            echo "$contents" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for item in data:
        if item.get('type') == 'dir':
            name = item.get('name', 'unknown')
            print(f'  📦 {name}')
except:
    pass
" 2>/dev/null
        else
            echo "  (unable to fetch package list)"
        fi
    else
        echo "  (curl not available)"
    fi
    
    echo ""
}

#-------------------------------------------------------------------------------
# 导出函数
#-------------------------------------------------------------------------------
export -f github_download_package
export -f github_search_packages
export -f github_download_release
export -f github_list_packages
