#!/bin/bash
#===============================================================================
# NovaScript Runtime Environment
# 运行时环境 - 提供类似 Python/Node.js 的完整能力
#===============================================================================

set -euo pipefail

declare -g NOVA_RUNTIME_VERSION="2.0.0"
declare -gA NOVA_CONFIG=(
    [debug]=false
    [strict]=true
    [verbose]=false
    [max_memory]=512M
)

declare -gA __NOVA_VARS=()
declare -gA __NOVA_FUNCS=()
declare -gA __NOVA_MODULES=()
declare -ga __NOVA_CALL_STACK=()
declare -gA __NOVA_IMPORTS=()
declare -g __NOVA_RETVAL=""
declare -g __NOVA_ERRMSG=""

__nova_log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        DEBUG) [[ "${NOVA_CONFIG[debug]}" == "true" ]] && echo "[$timestamp] [DEBUG] $msg" ;;
        INFO)  echo "[$timestamp] [INFO] $msg" ;;
        WARN)  echo "[$timestamp] [WARN] $msg" >&2 ;;
        ERROR) echo "[$timestamp] [ERROR] $msg" >&2 ;;
    esac
}

nova_log_debug() { __nova_log DEBUG "$@"; }
nova_log_info()  { __nova_log INFO "$@"; }
nova_log_warn()  { __nova_log WARN "$@"; }
nova_log_error() { __nova_log ERROR "$@"; }

nova_var_set() {
    local name="$1"
    local value="${2:-}"
    local scope="${3:-global}"
    
    if [[ "$scope" == "local" ]]; then
        printf -v "$name" '%s' "$value"
    else
        __NOVA_VARS["$name"]="$value"
    fi
}

nova_var_get() {
    local name="$1"
    local default="${2:-}"
    
    if [[ -v "$name" ]]; then
        printf '%s' "${!name}"
    elif [[ -v __NOVA_VARS["$name"] ]]; then
        printf '%s' "${__NOVA_VARS[$name]}"
    else
        printf '%s' "$default"
    fi
}

nova_var_exists() {
    local name="$1"
    [[ -v "$name" ]] || [[ -v __NOVA_VARS["$name"] ]]
}

nova_var_delete() {
    local name="$1"
    unset "$name" 2>/dev/null || true
    unset "__NOVA_VARS[$name]" 2>/dev/null || true
}

nova_type_of() {
    local val="$1"
    
    if [[ "$val" =~ ^-?[0-9]+$ ]]; then
        echo "integer"
    elif [[ "$val" =~ ^-?[0-9]+\.[0-9]+$ ]]; then
        echo "float"
    elif [[ "$val" == "true" ]] || [[ "$val" == "false" ]]; then
        echo "boolean"
    elif [[ "$val" == "null" ]] || [[ -z "$val" ]]; then
        echo "null"
    else
        echo "string"
    fi
}

nova_func_define() {
    local name="$1"
    local params="$2"
    local body="$3"
    __NOVA_FUNCS["$name"]="$params|$body"
}

nova_func_call() {
    local func_name="$1"
    shift
    local args=("$@")
    
    if [[ ! -v __NOVA_FUNCS["$func_name"] ]]; then
        __NOVA_ERRMSG="Function '$func_name' not defined"
        return 1
    fi
    
    local func_def="${__NOVA_FUNCS[$func_name]}"
    local params="${func_def%%|*}"
    local body="${func_def#*|}"
    
    __NOVA_CALL_STACK+=("$func_name")
    
    local i=0
    for param in $params; do
        if [[ $i -lt ${#args[@]} ]]; then
            nova_var_set "$param" "${args[$i]}" "local"
        else
            nova_var_set "$param" "" "local"
        fi
        ((i++))
    done
    
    eval "$body"
    local ret=$?
    
    unset '__NOVA_CALL_STACK[-1]' 2>/dev/null || true
    return $ret
}

nova_module_require() {
    local module_path="$1"
    
    if [[ -v __NOVA_IMPORTS["$module_path"] ]]; then
        return 0
    fi
    
    local module_file=""
    local search_paths=("$NOVA_HOME/lib" "$NOVA_HOME/src" "./lib" "./src" "$PWD")
    local extensions=(".sh" ".nova" "")
    
    for base_path in "${search_paths[@]}"; do
        for ext in "${extensions[@]}"; do
            local test_path="$base_path/$module_path$ext"
            if [[ -f "$test_path" ]]; then
                module_file="$test_path"
                break 2
            fi
        done
    done
    
    if [[ -z "$module_file" ]]; then
        __NOVA_ERRMSG="Module '$module_path' not found"
        return 1
    fi
    
    __NOVA_IMPORTS["$module_path"]="$module_file"
    source "$module_file"
    nova_log_debug "Loaded module: $module_path"
    return 0
}

nova_try() {
    local try_block="$1"
    local catch_block="${2:-}"
    local finally_block="${3:-}"
    local result=0
    
    eval "$try_block" 2>/dev/null
    result=$?
    
    if [[ $result -ne 0 ]] && [[ -n "$catch_block" ]]; then
        __NOVA_ERRMSG="Error in try block (exit code: $result)"
        eval "$catch_block"
    fi
    
    if [[ -n "$finally_block" ]]; then
        eval "$finally_block"
    fi
    return $result
}

nova_throw() {
    local message="${1:-Unknown error}"
    local code="${2:-1}"
    __NOVA_ERRMSG="$message"
    nova_log_error "Exception: $message"
    return "$code"
}

nova_str_len() { printf '%s' "${#1}"; }
nova_str_upper() { printf '%s' "${1^^}"; }
nova_str_lower() { printf '%s' "${1,,}"; }
nova_str_trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }
nova_str_reverse() { printf '%s' "$1" | rev; }
nova_str_substr() { printf '%s' "${1:$2:$3}"; }
nova_str_repeat() { local s="$1" n="$2" r=""; for ((i=0;i<n;i++)); do r+="$s"; done; printf '%s' "$r"; }
nova_str_contains() { [[ "$1" == *"$2"* ]] && echo "true" || echo "false"; }
nova_str_starts() { [[ "$1" == "$2"* ]] && echo "true" || echo "false"; }
nova_str_ends() { [[ "$1" == *"$2" ]] && echo "true" || echo "false"; }

nova_str_index() {
    local str="$1" substr="$2"
    local temp="${str%%$substr*}"
    if [[ "$temp" == "$str" ]]; then
        echo "-1"
    else
        echo "${#temp}"
    fi
}

nova_str_replace() {
    local str="$1" old="$2" new="$3"
    printf '%s' "${str//$old/$new}"
}

nova_str_split() {
    local str="$1" delim="${2:- }"
    echo "$str" | tr "$delim" '\n'
}

nova_str_join() {
    local delim="$1"
    shift
    local arr=("$@")
    local IFS="$delim"
    printf '%s' "${arr[*]}"
}

nova_arr_push() {
    local -n arr_ref="$1"
    shift
    arr_ref+=("$@")
}

nova_arr_pop() {
    local -n arr_ref="$1"
    if [[ ${#arr_ref[@]} -gt 0 ]]; then
        unset 'arr_ref[-1]'
    fi
}

nova_arr_shift() {
    local -n arr_ref="$1"
    if [[ ${#arr_ref[@]} -gt 0 ]]; then
        arr_ref=("${arr_ref[@]:1}")
    fi
}

nova_arr_unshift() {
    local -n arr_ref="$1"
    shift
    local new_items=("$@")
    arr_ref=("${new_items[@]}" "${arr_ref[@]}")
}

nova_arr_len() {
    local -n arr_ref="$1"
    echo "${#arr_ref[@]}"
}

nova_arr_get() {
    local -n arr_ref="$1"
    local idx="$2"
    printf '%s' "${arr_ref[$idx]}"
}

nova_arr_set() {
    local -n arr_ref="$1"
    local idx="$2"
    local val="$3"
    arr_ref[$idx]="$val"
}

nova_math_add() { echo $((${1//./} + ${2//./})); }
nova_math_sub() { echo $((${1//./} - ${2//./})); }
nova_math_mul() { echo $((${1//./} * ${2//./})); }
nova_math_div() { echo "scale=2; ${1}/${2}" | bc 2>/dev/null || echo "0"; }
nova_math_mod() { echo $((${1//./} % ${2//./})); }
nova_math_pow() { echo "$((${1//./} ** ${2//./}))"; }
nova_math_sqrt() { echo "scale=2; sqrt($1)" | bc 2>/dev/null || echo "0"; }
nova_math_abs() { local n="$1"; [[ $n -lt 0 ]] && echo $((-n)) || echo "$n"; }
nova_math_min() { local a="$1" b="$2"; [[ $a -lt $b ]] && echo "$a" || echo "$b"; }
nova_math_max() { local a="$1" b="$2"; [[ $a -gt $b ]] && echo "$a" || echo "$b"; }
nova_math_floor() { printf '%d' "$1"; }
nova_math_round() { printf "%.0f" "$1"; }
nova_math_rand() { local max="${1:-100}"; echo $((RANDOM % max)); }
nova_math_pi() { echo "3.14159265359"; }

nova_print() {
    local format="${1:-%s}"
    shift
    printf "$format\n" "$@"
}

nova_print_raw() { printf '%s' "$*"; }

nova_input() {
    local prompt="${1:-}"
    local var_name="${2:-REPLY}"
    if [[ -n "$prompt" ]]; then
        printf "%s" "$prompt"
    fi
    read -r "$var_name"
}

nova_read_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cat "$file"
    else
        __NOVA_ERRMSG="File not found: $file"
        return 1
    fi
}

nova_write_file() {
    local file="$1"
    local content="$2"
    local append="${3:-false}"
    if [[ "$append" == "true" ]]; then
        echo "$content" >> "$file"
    else
        echo "$content" > "$file"
    fi
}

nova_sys_os() { uname -s; }
nova_sys_arch() { uname -m; }
nova_sys_hostname() { hostname 2>/dev/null || echo "unknown"; }
nova_sys_user() { echo "${USER:-$(whoami)}"; }
nova_sys_pwd() { pwd; }
nova_sys_home() { echo "$HOME"; }
nova_sys_pid() { echo $$; }

nova_sys_exec() {
    local cmd="$*"
    eval "$cmd"
}

nova_sys_env_get() {
    local var="$1"
    printf '%s' "${!var:-}"
}

nova_sys_env_set() { export "$1"="$2"; }
nova_sys_env_unset() { unset "$1"; }

nova_json_parse() {
    local json_str="$1"
    if command -v jq &>/dev/null; then
        echo "$json_str" | jq -r '.'
    elif command -v python3 &>/dev/null; then
        echo "$json_str" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)))"
    else
        echo "$json_str"
    fi
}

nova_json_get() {
    local json="$1"
    local key="$2"
    if command -v jq &>/dev/null; then
        echo "$json" | jq -r ".$key"
    elif command -v python3 &>/dev/null; then
        echo "$json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$key',''))"
    else
        echo ""
    fi
}

nova_http_get() {
    local url="$1"
    if command -v curl &>/dev/null; then
        curl -s "$url"
    elif command -v wget &>/dev/null; then
        wget -qO- "$url"
    else
        __NOVA_ERRMSG="Neither curl nor wget available"
        return 1
    fi
}

nova_http_post() {
    local url="$1"
    local data="$2"
    local content_type="${3:-application/json}"
    if command -v curl &>/dev/null; then
        curl -s -X POST -H "Content-Type: $content_type" -d "$data" "$url"
    else
        __NOVA_ERRMSG="curl not available"
        return 1
    fi
}

nova_time_now() { date +%s; }
nova_time_ms() { date +%s%3N; }
nova_date_today() { date +%Y-%m-%d; }
nova_date_iso() { date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z; }

nova_date_format() {
    local timestamp="${1:-$(date +%s)}"
    local format="${2:-%Y-%m-%d %H:%M:%S}"
    date -d "@$timestamp" +"$format" 2>/dev/null || date -r "$timestamp" +"$format" 2>/dev/null || echo "$timestamp"
}

nova_inspect() {
    local name="$1"
    local value="${2:-}"
    echo "========================================"
    echo "Variable: $name"
    echo "Type:     $(nova_type_of "$value")"
    echo "Value:    $value"
    echo "========================================"
}

nova_trace() {
    local msg="${1:-Trace point}"
    local line="${2:-${BASH_LINENO[0]:-unknown}}"
    echo "[TRACE] $msg (line: $line)"
}

nova_runtime_init() {
    nova_log_info "NovaScript Runtime v$NOVA_RUNTIME_VERSION initialized"
    nova_log_debug "Platform: $(nova_sys_os)/$(nova_sys_arch)"
    nova_log_debug "Bash version: $BASH_VERSION"
}

export -f nova_log_debug nova_log_info nova_log_warn nova_log_error
export -f nova_var_set nova_var_get nova_var_exists nova_var_delete
export -f nova_type_of
export -f nova_func_define nova_func_call
export -f nova_module_require
export -f nova_try nova_throw
export -f nova_str_len nova_str_upper nova_str_lower nova_str_trim
export -f nova_str_contains nova_str_starts nova_str_ends nova_str_index
export -f nova_str_replace nova_str_split nova_str_join nova_str_repeat
export -f nova_arr_push nova_arr_pop nova_arr_shift nova_arr_unshift
export -f nova_arr_len nova_arr_get nova_arr_set
export -f nova_math_add nova_math_sub nova_math_mul nova_math_div nova_math_mod
export -f nova_math_pow nova_math_sqrt nova_math_abs nova_math_min nova_math_max
export -f nova_print nova_print_raw nova_input nova_read_file nova_write_file
export -f nova_sys_os nova_sys_arch nova_sys_hostname nova_sys_user
export -f nova_sys_exec nova_sys_env_get nova_sys_env_set nova_sys_env_unset
export -f nova_json_parse nova_json_get
export -f nova_http_get nova_http_post
export -f nova_time_now nova_time_ms nova_date_today nova_date_iso
export -f nova_date_format
export -f nova_inspect nova_trace
export -f nova_runtime_init
