#!/bin/bash
#===============================================================================
# NovaScript 参数解析模块
# 支持多种参数格式和选项
#===============================================================================

# 存储解析结果
declare -ga NOVA_ARGS=()
declare -gA NOVA_OPTS=()
declare -gA NOVA_FLAGS=()

#-------------------------------------------------------------------------------
# 参数解析
#-------------------------------------------------------------------------------
parse_args() {
    local positional=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            # 长选项带值 --option=value
            --*=*)
                local key="${1%%=*}"
                local value="${1#*=}"
                key="${key#--}"
                NOVA_OPTS["$key"]="$value"
                shift
                ;;
            
            # 长选项带值 --option value
            --*)
                local key="${1#--}"
                if [[ $# -gt 1 ]] && [[ ! "$2" =~ ^- ]]; then
                    NOVA_OPTS["$key"]="$2"
                    shift 2
                else
                    NOVA_FLAGS["$key"]="true"
                    shift
                fi
                ;;
            
            # 短选项带值 -o=value 或 -o value
            -[a-zA-Z]=*)
                local key="${1%%=*}"
                local value="${1#*=}"
                key="${key#-}"
                NOVA_OPTS["$key"]="$value"
                shift
                ;;
            
            # 短选项带值 -o value
            -[a-zA-Z])
                local key="${1#-}"
                if [[ $# -gt 1 ]] && [[ ! "$2" =~ ^- ]]; then
                    NOVA_OPTS["$key"]="$2"
                    shift 2
                else
                    NOVA_FLAGS["$key"]="true"
                    shift
                fi
                ;;
            
            # 组合短选项 -abc
            -[a-zA-Z]*)
                local key="${1#-}"
                for ((i=0; i<${#key}; i++)); do
                    local char="${key:$i:1}"
                    NOVA_FLAGS["$char"]="true"
                done
                shift
                ;;
            
            # 位置参数
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done
    
    # 处理语言选项
    if [[ -v NOVA_OPTS["lang"] ]] || [[ -v NOVA_OPTS["l"] ]]; then
        local lang="${NOVA_OPTS[lang]:-${NOVA_OPTS[l]:-en}}"
        export NOVA_LANG="$lang"
    fi
    
    # 处理调试标志
    if [[ "${NOVA_FLAGS[d]:-}" == "true" ]] || [[ "${NOVA_FLAGS[debug]:-}" == "true" ]]; then
        export NOVA_DEBUG="true"
    fi
    
    # 处理安静模式
    if [[ "${NOVA_FLAGS[q]:-}" == "true" ]] || [[ "${NOVA_FLAGS[quiet]:-}" == "true" ]]; then
        export NOVA_QUIET="true"
    fi
    
    # 处理详细模式
    if [[ "${NOVA_FLAGS[V]:-}" == "true" ]] || [[ "${NOVA_FLAGS[verbose]:-}" == "true" ]]; then
        export NOVA_VERBOSE="true"
    fi
    
    # 处理优化标志
    if [[ "${NOVA_FLAGS[O]:-}" == "true" ]] || [[ "${NOVA_FLAGS[optimize]:-}" == "true" ]]; then
        export NOVA_OPTIMIZE="true"
    fi
    
    # 存储位置参数
    if [[ ${#positional[@]} -gt 0 ]]; then
        NOVA_COMMAND="${positional[0]}"
        NOVA_ARGS=("${positional[@]:1}")
    else
        NOVA_COMMAND="help"
        NOVA_ARGS=()
    fi
}

#-------------------------------------------------------------------------------
# 获取选项值
#-------------------------------------------------------------------------------
get_opt() {
    local key="$1"
    local default="${2:-}"
    echo "${NOVA_OPTS[$key]:-$default}"
}

#-------------------------------------------------------------------------------
# 检查标志
#-------------------------------------------------------------------------------
has_flag() {
    local key="$1"
    [[ "${NOVA_FLAGS[$key]:-}" == "true" ]]
}

#-------------------------------------------------------------------------------
# 获取位置参数
#-------------------------------------------------------------------------------
get_arg() {
    local index="$1"
    local default="${2:-}"
    echo "${NOVA_ARGS[$index]:-$default}"
}

#-------------------------------------------------------------------------------
# 获取所有位置参数
#-------------------------------------------------------------------------------
get_all_args() {
    echo "${NOVA_ARGS[@]}"
}

#-------------------------------------------------------------------------------
# 获取所有选项
#-------------------------------------------------------------------------------
get_all_opts() {
    for key in "${!NOVA_OPTS[@]}"; do
        echo "--$key=${NOVA_OPTS[$key]}"
    done
}

#-------------------------------------------------------------------------------
# 获取所有标志
#-------------------------------------------------------------------------------
get_all_flags() {
    for key in "${!NOVA_FLAGS[@]}"; do
        echo "--$key"
    done
}

#-------------------------------------------------------------------------------
# 验证必需参数
#-------------------------------------------------------------------------------
require_args() {
    local count="$1"
    if [[ ${#NOVA_ARGS[@]} -lt $count ]]; then
        echo "Error: Expected at least $count argument(s), got ${#NOVA_ARGS[@]}" >&2
        return 1
    fi
    return 0
}

#-------------------------------------------------------------------------------
# 验证必需选项
#-------------------------------------------------------------------------------
require_opt() {
    local key="$1"
    if [[ ! -v NOVA_OPTS["$key"] ]]; then
        echo "Error: Required option --$key is missing" >&2
        return 1
    fi
    return 0
}

#-------------------------------------------------------------------------------
# 参数类型验证
#-------------------------------------------------------------------------------
validate_type() {
    local value="$1"
    local type="$2"
    
    case "$type" in
        int|integer)
            [[ "$value" =~ ^-?[0-9]+$ ]]
            ;;
        float|number)
            [[ "$value" =~ ^-?[0-9]+\.?[0-9]*$ ]]
            ;;
        file)
            [[ -f "$value" ]]
            ;;
        dir|directory)
            [[ -d "$value" ]]
            ;;
        path)
            [[ -e "$value" ]]
            ;;
        url)
            [[ "$value" =~ ^https?:// ]]
            ;;
        email)
            [[ "$value" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
            ;;
        *)
            return 0
            ;;
    esac
}

#-------------------------------------------------------------------------------
# 带类型验证的参数获取
#-------------------------------------------------------------------------------
get_opt_typed() {
    local key="$1"
    local type="$2"
    local default="${3:-}"
    
    local value="${NOVA_OPTS[$key]:-$default}"
    
    if [[ -n "$value" ]] && ! validate_type "$value" "$type"; then
        echo "Error: Option --$key must be of type $type" >&2
        return 1
    fi
    
    echo "$value"
}

#-------------------------------------------------------------------------------
# 枚举参数解析
#-------------------------------------------------------------------------------
parse_enum() {
    local value="$1"
    shift
    local valid_values=("$@")
    
    for valid in "${valid_values[@]}"; do
        if [[ "$value" == "$valid" ]]; then
            echo "$value"
            return 0
        fi
    done
    
    echo "Error: Invalid value '$value'. Valid values: ${valid_values[*]}" >&2
    return 1
}

#-------------------------------------------------------------------------------
# 列表参数解析
#-------------------------------------------------------------------------------
parse_list() {
    local input="$1"
    local delimiter="${2:-,}"
    
    echo "$input" | tr "$delimiter" '\n'
}

#-------------------------------------------------------------------------------
# 范围参数解析 (e.g., 1-10)
#-------------------------------------------------------------------------------
parse_range() {
    local input="$1"
    
    if [[ "$input" =~ ^([0-9]+)-([0-9]+)$ ]]; then
        local start="${BASH_REMATCH[1]}"
        local end="${BASH_REMATCH[2]}"
        
        for ((i=start; i<=end; i++)); do
            echo "$i"
        done
    else
        echo "$input"
    fi
}

#-------------------------------------------------------------------------------
# 键值对参数解析
#-------------------------------------------------------------------------------
parse_keyvalue() {
    local input="$1"
    local delimiter="${2:-=}"
    
    if [[ "$input" =~ ^([^$delimiter]+)$delimiter(.+)$ ]]; then
        local key="${BASH_REMATCH[1]}"
        local value="${BASH_REMATCH[2]}"
        echo "$key"
        echo "$value"
    else
        echo "$input"
        echo ""
    fi
}
