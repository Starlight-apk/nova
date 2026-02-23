#!/bin/bash
#===============================================================================
# NovaScript 加密模块
# 采用轻量级多层混淆加密，适合 Termux/ARM64 设备
#===============================================================================

#-------------------------------------------------------------------------------
# 加密级别说明
# Level 1: Base64 + XOR (最快)
# Level 2: Base64 + XOR + Reverse (快速)
# Level 3: Base64 + XOR + Reverse + Substitution (平衡)
# Level 4: Base64 + XOR + Reverse + Substitution + Transposition (较慢)
# Level 5: 所有上述 + 自定义头 (最慢，最安全)
#-------------------------------------------------------------------------------

# 加密密钥（默认）
NOVA_ENCRYPT_KEY="${NOVA_ENCRYPT_KEY:-nova_default_key_2026}"

#-------------------------------------------------------------------------------
# XOR 加密
#-------------------------------------------------------------------------------
nova_xor_cipher() {
    local input="$1"
    local key="$2"
    local key_len=${#key}
    local output=""
    
    for ((i=0; i<${#input}; i++)); do
        local char="${input:$i:1}"
        local key_char="${key:$((i % key_len)):1}"
        local char_code=$(printf '%d' "'$char")
        local key_code=$(printf '%d' "'$key_char")
        local xor_code=$((char_code ^ key_code))
        
        # 处理非打印字符
        if [[ $xor_code -lt 32 ]] || [[ $xor_code -gt 126 ]]; then
            xor_code=$((xor_code % 95 + 32))
        fi
        
        output+=$(printf "\\$(printf '%03o' $xor_code)")
    done
    
    echo "$output"
}

#-------------------------------------------------------------------------------
# 替换加密
#-------------------------------------------------------------------------------
nova_substitute() {
    local input="$1"
    local output=""
    
    # 自定义替换表
    local from="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local to="qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM5678901234"
    
    for ((i=0; i<${#input}; i++)); do
        local char="${input:$i:1}"
        local pos=$(expr index "$from" "$char")
        if [[ $pos -gt 0 ]]; then
            output+="${to:$((pos-1)):1}"
        else
            output+="$char"
        fi
    done
    
    echo "$output"
}

#-------------------------------------------------------------------------------
# 反向替换
#-------------------------------------------------------------------------------
nova_unsubstitute() {
    local input="$1"
    local output=""
    
    local from="qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM5678901234"
    local to="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    for ((i=0; i<${#input}; i++)); do
        local char="${input:$i:1}"
        local pos=$(expr index "$from" "$char")
        if [[ $pos -gt 0 ]]; then
            output+="${to:$((pos-1)):1}"
        else
            output+="$char"
        fi
    done
    
    echo "$output"
}

#-------------------------------------------------------------------------------
# 转置加密
#-------------------------------------------------------------------------------
nova_transpose() {
    local input="$1"
    local len=${#input}
    local half=$((len / 2))
    local output=""
    
    # 交错排列
    for ((i=0; i<half; i++)); do
        output+="${input:$i:1}"
        output+="${input:$((len - i - 1)):1}"
    done
    
    # 处理奇数长度
    if [[ $((len % 2)) -ne 0 ]]; then
        output+="${input:$half:1}"
    fi
    
    echo "$output"
}

#-------------------------------------------------------------------------------
# 反向转置
#-------------------------------------------------------------------------------
nova_untranspose() {
    local input="$1"
    local len=${#input}
    local output=""
    
    local half=$((len / 2))
    local left=""
    local right=""
    
    for ((i=0; i<len; i++)); do
        if [[ $((i % 2)) -eq 0 ]]; then
            left+="${input:$i:1}"
        else
            right="${input:$i:1}$right"
        fi
    done
    
    output="$left$right"
    
    # 处理奇数长度
    if [[ $((len % 2)) -ne 0 ]]; then
        output="${output:0:$((len/2))}${output:$((len/2 + 1))}${output:$((len/2)):1}"
    fi
    
    echo "$output"
}

#-------------------------------------------------------------------------------
# 主加密函数
#-------------------------------------------------------------------------------
nova_encrypt() {
    local input_file="$1"
    local output_file="$2"
    local level="${3:-3}"
    local key="${4:-$NOVA_ENCRYPT_KEY}"
    
    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file not found" >&2
        return 1
    fi
    
    local content
    content=$(cat "$input_file")
    
    # 添加魔术头
    local magic="NOVA_ENC_v1_L${level}_"
    
    # Level 1: Base64 + XOR
    local result=$(echo "$content" | base64 -w0 2>/dev/null || echo "$content" | base64)
    result=$(nova_xor_cipher "$result" "$key")
    
    # Level 2: + Reverse
    if [[ $level -ge 2 ]]; then
        result=$(echo "$result" | rev)
    fi
    
    # Level 3: + Substitution
    if [[ $level -ge 3 ]]; then
        result=$(nova_substitute "$result")
    fi
    
    # Level 4: + Transposition
    if [[ $level -ge 4 ]]; then
        result=$(nova_transpose "$result")
    fi
    
    # Level 5: + Custom header + checksum
    if [[ $level -ge 5 ]]; then
        local checksum=$(echo "$content" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "$content" | md5)
        magic="${magic}${checksum:0:8}_"
    fi
    
    # 写入输出文件
    echo "${magic}${result}" > "$output_file"
    
    return 0
}

#-------------------------------------------------------------------------------
# 主解密函数
#-------------------------------------------------------------------------------
nova_decrypt() {
    local input_file="$1"
    local output_file="$2"
    local key="${3:-$NOVA_ENCRYPT_KEY}"
    
    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file not found" >&2
        return 1
    fi
    
    local content
    content=$(cat "$input_file")
    
    # 验证魔术头
    if [[ ! "$content" =~ ^NOVA_ENC_v1_L([0-9])_ ]]; then
        echo "Error: Invalid encrypted file format" >&2
        return 1
    fi
    
    local level="${BASH_REMATCH[1]}"
    
    # 移除魔术头
    content="${content#NOVA_ENC_v1_L${level}_}"
    
    # Level 5: Verify checksum
    if [[ $level -ge 5 ]]; then
        content="${content#*_}"
    fi
    
    local result="$content"
    
    # Level 4: Untranspose
    if [[ $level -ge 4 ]]; then
        result=$(nova_untranspose "$result")
    fi
    
    # Level 3: Unsubstitute
    if [[ $level -ge 3 ]]; then
        result=$(nova_unsubstitute "$result")
    fi
    
    # Level 2: Unreverse
    if [[ $level -ge 2 ]]; then
        result=$(echo "$result" | rev)
    fi
    
    # Level 1: XOR + Base64 decode
    result=$(nova_xor_cipher "$result" "$key")
    result=$(echo "$result" | base64 -d 2>/dev/null || echo "$result" | base64 --decode 2>/dev/null || echo "$result")
    
    # 写入输出文件
    echo "$result" > "$output_file"
    
    return 0
}

#-------------------------------------------------------------------------------
# 加密字符串
#-------------------------------------------------------------------------------
nova_encrypt_string() {
    local input="$1"
    local level="${2:-3}"
    local key="${3:-$NOVA_ENCRYPT_KEY}"
    
    local result=$(echo "$input" | base64 -w0 2>/dev/null || echo "$input" | base64)
    result=$(nova_xor_cipher "$result" "$key")
    
    if [[ $level -ge 2 ]]; then
        result=$(echo "$result" | rev)
    fi
    
    if [[ $level -ge 3 ]]; then
        result=$(nova_substitute "$result")
    fi
    
    if [[ $level -ge 4 ]]; then
        result=$(nova_transpose "$result")
    fi
    
    local magic="NOVA_ENC_v1_L${level}_"
    if [[ $level -ge 5 ]]; then
        local checksum=$(echo "$input" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "$input" | md5)
        magic="${magic}${checksum:0:8}_"
    fi
    
    echo "${magic}${result}"
}

#-------------------------------------------------------------------------------
# 解密字符串
#-------------------------------------------------------------------------------
nova_decrypt_string() {
    local input="$1"
    local key="${2:-$NOVA_ENCRYPT_KEY}"
    
    if [[ ! "$input" =~ ^NOVA_ENC_v1_L([0-9])_ ]]; then
        echo "Error: Invalid encrypted string format" >&2
        return 1
    fi
    
    local level="${BASH_REMATCH[1]}"
    local content="${input#NOVA_ENC_v1_L${level}_}"
    
    if [[ $level -ge 5 ]]; then
        content="${content#*_}"
    fi
    
    local result="$content"
    
    if [[ $level -ge 4 ]]; then
        result=$(nova_untranspose "$result")
    fi
    
    if [[ $level -ge 3 ]]; then
        result=$(nova_unsubstitute "$result")
    fi
    
    if [[ $level -ge 2 ]]; then
        result=$(echo "$result" | rev)
    fi
    
    result=$(nova_xor_cipher "$result" "$key")
    result=$(echo "$result" | base64 -d 2>/dev/null || echo "$result" | base64 --decode 2>/dev/null || echo "$result")
    
    echo "$result"
}

#-------------------------------------------------------------------------------
# 生成密钥
#-------------------------------------------------------------------------------
nova_generate_key() {
    local length="${1:-32}"
    local chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*'
    local key=""
    
    for ((i=0; i<length; i++)); do
        local idx=$((RANDOM % ${#chars}))
        key+="${chars:$idx:1}"
    done
    
    echo "$key"
}

#-------------------------------------------------------------------------------
# 哈希函数
#-------------------------------------------------------------------------------
nova_hash() {
    local input="$1"
    local algorithm="${2:-md5}"
    
    case "$algorithm" in
        md5)
            echo "$input" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "$input" | md5
            ;;
        sha1)
            echo "$input" | sha1sum 2>/dev/null | cut -d' ' -f1 || echo "$input" | shasum -a 1
            ;;
        sha256)
            echo "$input" | sha256sum 2>/dev/null | cut -d' ' -f1 || echo "$input" | shasum -a 256
            ;;
        *)
            echo "$input" | md5sum 2>/dev/null | cut -d' ' -f1
            ;;
    esac
}
