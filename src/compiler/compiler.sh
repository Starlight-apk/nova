#!/bin/bash
#===============================================================================
# NovaScript 编译器模块
# 将 .nova 文件编译为字节码 (.nbc) 以提高执行性能
#===============================================================================

#-------------------------------------------------------------------------------
# 字节码格式
# NBC_MAGIC: "NBC\x01" (4 bytes)
# Version: 1 byte
# Flags: 1 byte
# Constants count: 2 bytes
# Instructions: variable
# Constants: variable
#-------------------------------------------------------------------------------

NBC_MAGIC=$'NBC\x01'
NBC_VERSION=1

# 指令集
declare -A NBC_OPCODES=(
    ["NOP"]=0x00
    ["LOAD_CONST"]=0x01
    ["LOAD_VAR"]=0x02
    ["STORE_VAR"]=0x03
    ["LOAD_GLOBAL"]=0x04
    ["STORE_GLOBAL"]=0x05
    ["ADD"]=0x10
    ["SUB"]=0x11
    ["MUL"]=0x12
    ["DIV"]=0x13
    ["MOD"]=0x14
    ["POW"]=0x15
    ["EQ"]=0x20
    ["NE"]=0x21
    ["LT"]=0x22
    ["LE"]=0x23
    ["GT"]=0x24
    ["GE"]=0x25
    ["JUMP"]=0x30
    ["JUMP_IF_FALSE"]=0x31
    ["JUMP_IF_TRUE"]=0x32
    ["CALL"]=0x40
    ["RETURN"]=0x41
    ["PRINT"]=0x42
    ["INPUT"]=0x43
    ["POP"]=0x50
    ["DUP"]=0x51
    ["SWAP"]=0x52
    ["HALT"]=0xFF
)

#-------------------------------------------------------------------------------
# 编译文件
#-------------------------------------------------------------------------------
nova_compile() {
    local input_file="$1"
    local output_file="$2"
    local optimize="${3:-false}"
    
    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file not found: $input_file" >&2
        return 1
    fi
    
    echo "Compiling: $input_file -> $output_file"
    
    # 读取并解析源代码
    local source
    source=$(cat "$input_file")
    
    # 词法分析
    local -a tokens=()
    nova_tokenize_source "$source" tokens
    
    # 语法分析并生成字节码
    local -a bytecode=()
    local -a constants=()
    
    nova_generate_bytecode tokens bytecode constants "$optimize"
    
    # 写入字节码文件
    nova_write_bytecode "$output_file" bytecode constants
    
    echo "Compilation completed: $output_file"
    return 0
}

#-------------------------------------------------------------------------------
# 词法分析
#-------------------------------------------------------------------------------
nova_tokenize_source() {
    local source="$1"
    local -n tokens_ref=$2
    
    local line_num=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        # 跳过空行和注释
        [[ -z "${line// }" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        
        # 移除行内注释
        line="${line%%#*}"
        
        # 简单的词法分析
        local pos=0
        local len=${#line}
        
        while [[ $pos -lt $len ]]; do
            local char="${line:$pos:1}"
            
            # 跳过空白
            if [[ "$char" =~ [[:space:]] ]]; then
                ((pos++))
                continue
            fi
            
            # 字符串
            if [[ "$char" == '"' ]] || [[ "$char" == "'" ]]; then
                local quote="$char"
                local str=""
                ((pos++))
                while [[ $pos -lt $len ]] && [[ "${line:$pos:1}" != "$quote" ]]; do
                    str+="${line:$pos:1}"
                    ((pos++))
                done
                ((pos++))
                tokens_ref+=("STRING:$str")
                continue
            fi
            
            # 数字
            if [[ "$char" =~ [0-9] ]]; then
                local num=""
                while [[ $pos -lt $len ]] && [[ "${line:$pos:1}" =~ [0-9.] ]]; do
                    num+="${line:$pos:1}"
                    ((pos++))
                done
                tokens_ref+=("NUMBER:$num")
                continue
            fi
            
            # 标识符和关键字
            if [[ "$char" =~ [a-zA-Z_] ]]; then
                local ident=""
                while [[ $pos -lt $len ]] && [[ "${line:$pos:1}" =~ [a-zA-Z0-9_] ]]; do
                    ident+="${line:$pos:1}"
                    ((pos++))
                done
                
                # 检查关键字
                case "$ident" in
                    func) tokens_ref+=("KEYWORD:FUNC") ;;
                    import) tokens_ref+=("KEYWORD:IMPORT") ;;
                    if) tokens_ref+=("KEYWORD:IF") ;;
                    else) tokens_ref+=("KEYWORD:ELSE") ;;
                    elif) tokens_ref+=("KEYWORD:ELIF") ;;
                    while) tokens_ref+=("KEYWORD:WHILE") ;;
                    for) tokens_ref+=("KEYWORD:FOR") ;;
                    in) tokens_ref+=("KEYWORD:IN") ;;
                    return) tokens_ref+=("KEYWORD:RETURN") ;;
                    break) tokens_ref+=("KEYWORD:BREAK") ;;
                    continue) tokens_ref+=("KEYWORD:CONTINUE") ;;
                    true|false) tokens_ref+=("BOOL:$ident") ;;
                    *) tokens_ref+=("IDENT:$ident") ;;
                esac
                continue
            fi
            
            # 运算符和符号
            case "$char" in
                "=") 
                    if [[ "${line:$((pos+1)):1}" == "=" ]]; then
                        tokens_ref+=("OP:==")
                        ((pos++))
                    else
                        tokens_ref+=("OP:=")
                    fi
                    ;;
                "+") tokens_ref+=("OP:+") ;;
                "-") tokens_ref+=("OP:-") ;;
                "*") tokens_ref+=("OP:*") ;;
                "/") tokens_ref+=("OP:/") ;;
                "%") tokens_ref+=("OP:%") ;;
                "<") tokens_ref+=("OP:<") ;;
                ">") tokens_ref+=("OP:>") ;;
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
        
        tokens_ref+=("NEWLINE:\n")
    done <<< "$source"
}

#-------------------------------------------------------------------------------
# 生成字节码
#-------------------------------------------------------------------------------
nova_generate_bytecode() {
    local -n tokens_in=$1
    local -n bytecode_out=$2
    local -n constants_out=$3
    local optimize="$4"
    
    local pos=0
    local total=${#tokens_in[@]}
    
    while [[ $pos -lt $total ]]; do
        local token="${tokens_in[$pos]}"
        local type="${token%%:*}"
        local value="${token#*:}"
        
        case "$type" in
            KEYWORD)
                case "$value" in
                    FUNC)
                        # 处理函数定义
                        bytecode_out+=("${NBC_OPCODES[NOP]}")
                        ;;
                    IMPORT)
                        # 处理导入
                        bytecode_out+=("${NBC_OPCODES[NOP]}")
                        ;;
                esac
                ;;
            IDENT)
                bytecode_out+=("${NBC_OPCODES[LOAD_GLOBAL]}")
                constants_out+=("$value")
                ;;
            STRING)
                bytecode_out+=("${NBC_OPCODES[LOAD_CONST]}")
                constants_out+=("$value")
                ;;
            NUMBER)
                bytecode_out+=("${NBC_OPCODES[LOAD_CONST]}")
                constants_out+=("$value")
                ;;
            OP)
                case "$value" in
                    "+") bytecode_out+=("${NBC_OPCODES[ADD]}") ;;
                    "-") bytecode_out+=("${NBC_OPCODES[SUB]}") ;;
                    "*") bytecode_out+=("${NBC_OPCODES[MUL]}") ;;
                    "/") bytecode_out+=("${NBC_OPCODES[DIV]}") ;;
                    "=") bytecode_out+=("${NBC_OPCODES[STORE_VAR]}") ;;
                esac
                ;;
        esac
        
        ((pos++))
    done
    
    # 添加停止指令
    bytecode_out+=("${NBC_OPCODES[HALT]}")
}

#-------------------------------------------------------------------------------
# 写入字节码文件
#-------------------------------------------------------------------------------
nova_write_bytecode() {
    local output_file="$1"
    local -n bytecode_in=$2
    local -n constants_in=$3
    
    # 创建二进制文件
    {
        # 魔术头
        printf '%s' "$NBC_MAGIC"
        
        # 版本
        printf '\\x%02x' "$NBC_VERSION"
        
        # 标志
        printf '\\x00'
        
        # 常量数量
        local const_count=${#constants_in[@]}
        printf '\\x%02x\\x%02x' $((const_count / 256)) $((const_count % 256))
        
        # 常量
        for const in "${constants_in[@]}"; do
            local len=${#const}
            printf '\\x%02x' "$len"
            printf '%s' "$const"
        done
        
        # 指令
        for instr in "${bytecode_in[@]}"; do
            printf '\\x%02x' "$instr"
        done
    } > "$output_file"
}

#-------------------------------------------------------------------------------
# 运行字节码
#-------------------------------------------------------------------------------
nova_run_bytecode() {
    local bytecode_file="$1"
    
    if [[ ! -f "$bytecode_file" ]]; then
        echo "Error: Bytecode file not found: $bytecode_file" >&2
        return 1
    fi
    
    # 验证魔术头
    local magic
    magic=$(head -c 4 "$bytecode_file")
    
    if [[ "$magic" != "$NBC_MAGIC" ]]; then
        echo "Error: Invalid bytecode file format" >&2
        return 1
    fi
    
    # 读取并执行字节码
    # 这里简化处理，实际应该实现虚拟机
    echo "Running bytecode: $bytecode_file"
    
    # 对于现在，我们反编译回源码执行
    nova_decompile "$bytecode_file" | bash
}

#-------------------------------------------------------------------------------
# 反编译字节码
#-------------------------------------------------------------------------------
nova_decompile() {
    local bytecode_file="$1"
    
    # 读取文件
    local content
    content=$(cat "$bytecode_file")
    
    # 简单的反编译（占位符）
    echo "# Decompiled from $bytecode_file"
    echo "# This is a placeholder"
}

#-------------------------------------------------------------------------------
# 批量编译
#-------------------------------------------------------------------------------
nova_compile_all() {
    local source_dir="${1:-.}"
    local output_dir="${2:-build}"
    local optimize="${3:-false}"
    
    mkdir -p "$output_dir"
    
    local count=0
    while IFS= read -r -d '' file; do
        local basename=$(basename "$file" .nova)
        nova_compile "$file" "$output_dir/$basename.nbc" "$optimize"
        ((count++))
    done < <(find "$source_dir" -name "*.nova" -print0)
    
    echo "Compiled $count files"
}

#-------------------------------------------------------------------------------
# 清理编译产物
#-------------------------------------------------------------------------------
nova_clean_build() {
    local dir="${1:-.}"
    
    find "$dir" -name "*.nbc" -delete
    find "$dir" -type d -name "__nova_cache__" -exec rm -rf {} +
    
    echo "Build cleaned"
}
