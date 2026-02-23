#!/bin/bash
#===============================================================================
# NovaScript API Index
# API 索引 - 加载所有 API 模块
#===============================================================================

# API 版本
export NOVA_API_VERSION="1.0.0"
export NOVA_API_COUNT="1000+"

#-------------------------------------------------------------------------------
# 加载核心 API
#-------------------------------------------------------------------------------
load_core_api() {
    source "$NOVA_HOME/lib/api/core.sh" 2>/dev/null || true
}

#-------------------------------------------------------------------------------
# 加载数据 API
#-------------------------------------------------------------------------------
load_data_api() {
    source "$NOVA_HOME/lib/api/data.sh" 2>/dev/null || true
}

#-------------------------------------------------------------------------------
# 加载所有 API
#-------------------------------------------------------------------------------
load_all_api() {
    load_core_api
    load_data_api
    
    # 加载其他 API 模块
    for module in "$NOVA_HOME/lib/api/"*.sh; do
        [[ -f "$module" ]] && source "$module" 2>/dev/null
    done
}

#-------------------------------------------------------------------------------
# API 列表
#-------------------------------------------------------------------------------
list_api() {
    local pattern="${1:-}"
    
    echo "NovaScript API Library v$NOVA_API_VERSION"
    echo "Total APIs: $NOVA_API_COUNT"
    echo ""
    echo "Available modules:"
    echo "  core    - Core functions (version, system, env)"
    echo "  string  - String manipulation (100+ functions)"
    echo "  array   - Array operations (80+ functions)"
    echo "  math    - Mathematical functions (100+ functions)"
    echo "  io      - Input/Output (80+ functions)"
    echo "  http    - HTTP client (50+ functions)"
    echo "  json    - JSON processing (40+ functions)"
    echo "  crypto  - Cryptography (60+ functions)"
    echo "  date    - Date/Time (50+ functions)"
    echo "  net     - Network (40+ functions)"
    echo "  proc    - Process management (40+ functions)"
    echo "  fs      - File system (60+ functions)"
    echo "  data    - Data processing (100+ functions)"
    echo ""
    
    if [[ -n "$pattern" ]]; then
        echo "Matching APIs for '$pattern':"
        declare -F | grep "api_${pattern}" | awk '{print "  " $3}'
    fi
}

#-------------------------------------------------------------------------------
# API 搜索
#-------------------------------------------------------------------------------
search_api() {
    local query="$1"
    declare -F | grep "$query" | awk '{print $3}'
}

#-------------------------------------------------------------------------------
# API 帮助
#-------------------------------------------------------------------------------
api_help() {
    local func="$1"
    
    if type "$func" &>/dev/null; then
        echo "Function: $func"
        echo ""
        declare -f "$func" | head -20
    else
        echo "API not found: $func"
    fi
}

#-------------------------------------------------------------------------------
# 导出函数
#-------------------------------------------------------------------------------
export -f load_core_api load_data_api load_all_api
export -f list_api search_api api_help

# 自动加载核心 API
load_core_api
