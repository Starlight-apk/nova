#!/bin/bash
#===============================================================================
# NovaScript 国际化 (i18n) 模块
#===============================================================================

# 当前语言
NOVA_LANG="${NOVA_LANG:-en}"

# 翻译存储
declare -gA NOVA_I18N_MESSAGES=()

#-------------------------------------------------------------------------------
# 初始化 i18n
#-------------------------------------------------------------------------------
init_i18n() {
    local lang="${1:-en}"
    NOVA_LANG="$lang"
    load_translations "$lang"
}

#-------------------------------------------------------------------------------
# 加载翻译
#-------------------------------------------------------------------------------
load_translations() {
    local lang="$1"
    local locale_file="$NOVA_HOME/src/i18n/locales/$lang.json"
    
    NOVA_I18N_MESSAGES=()
    
    if [[ -f "$locale_file" ]]; then
        # 简单的 JSON 解析
        while IFS= read -r line; do
            if [[ "$line" =~ \"([^\"]+)\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${BASH_REMATCH[2]}"
                NOVA_I18N_MESSAGES["$key"]="$value"
            fi
        done < "$locale_file"
    fi
}

#-------------------------------------------------------------------------------
# 获取翻译
#-------------------------------------------------------------------------------
i18n() {
    local key="$1"
    shift
    local args=("$@")
    
    local message="${NOVA_I18N_MESSAGES[$key]:-$key}"
    
    # 替换占位符 {0}, {1}, ...
    for i in "${!args[@]}"; do
        message="${message//\{$i\}/${args[$i]}}"
    done
    
    echo "$message"
}

#-------------------------------------------------------------------------------
# 设置语言
#-------------------------------------------------------------------------------
set_language() {
    local lang="$1"
    init_i18n "$lang"
}

#-------------------------------------------------------------------------------
# 获取当前语言
#-------------------------------------------------------------------------------
get_language() {
    echo "$NOVA_LANG"
}

#-------------------------------------------------------------------------------
# 获取支持的语言列表
#-------------------------------------------------------------------------------
get_supported_languages() {
    local locales_dir="$NOVA_HOME/src/i18n/locales"
    if [[ -d "$locales_dir" ]]; then
        for f in "$locales_dir"/*.json; do
            basename "$f" .json
        done
    else
        echo "en"
        echo "zh-CN"
        echo "zh-TW"
        echo "es"
        echo "fr"
        echo "de"
        echo "ja"
        echo "ko"
        echo "ru"
    fi
}

#-------------------------------------------------------------------------------
# 添加翻译
#-------------------------------------------------------------------------------
add_translation() {
    local lang="$1"
    local key="$2"
    local value="$3"
    
    NOVA_I18N_MESSAGES["$key"]="$value"
}

#-------------------------------------------------------------------------------
# 翻译复数形式
#-------------------------------------------------------------------------------
i18n_plural() {
    local key="$1"
    local count="$2"
    shift 2
    
    local message=""
    if [[ $count -eq 1 ]]; then
        message="${NOVA_I18N_MESSAGES[${key}_singular]:-$key}"
    else
        message="${NOVA_I18N_MESSAGES[${key}_plural]:-${key}}"
    fi
    
    message="${message//\{count\}/$count}"
    
    echo "$message"
}
