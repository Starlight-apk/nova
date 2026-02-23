#!/bin/bash
#===============================================================================
# NovaScript 解释器核心
# 支持：变量、函数、控制流、模块、异常处理等
#===============================================================================

#-------------------------------------------------------------------------------
# 词法分析器
#-------------------------------------------------------------------------------
nova_tokenize() {
    local input="$1"
    local -n tokens_ref=$2
    local pos=0
    local len=${#input}
    
    while [[ $pos -lt $len ]]; do
        local char="${input:$pos:1}"
        local next_char="${input:$((pos+1)):1}"
        
        # 跳过空白
        if [[ "$char" =~ [[:space:]] ]]; then
            ((pos++))
            continue
        fi
        
        # 注释
        if [[ "$char" == "#" ]]; then
            break
        fi
        
        # 字符串
        if [[ "$char" == '"' ]] || [[ "$char" == "'" ]]; then
            local quote="$char"
            local str=""
            ((pos++))
            while [[ $pos -lt $len ]] && [[ "${input:$pos:1}" != "$quote" ]]; do
                if [[ "${input:$pos:1}" == "\\" ]]; then
                    ((pos++))
                    local escaped="${input:$pos:1}"
                    case "$escaped" in
                        n) str+=$'\n' ;;
                        t) str+=$'\t' ;;
                        r) str+=$'\r' ;;
                        *) str+="$escaped" ;;
                    esac
                else
                    str+="${input:$pos:1}"
                fi
                ((pos++))
            done
            ((pos++))
            tokens_ref+=("STRING:$str")
            continue
        fi
        
        # 数字
        if [[ "$char" =~ [0-9] ]]; then
            local num=""
            while [[ $pos -lt $len ]] && [[ "${input:$pos:1}" =~ [0-9.] ]]; do
                num+="${input:$pos:1}"
                ((pos++))
            done
            tokens_ref+=("NUMBER:$num")
            continue
        fi
        
        # 标识符和关键字
        if [[ "$char" =~ [a-zA-Z_] ]]; then
            local ident=""
            while [[ $pos -lt $len ]] && [[ "${input:$pos:1}" =~ [a-zA-Z0-9_] ]]; do
                ident+="${input:$pos:1}"
                ((pos++))
            done
            tokens_ref+=("IDENT:$ident")
            continue
        fi
        
        # 运算符
        case "$char$next_char" in
            "==") tokens_ref+=("OP:=="); ((pos+=2)); continue ;;
            "!=") tokens_ref+=("OP:!="); ((pos+=2)); continue ;;
            ">=") tokens_ref+=("OP:>="); ((pos+=2)); continue ;;
            "<=") tokens_ref+=("OP:<="); ((pos+=2)); continue ;;
            "&&") tokens_ref+=("OP:&&"); ((pos+=2)); continue ;;
            "||") tokens_ref+=("OP:||"); ((pos+=2)); continue ;;
            "++") tokens_ref+=("OP:++"); ((pos+=2)); continue ;;
            "--") tokens_ref+=("OP:--"); ((pos+=2)); continue ;;
            "+=") tokens_ref+=("OP:+="); ((pos+=2)); continue ;;
            "-=") tokens_ref+=("OP:-="); ((pos+=2)); continue ;;
            "*=") tokens_ref+=("OP:*="); ((pos+=2)); continue ;;
            "/=") tokens_ref+=("OP:/="); ((pos+=2)); continue ;;
        esac
        
        case "$char" in
            "+") tokens_ref+=("OP:+") ;;
            "-") tokens_ref+=("OP:-") ;;
            "*") tokens_ref+=("OP:*") ;;
            "/") tokens_ref+=("OP:/") ;;
            "%") tokens_ref+=("OP:%") ;;
            "=") tokens_ref+=("OP:=") ;;
            ">") tokens_ref+=("OP:>") ;;
            "<") tokens_ref+=("OP:<") ;;
            "!") tokens_ref+=("OP:!") ;;
            "(") tokens_ref+=("LPAREN:(") ;;
            ")") tokens_ref+=("RPAREN:)") ;;
            "{") tokens_ref+=("LBRACE:{") ;;
            "}") tokens_ref+=("RBRACE:}") ;;
            "[") tokens_ref+=("LBRACK:[") ;;
            "]") tokens_ref+=("RBRACK:]") ;;
            ",") tokens_ref+=("COMMA:,") ;;
            ";") tokens_ref+=("SEMICOLON:;") ;;
            ":") tokens_ref+=("COLON::") ;;
            ".") tokens_ref+=("DOT:.") ;;
            *) tokens_ref+=("UNKNOWN:$char") ;;
        esac
        ((pos++))
    done
}

#-------------------------------------------------------------------------------
# 变量管理
#-------------------------------------------------------------------------------
declare -gA NOVA_VARS=()
declare -gA NOVA_FUNCS=()
declare -gA NOVA_MODULES=()
declare -ga NOVA_CALL_STACK=()

nova_set_var() {
    local name="$1"
    local value="$2"
    NOVA_VARS["$name"]="$value"
}

nova_get_var() {
    local name="$1"
    local default="${2:-}"
    echo "${NOVA_VARS[$name]:-$default}"
}

nova_has_var() {
    local name="$1"
    [[ -v NOVA_VARS["$name"] ]]
}

#-------------------------------------------------------------------------------
# 函数定义和执行
#-------------------------------------------------------------------------------
nova_define_func() {
    local name="$1"
    local params="$2"
    local body="$3"
    NOVA_FUNCS["$name"]="$params|$body"
}

nova_call_func() {
    local name="$1"
    shift
    local args=("$@")
    
    if [[ ! -v NOVA_FUNCS["$name"] ]]; then
        echo "Error: Function '$name' not defined" >&2
        return 1
    fi
    
    local func_def="${NOVA_FUNCS[$name]}"
    local params="${func_def%%|*}"
    local body="${func_def#*|}"
    
    # 保存当前作用域
    NOVA_CALL_STACK+=("$name")
    
    # 设置参数
    local i=0
    for param in $params; do
        if [[ $i -lt ${#args[@]} ]]; then
            nova_set_var "$param" "${args[$i]}"
        else
            nova_set_var "$param" ""
        fi
        ((i++))
    done
    
    # 执行函数体
    eval "$body"
    local ret=$?
    
    # 恢复作用域
    unset 'NOVA_CALL_STACK[-1]'
    
    return $ret
}

#-------------------------------------------------------------------------------
# 控制流
#-------------------------------------------------------------------------------
nova_if() {
    local condition="$1"
    local then_block="$2"
    local else_block="${3:-}"
    
    if eval "$condition"; then
        eval "$then_block"
    elif [[ -n "$else_block" ]]; then
        eval "$else_block"
    fi
}

nova_while() {
    local condition="$1"
    local body="$2"
    
    while eval "$condition"; do
        eval "$body"
    done
}

nova_for() {
    local var="$1"
    local range="$2"
    local body="$3"
    
    local start end
    if [[ "$range" =~ ^([0-9]+)\.\.([0-9]+)$ ]]; then
        start="${BASH_REMATCH[1]}"
        end="${BASH_REMATCH[2]}"
    else
        start=0
        end="$range"
    fi
    
    for ((i=start; i<=end; i++)); do
        nova_set_var "$var" "$i"
        eval "$body"
    done
}

nova_for_each() {
    local var="$1"
    local list="$2"
    local body="$3"
    
    for item in $list; do
        nova_set_var "$var" "$item"
        eval "$body"
    done
}

#-------------------------------------------------------------------------------
# 模块系统
#-------------------------------------------------------------------------------
nova_import() {
    local module="$1"
    local alias="${2:-}"
    
    # 处理 std.xxx 格式
    if [[ "$module" =~ ^std\.(.+) ]]; then
        module="${BASH_REMATCH[1]}"
    fi
    
    # 检查是否已加载
    if [[ -v NOVA_MODULES["$module"] ]]; then
        return 0
    fi
    
    # 查找模块文件
    local module_file=""
    local search_paths=(
        "$NOVA_HOME/lib/std"
        "./lib/std"
        "./packages"
        "$NOVA_PACKAGES_DIR"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path/$module.nova" ]]; then
            module_file="$path/$module.nova"
            break
        fi
    done
    
    if [[ -z "$module_file" ]]; then
        echo "Error: Module '$module' not found" >&2
        return 1
    fi
    
    # 加载模块
    NOVA_MODULES["$module"]="$module_file"
    
    # 执行模块（在独立作用域）
    source "$module_file"
    
    return 0
}

#-------------------------------------------------------------------------------
# 异常处理
#-------------------------------------------------------------------------------
nova_try() {
    local try_block="$1"
    local catch_block="${2:-}"
    
    eval "$try_block" 2>/dev/null
    local ret=$?
    
    if [[ $ret -ne 0 ]] && [[ -n "$catch_block" ]]; then
        eval "$catch_block"
    fi
    
    return $ret
}

nova_throw() {
    local message="$1"
    echo "Error: $message" >&2
    return 1
}

#-------------------------------------------------------------------------------
# 解释器主循环
#-------------------------------------------------------------------------------
nova_interpret() {
    local file="$1"
    shift
    local args=("$@")
    
    # 设置命令行参数
    export NOVA_SCRIPT_ARGS=("${args[@]}")
    export NOVA_ARGC=${#args[@]}
    
    # 读取文件
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi
    
    local content
    content=$(cat "$file")
    
    # 预处理器指令
    content=$(nova_preprocess "$content")
    
    # 解析并执行
    nova_execute "$content"
}

nova_preprocess() {
    local content="$1"
    
    # 处理 @include 指令
    while [[ "$content" =~ @include[[:space:]]+\"([^\"]+)\" ]]; do
        local include_file="${BASH_REMATCH[1]}"
        local include_content=""
        if [[ -f "$include_file" ]]; then
            include_content=$(cat "$include_file")
        fi
        content="${content/@include \"$include_file\"/$include_content}"
    done
    
    # 处理 @define 指令
    while [[ "$content" =~ @define[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]+(.+) ]]; do
        local def_name="${BASH_REMATCH[1]}"
        local def_value="${BASH_REMATCH[2]}"
        content="${content//@$def_name/$def_value}"
    done
    
    echo "$content"
}

nova_execute() {
    local content="$1"
    
    # 移除注释（保留 shebang）
    content=$(echo "$content" | sed 's/^[^#]*#/;#/' | sed 's/;#//g')
    
    # 处理 import 语句
    while IFS= read -r line; do
        if [[ "$line" =~ ^import[[:space:]]+([a-zA-Z_][a-zA-Z0-9_.]*) ]]; then
            local module="${BASH_REMATCH[1]}"
            nova_import "$module"
        fi
    done <<< "$content"
    
    # 处理 func 定义 - 转换为 bash 函数
    local temp_content="$content"
    temp_content=$(echo "$temp_content" | sed 's/^func /nova_func_/' )
    
    # 直接执行内容
    eval "$temp_content" 2>/dev/null || {
        # 如果 eval 失败，尝试直接执行原始内容
        eval "$content"
    }
}

#-------------------------------------------------------------------------------
# 内置函数
#-------------------------------------------------------------------------------
nova_builtin_print() {
    printf "%s\n" "$*"
}

nova_builtin_input() {
    local prompt="${1:-}"
    local var_name="${2:-REPLY}"
    
    if [[ -n "$prompt" ]]; then
        printf "%s" "$prompt"
    fi
    read -r "$var_name"
}

nova_builtin_exit() {
    local code="${1:-0}"
    exit "$code"
}

nova_builtin_len() {
    local str="$1"
    echo "${#str}"
}

nova_builtin_substr() {
    local str="$1"
    local start="$2"
    local len="${3:-${#str}}"
    echo "${str:$start:$len}"
}

nova_builtin_split() {
    local str="$1"
    local delim="${2:- }"
    echo "$str" | tr "$delim" '\n'
}

nova_builtin_join() {
    local delim="$1"
    shift
    local arr=("$@")
    local IFS="$delim"
    echo "${arr[*]}"
}

nova_builtin_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

nova_builtin_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

nova_builtin_trim() {
    local str="$1"
    str="${str#"${str%%[![:space:]]*}"}"
    str="${str%"${str##*[![:space:]]}"}"
    echo "$str"
}

nova_builtin_replace() {
    local str="$1"
    local old="$2"
    local new="$3"
    echo "${str//$old/$new}"
}

nova_builtin_contains() {
    local str="$1"
    local substr="$2"
    [[ "$str" == *"$substr"* ]] && echo "true" || echo "false"
}

nova_builtin_type() {
    local val="$1"
    if [[ "$val" =~ ^-?[0-9]+$ ]]; then
        echo "int"
    elif [[ "$val" =~ ^-?[0-9]+\.[0-9]+$ ]]; then
        echo "float"
    elif [[ "$val" == "true" ]] || [[ "$val" == "false" ]]; then
        echo "bool"
    else
        echo "string"
    fi
}

nova_builtin_rand() {
    local max="${1:-100}"
    echo $((RANDOM % max))
}

nova_builtin_time() {
    date +%s
}

nova_builtin_date() {
    local format="${1:-%Y-%m-%d %H:%M:%S}"
    date +"$format"
}

#-------------------------------------------------------------------------------
# 注册内置函数到解释器
#-------------------------------------------------------------------------------
export -f nova_builtin_print
export -f nova_builtin_input
export -f nova_builtin_exit
export -f nova_builtin_len
export -f nova_builtin_substr
export -f nova_builtin_split
export -f nova_builtin_join
export -f nova_builtin_upper
export -f nova_builtin_lower
export -f nova_builtin_trim
export -f nova_builtin_replace
export -f nova_builtin_contains
export -f nova_builtin_type
export -f nova_builtin_rand
export -f nova_builtin_time
export -f nova_builtin_date
