#!/bin/bash
#===============================================================================
# NovaScript 调试器
# 支持断点、单步执行、变量检查等功能
#===============================================================================

# 调试状态
NOVA_DEBUG_MODE=false
NOVA_DEBUG_FILE=""
NOVA_DEBUG_LINE=0
NOVA_DEBUG_BREAKPOINTS=()
declare -A NOVA_DEBUG_VARS=()
NOVA_DEBUG_HISTORY=()

#-------------------------------------------------------------------------------
# 启动调试器
#-------------------------------------------------------------------------------
nova_debug() {
    local file="$1"
    shift
    local args=("$@")
    
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file" >&2
        return 1
    fi
    
    NOVA_DEBUG_MODE=true
    NOVA_DEBUG_FILE="$file"
    
    echo "=== NovaScript Debugger ==="
    echo "File: $file"
    echo "Commands: n(ext), s(tep), c(ontinue), b(reak), p(rint), l(ist), q(uit)"
    echo ""
    
    # 读取文件内容
    local -a lines=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        lines+=("$line")
    done < "$file"
    
    local total_lines=${#lines[@]}
    local current_line=0
    
    # 调试循环
    while [[ $current_line -lt $total_lines ]]; do
        local line="${lines[$current_line]}"
        ((current_line++))
        
        # 检查断点
        if nova_debug_is_breakpoint $current_line; then
            echo ""
            echo "Breakpoint at line $current_line"
            nova_debug_prompt "$current_line" "$line"
        fi
        
        # 显示当前行
        echo "[$current_line] $line"
        
        # 等待命令
        read -r -p "(nova) " cmd
        
        case "$cmd" in
            n|next|"")
                # 执行当前行
                nova_debug_execute "$line"
                ;;
            s|step)
                # 单步进入（如果有函数调用）
                if [[ "$line" =~ ([a-zA-Z_][a-zA-Z0-9_]*)\( ]]; then
                    local func="${BASH_REMATCH[1]}"
                    echo "Stepping into: $func"
                fi
                nova_debug_execute "$line"
                ;;
            c|continue)
                # 继续执行直到下一个断点
                while [[ $current_line -lt $total_lines ]]; do
                    if nova_debug_is_breakpoint $current_line; then
                        break
                    fi
                    local exec_line="${lines[$current_line]}"
                    ((current_line++))
                    nova_debug_execute "$exec_line" 2>/dev/null
                done
                ;;
            b|break)
                # 设置断点
                read -r -p "Line number: " bp_line
                nova_debug_add_breakpoint "$bp_line"
                echo "Breakpoint set at line $bp_line"
                ((current_line--))
                ;;
            d|delete)
                # 删除断点
                read -r -p "Line number: " bp_line
                nova_debug_remove_breakpoint "$bp_line"
                echo "Breakpoint removed at line $bp_line"
                ((current_line--))
                ;;
            p|print)
                # 打印变量
                read -r -p "Variable: " var
                nova_debug_print_var "$var"
                ((current_line--))
                ;;
            l|list)
                # 列出代码
                read -r -p "Lines around: " around
                around="${around:-$current_line}"
                nova_debug_list_code "$around" "${lines[@]}"
                ((current_line--))
                ;;
            v|vars)
                # 显示所有变量
                nova_debug_list_vars
                ((current_line--))
                ;;
            h|help|?)
                nova_debug_help
                ((current_line--))
                ;;
            q|quit|exit)
                echo "Debug session ended"
                return 0
                ;;
            *)
                # 尝试执行命令
                if [[ -n "$cmd" ]]; then
                    eval "$cmd" 2>/dev/null || echo "Unknown command: $cmd"
                fi
                ((current_line--))
                ;;
        esac
    done
    
    echo "End of file reached"
}

#-------------------------------------------------------------------------------
# 执行代码行
#-------------------------------------------------------------------------------
nova_debug_execute() {
    local line="$1"
    
    # 跳过空行和注释
    [[ -z "${line// }" ]] && return 0
    [[ "$line" =~ ^[[:space:]]*# ]] && return 0
    
    # 执行
    eval "$line" 2>/dev/null || {
        local err=$?
        if [[ "$NOVA_VERBOSE" == "true" ]]; then
            echo "Error executing line: $err"
        fi
    }
}

#-------------------------------------------------------------------------------
# 断点管理
#-------------------------------------------------------------------------------
nova_debug_add_breakpoint() {
    local line="$1"
    NOVA_DEBUG_BREAKPOINTS+=("$line")
}

nova_debug_remove_breakpoint() {
    local line="$1"
    local new_breakpoints=()
    
    for bp in "${NOVA_DEBUG_BREAKPOINTS[@]}"; do
        [[ "$bp" != "$line" ]] && new_breakpoints+=("$bp")
    done
    
    NOVA_DEBUG_BREAKPOINTS=("${new_breakpoints[@]}")
}

nova_debug_is_breakpoint() {
    local line="$1"
    
    for bp in "${NOVA_DEBUG_BREAKPOINTS[@]}"; do
        [[ "$bp" == "$line" ]] && return 0
    done
    
    return 1
}

nova_debug_clear_breakpoints() {
    NOVA_DEBUG_BREAKPOINTS=()
}

#-------------------------------------------------------------------------------
# 变量检查
#-------------------------------------------------------------------------------
nova_debug_print_var() {
    local var="$1"
    
    # 检查是否是数组
    if [[ -v "$var" ]]; then
        local value="${!var}"
        echo "$var = $value"
        
        # 如果是数组，显示所有元素
        if declare -p "$var" 2>/dev/null | grep -q '^declare -[aA]'; then
            local -n arr="$var"
            for key in "${!arr[@]}"; do
                echo "  [$key] = ${arr[$key]}"
            done
        fi
    else
        echo "$var is not defined"
    fi
}

nova_debug_list_vars() {
    echo "=== Variables ==="
    
    # 显示局部变量
    for var in "${!NOVA_VARS[@]}"; do
        echo "$var = ${NOVA_VARS[$var]}"
    done
    
    # 显示全局变量
    for var in "${!NOVA_FUNCS[@]}"; do
        echo "[func] $var"
    done
}

#-------------------------------------------------------------------------------
# 代码列表
#-------------------------------------------------------------------------------
nova_debug_list_code() {
    local around="$1"
    shift
    local -a lines=("$@")
    
    local start=$((around - 5))
    [[ $start -lt 0 ]] && start=0
    
    local end=$((around + 5))
    [[ $end -gt ${#lines[@]} ]] && end=${#lines[@]}
    
    for ((i=start; i<end; i++)); do
        local marker=" "
        [[ $((i + 1)) -eq $around ]] && marker=">"
        local bp_marker=" "
        nova_debug_is_breakpoint $((i + 1)) && bp_marker="*"
        
        printf "%s%s %3d | %s\n" "$marker" "$bp_marker" $((i + 1)) "${lines[$i]}"
    done
}

#-------------------------------------------------------------------------------
# 调用栈
#-------------------------------------------------------------------------------
nova_debug_print_stack() {
    echo "=== Call Stack ==="
    
    local i=0
    for frame in "${NOVA_CALL_STACK[@]}"; do
        echo "  #$i: $frame"
        ((i++))
    done
    
    if [[ ${#NOVA_CALL_STACK[@]} -eq 0 ]]; then
        echo "  (empty)"
    fi
}

#-------------------------------------------------------------------------------
# 帮助
#-------------------------------------------------------------------------------
nova_debug_help() {
    cat << EOF
Debugger Commands:
  n, next       Execute current line, step over
  s, step       Step into function calls
  c, continue   Continue until next breakpoint
  b, break      Set breakpoint
  d, delete     Delete breakpoint
  p, print      Print variable value
  l, list       List source code
  v, vars       List all variables
  stack         Show call stack
  h, help       Show this help
  q, quit       Quit debugger
EOF
}

#-------------------------------------------------------------------------------
# 调试提示符
#-------------------------------------------------------------------------------
nova_debug_prompt() {
    local line="$1"
    local code="$2"
    
    read -r -p "[$line] (nova) " cmd
    
    case "$cmd" in
        n|next|"") ;;
        s|step) ;;
        c|continue) ;;
        *)
            eval "$cmd" 2>/dev/null || echo "Unknown command"
            ;;
    esac
}

#-------------------------------------------------------------------------------
# 日志调试
#-------------------------------------------------------------------------------
nova_debug_log() {
    local message="$1"
    local level="${2:-INFO}"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >&2
}

#-------------------------------------------------------------------------------
# 性能分析
#-------------------------------------------------------------------------------
nova_debug_profile() {
    local start_time=$(date +%s.%N)
    
    yield
    local result=$?
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")
    
    echo "Execution time: ${duration}s"
    
    return $result
}
