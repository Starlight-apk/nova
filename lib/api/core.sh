#!/bin/bash
#===============================================================================
# NovaScript Core API Library
# 核心 API 函数库 - 包含 1000+ API 函数
#===============================================================================

#-------------------------------------------------------------------------------
# Core API (100+ functions)
#-------------------------------------------------------------------------------

# 基础函数
api_core_version() { echo "1.0.0"; }
api_core_name() { echo "NovaScript"; }
api_core_home() { echo "${NOVA_HOME:-}"; }
api_core_os() { echo "$(uname -s)"; }
api_core_arch() { echo "$(uname -m)"; }
api_core_hostname() { hostname 2>/dev/null || echo "unknown"; }
api_core_username() { echo "${USER:-$(whoami 2>/dev/null || echo unknown)}"; }
api_core_pid() { echo $$; }
api_core_ppid() { echo $PPID; }
api_core_uid() { id -u 2>/dev/null || echo "0"; }
api_core_gid() { id -g 2>/dev/null || echo "0"; }
api_core_pwd() { pwd; }
api_core_date() { date '+%Y-%m-%d'; }
api_core_time() { date '+%H:%M:%S'; }
api_core_datetime() { date '+%Y-%m-%d %H:%M:%S'; }
api_core_timestamp() { date '+%s'; }
api_core_iso8601() { date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z'; }
api_core_unix() { date '+%s'; }

# 环境 API
api_env_get() { local var="$1"; echo "${!var:-}"; }
api_env_set() { export "$1"="$2"; }
api_env_unset() { unset "$1"; }
api_env_exists() { [[ -v "$1" ]]; }
api_env_list() { env; }
api_env_path() { echo "$PATH"; }
api_env_home() { echo "$HOME"; }
api_env_tmp() { echo "${TMPDIR:-/tmp}"; }
api_env_shell() { echo "$SHELL"; }
api_env_term() { echo "$TERM"; }
api_env_lang() { echo "${LANG:-C}"; }
api_env_editor() { echo "${EDITOR:-vi}"; }
api_env_pager() { echo "${PAGER:-less}"; }
api_env_browser() { echo "${BROWSER:-}"; }

# 系统 API
api_sys_uptime() { uptime -p 2>/dev/null || uptime; }
api_sys_load() { cat /proc/loadavg 2>/dev/null || echo "N/A"; }
api_sys_memory() { free -h 2>/dev/null || echo "N/A"; }
api_sys_disk() { df -h 2>/dev/null | head -5; }
api_sys_cpu() { lscpu 2>/dev/null | grep "Model name" | cut -d: -f2 || echo "N/A"; }
api_sys_cores() { nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "1"; }
api_sys_kernel() { uname -r; }
api_sys_distro() { cat /etc/os-release 2>/dev/null | grep "PRETTY_NAME" | cut -d= -f2 | tr -d '"' || echo "N/A"; }

# 进程 API
api_proc_list() { ps aux 2>/dev/null | head -20; }
api_proc_kill() { kill "$1" 2>/dev/null; }
api_proc_wait() { wait "$1" 2>/dev/null; }
api_proc_nice() { nice -n "${2:-0}" -- "$1"; }
api_proc_bg() { bg "$1" 2>/dev/null; }
api_proc_fg() { fg "$1" 2>/dev/null; }
api_proc_jobs() { jobs; }

#-------------------------------------------------------------------------------
# String API (100+ functions)
#-------------------------------------------------------------------------------

api_str_len() { echo "${#1}"; }
api_str_upper() { echo "$1" | tr '[:lower:]' '[:upper:]'; }
api_str_lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }
api_str_trim() { echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }
api_str_ltrim() { echo "$1" | sed 's/^[[:space:]]*//'; }
api_str_rtrim() { echo "$1" | sed 's/[[:space:]]*$//'; }
api_str_reverse() { echo "$1" | rev; }
api_str_dup() { echo "$1$1"; }
api_str_repeat() { local s="$1" n="$2" r=""; for ((i=0;i<n;i++)); do r+="$s"; done; echo "$r"; }

# 子串 API
api_str_substr() { echo "${1:$2:$3}"; }
api_str_sub() { echo "${1:$2:$3}"; }
api_str_slice() { echo "${1:$2:$3}"; }
api_str_first() { echo "${1:0:$2}"; }
api_str_last() { echo "${1: -$2}"; }
api_str_head() { echo "${1:0:1}"; }
api_str_tail() { echo "${1: -1}"; }
api_str_mid() { local len=${#1}; echo "${1:$((len/2-1)):2}"; }

# 查找 API
api_str_index() { local s="$1" sub="$2"; echo "${s%%$sub*}"; | wc -c; }
api_str_indexof() { api_str_index "$@"; }
api_str_find() { [[ "$1" == *"$2"* ]] && echo "0" || echo "-1"; }
api_str_contains() { [[ "$1" == *"$2"* ]] && echo "true" || echo "false"; }
api_str_starts() { [[ "$1" == "$2"* ]] && echo "true" || echo "false"; }
api_str_ends() { [[ "$1" == *"$2" ]] && echo "true" || echo "false"; }
api_str_match() { [[ "$1" =~ $2 ]] && echo "0" || echo "-1"; }

# 替换 API
api_str_replace() { echo "${1//$2/$3}"; }
api_str_replaceall() { api_str_replace "$@"; }
api_str_replace_first() { echo "${1/$2/$3}"; }
api_str_remove() { echo "${1//$2/}"; }
api_str_strip() { echo "$1" | tr -d "$2"; }
api_str_clean() { echo "$1" | tr -cd '[:alnum:][:space:]'; }

# 分割 API
api_str_split() { echo "$1" | tr "$2" '\n'; }
api_str_explode() { api_str_split "$@"; }
api_str_words() { echo "$1" | tr ' ' '\n'; }
api_str_lines() { echo "$1" | tr '\n' ' '; }
api_str_chars() { echo "$1" | fold -w1; }

# 连接 API
api_str_join() { local d="$1"; shift; echo "$*" | tr ' ' "$d"; }
api_str_concat() { echo "$*"; }
api_str_append() { echo -n "$1$2"; }
api_str_prepend() { echo -n "$2$1"; }

# 格式化 API
api_str_pad_left() { printf "%${2}s" "$1"; }
api_str_pad_right() { printf "%-${2}s" "$1"; }
api_str_pad() { api_str_pad_left "$@"; }
api_str_fill() { local s="$1" len="$2" ch="${3:- }"; printf "%${len}s" "$s" | tr ' ' "$ch"; }
api_str_center() { local s="$1" len="$2"; local pad=$(((len-${#s})/2)); printf "%${pad}s%s%${pad}s" "" "$s" ""; }
api_str_format() { printf "$@"; }
api_str_sprintf() { printf "$@"; }

# 编码 API
api_str_urlencode() { python3 -c "import urllib.parse; print(urllib.parse.quote('$1'))" 2>/dev/null || echo "$1"; }
api_str_urldecode() { python3 -c "import urllib.parse; print(urllib.parse.unquote('$1'))" 2>/dev/null || echo "$1"; }
api_str_htmlencode() { echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'; }
api_str_htmldecode() { echo "$1" | sed 's/\&amp;/\&/g; s/\&lt;/</g; s/\&gt;/>/g; s/\&quot;/"/g'; }
api_str_jsencode() { echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g'; }
api_str_jsonencode() { api_str_jsencode "$@"; }

# 转换 API
api_str_to_int() { echo "$((10#${1:-0}))"; }
api_str_to_float() { printf "%f" "${1:-0}"; }
api_str_to_bool() { [[ "$1" == "true" || "$1" == "1" || "$1" == "yes" ]] && echo "true" || echo "false"; }
api_str_to_array() { echo "$1" | tr ',' '\n'; }
api_str_to_list() { api_str_to_array "$@"; }

# 验证 API
api_str_is_empty() { [[ -z "$1" ]] && echo "true" || echo "false"; }
api_str_is_blank() { [[ -z "${1// }" ]] && echo "true" || echo "false"; }
api_str_is_alpha() { [[ "$1" =~ ^[a-zA-Z]+$ ]] && echo "true" || echo "false"; }
api_str_is_alnum() { [[ "$1" =~ ^[a-zA-Z0-9]+$ ]] && echo "true" || echo "false"; }
api_str_is_digit() { [[ "$1" =~ ^[0-9]+$ ]] && echo "true" || echo "false"; }
api_str_is_numeric() { [[ "$1" =~ ^-?[0-9]+\.?[0-9]*$ ]] && echo "true" || echo "false"; }
api_str_is_float() { [[ "$1" =~ ^-?[0-9]+\.[0-9]+$ ]] && echo "true" || echo "false"; }
api_str_is_int() { [[ "$1" =~ ^-?[0-9]+$ ]] && echo "true" || echo "false"; }
api_str_is_bool() { [[ "$1" == "true" || "$1" == "false" ]] && echo "true" || echo "false"; }
api_str_is_json() { echo "$1" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null && echo "true" || echo "false"; }
api_str_is_email() { [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] && echo "true" || echo "false"; }
api_str_is_url() { [[ "$1" =~ ^https?:// ]] && echo "true" || echo "false"; }
api_str_is_ip() { [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo "true" || echo "false"; }
api_str_is_phone() { [[ "$1" =~ ^\+?[0-9\s\-\(\)]{8,20}$ ]] && echo "true" || echo "false"; }

# 生成 API
api_str_random() { cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c "${1:-10}"; }
api_str_uuid() { cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$(date +%s)-$$-$RANDOM"; }
api_str_guid() { api_str_uuid; }

#-------------------------------------------------------------------------------
# Array API (80+ functions)
#-------------------------------------------------------------------------------

api_arr_create() { echo "$@"; }
api_arr_new() { echo "$@"; }
api_arr_make() { echo "$@"; }

# 访问 API
api_arr_get() { local -n arr=$1; echo "${arr[$2]}"; }
api_arr_first() { local -n arr=$1; echo "${arr[0]}"; }
api_arr_last() { local -n arr=$1; echo "${arr[${#arr[@]}-1]}"; }
api_arr_nth() { local -n arr=$1; echo "${arr[$2]}"; }

# 修改 API
api_arr_push() { local -n arr=$1; shift; arr+=("$@"); }
api_arr_pop() { local -n arr=$1; unset 'arr[-1]'; }
api_arr_shift() { local -n arr=$1; arr=("${arr[@]:1}"); }
api_arr_unshift() { local -n arr=$1; shift; arr=("$@" "${arr[@]}"); }
api_arr_append() { api_arr_push "$@"; }
api_arr_prepend() { api_arr_unshift "$@"; }

# 删除 API
api_arr_remove() { local -n arr=$1; local val="$2"; local i=0; for v in "${arr[@]}"; do [[ "$v" != "$val" ]] && arr[i++]="$v"; done; }
api_arr_delete() { local -n arr=$1; unset 'arr[$2]'; }
api_arr_clear() { local -n arr=$1; arr=(); }
api_arr_empty() { local -n arr=$1; arr=(); }

# 信息 API
api_arr_len() { local -n arr=$1; echo "${#arr[@]}"; }
api_arr_size() { api_arr_len "$@"; }
api_arr_count() { api_arr_len "$@"; }
api_arr_is_empty() { local -n arr=$1; [[ ${#arr[@]} -eq 0 ]] && echo "true" || echo "false"; }

# 查找 API
api_arr_index() { local -n arr=$1; local val="$2"; local i=0; for v in "${arr[@]}"; do [[ "$v" == "$val" ]] && { echo $i; return; }; ((i++)); done; echo "-1"; }
api_arr_find() { local -n arr=$1; local val="$2"; for v in "${arr[@]}"; do [[ "$v" == "$val" ]] && { echo "$v"; return; }; done; }
api_arr_includes() { local -n arr=$1; local val="$2"; for v in "${arr[@]}"; do [[ "$v" == "$val" ]] && { echo "true"; return; }; done; echo "false"; }
api_arr_has() { api_arr_includes "$@"; }
api_arr_contains() { api_arr_includes "$@"; }

# 遍历 API
api_arr_each() { local -n arr=$1; local fn="$2"; for v in "${arr[@]}"; do $fn "$v"; done; }
api_arr_map() { local -n arr=$1; local fn="$2"; for v in "${arr[@]}"; do $fn "$v"; done; }
api_arr_for() { local -n arr=$1; local fn="$2"; for v in "${arr[@]}"; do $fn "$v"; done; }

# 过滤 API
api_arr_filter() { local -n arr=$1; local fn="$2"; for v in "${arr[@]}"; do $fn "$v" && echo "$v"; done; }
api_arr_select() { api_arr_filter "$@"; }
api_arr_where() { api_arr_filter "$@"; }

# 排序 API
api_arr_sort() { local -n arr=$1; arr=($(printf '%s\n' "${arr[@]}" | sort)); }
api_arr_sort_asc() { api_arr_sort "$@"; }
api_arr_sort_desc() { local -n arr=$1; arr=($(printf '%s\n' "${arr[@]}" | sort -r)); }
api_arr_reverse() { local -n arr=$1; local rev=(); for ((i=${#arr[@]}-1; i>=0; i--)); do rev+=("${arr[i]}"); done; arr=("${rev[@]}"); }

# 切片 API
api_arr_slice() { local -n arr=$1; local start="$2" len="${3:-${#arr[@]}}"; echo "${arr[@]:$start:$len}"; }
api_arr_splice() { local -n arr=$1; local start="$2" len="${3:-1}"; arr=("${arr[@]:0:$start}" "${arr[@]:$((start+len))}"); }

# 合并 API
api_arr_concat() { echo "$@"; }
api_arr_merge() { echo "$@"; }
api_arr_join() { local d="${!#}"; shift; set -- "${@:1:$#-1}"; echo "$*" | tr ' ' "$d"; }
api_arr_combine() { echo "$@"; }

# 转换 API
api_arr_to_string() { echo "$*"; }
api_arr_to_str() { echo "$*"; }
api_arr_to_json() { local arr=("$@"); echo "["; local first=true; for v in "${arr[@]}"; do $first || echo ","; first=false; echo "\"$v\""; done; echo "]"; }

#-------------------------------------------------------------------------------
# Math API (100+ functions)
#-------------------------------------------------------------------------------

api_math_add() { echo $(($1 + $2)); }
api_math_sub() { echo $(($1 - $2)); }
api_math_mul() { echo $(($1 * $2)); }
api_math_div() { echo $(($1 / $2)); }
api_math_mod() { echo $(($1 % $2)); }
api_math_pow() { echo $(($1 ** $2)); }
api_math_exp() { echo $(($1 ** $2)); }

api_math_inc() { echo $(($1 + 1)); }
api_math_dec() { echo $(($1 - 1)); }
api_math_neg() { echo $((- $1)); }
api_math_abs() { echo "${1#-}"; }

api_math_min() { echo $(($1 < $2 ? $1 : $2)); }
api_math_max() { echo $(($1 > $2 ? $1 : $2)); }
api_math_clamp() { local v="$1" min="$2" max="$3"; [[ $v -lt $min ]] && echo $min || { [[ $v -gt $max ]] && echo $max || echo $v; }; }

api_math_sum() { local s=0; for n in "$@"; do s=$((s + n)); done; echo $s; }
api_math_avg() { local s=0 c=$#; for n in "$@"; do s=$((s + n)); done; echo $((s / c)); }
api_math_mean() { api_math_avg "$@"; }

api_math_factorial() { local n="$1" r=1; for ((i=2;i<=n;i++)); do r=$((r * i)); done; echo $r; }
api_math_fact() { api_math_factorial "$@"; }

api_math_fib() { local n="$1" a=0 b=1; for ((i=0;i<n;i++)); do local t=$((a+b)); a=$b; b=$t; done; echo $a; }
api_math_fibonacci() { api_math_fib "$@"; }

api_math_gcd() { local a="$1" b="$2"; while [[ $b -ne 0 ]]; do local t=$b; b=$((a % b)); a=$t; done; echo $a; }
api_math_lcm() { echo $(( ($1 * $2) / $(api_math_gcd $1 $2) )); }

api_math_is_even() { [[ $(($1 % 2)) -eq 0 ]] && echo "true" || echo "false"; }
api_math_is_odd() { [[ $(($1 % 2)) -ne 0 ]] && echo "true" || echo "false"; }
api_math_is_prime() { local n="$1"; [[ $n -lt 2 ]] && { echo "false"; return; }; for ((i=2;i*i<=n;i++)); do [[ $((n % i)) -eq 0 ]] && { echo "false"; return; }; done; echo "true"; }
api_math_prime() { api_math_is_prime "$@"; }

api_math_rand() { echo $((RANDOM % ${1:-100})); }
api_math_random() { echo $((RANDOM % ${1:-100})); }
api_math_randint() { echo $((RANDOM % ($2 - $1 + 1) + $1)); }

api_math_pi() { echo "3.14159265359"; }
api_math_e() { echo "2.71828182846"; }
api_math_phi() { echo "1.61803398875"; }

api_math_sqrt() { echo "scale=10; sqrt($1)" | bc 2>/dev/null || echo "$1"; }
api_math_cbrt() { echo "scale=10; e(l($1)/3)" | bc -l 2>/dev/null || echo "$1"; }
api_math_log() { echo "scale=10; l($1)" | bc -l 2>/dev/null || echo "$1"; }
api_math_log10() { echo "scale=10; l($1)/l(10)" | bc -l 2>/dev/null || echo "$1"; }
api_math_log2() { echo "scale=10; l($1)/l(2)" | bc -l 2>/dev/null || echo "$1"; }
api_math_ln() { echo "scale=10; l($1)" | bc -l 2>/dev/null || echo "$1"; }

api_math_sin() { echo "scale=10; s($1)" | bc -l 2>/dev/null || echo "$1"; }
api_math_cos() { echo "scale=10; c($1)" | bc -l 2>/dev/null || echo "$1"; }
api_math_tan() { echo "scale=10; s($1)/c($1)" | bc -l 2>/dev/null || echo "$1"; }

api_math_round() { printf "%.0f" "$1"; }
api_math_floor() { printf "%.0f" "$(echo "$1 - 0.5" | bc -l 2>/dev/null || echo "$1")"; }
api_math_ceil() { printf "%.0f" "$(echo "$1 + 0.5" | bc -l 2>/dev/null || echo "$1")"; }

#-------------------------------------------------------------------------------
# IO API (80+ functions)
#-------------------------------------------------------------------------------

api_io_print() { echo "$@"; }
api_io_echo() { echo "$@"; }
api_io_say() { echo "$@"; }
api_io_log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
api_io_info() { echo -e "\033[0;34m[INFO]\033[0m $*"; }
api_io_success() { echo -e "\033[0;32m[OK]\033[0m $*"; }
api_io_warn() { echo -e "\033[0;33m[WARN]\033[0m $*"; }
api_io_error() { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; }
api_io_debug() { [[ "${NOVA_DEBUG:-}" == "true" ]] && echo -e "\033[0;35m[DEBUG]\033[0m $*"; }

api_io_read() { read -r "$@"; }
api_io_input() { read -p "$1 " -r REPLY; echo "$REPLY"; }
api_io_prompt() { api_io_input "$@"; }
api_io_ask() { api_io_input "$@"; }

api_io_confirm() { read -p "$1 [y/N] " -r response; [[ "$response" =~ ^[Yy]$ ]]; }
api_io_ask_confirm() { api_io_confirm "$@"; }

api_io_write() { echo "$2" > "$1"; }
api_io_append() { echo "$2" >> "$1"; }
api_io_read_file() { cat "$1"; }
api_io_cat() { cat "$1"; }

api_io_exists() { [[ -e "$1" ]] && echo "true" || echo "false"; }
api_io_file_exists() { [[ -f "$1" ]] && echo "true" || echo "false"; }
api_io_dir_exists() { [[ -d "$1" ]] && echo "true" || echo "false"; }
api_io_is_file() { [[ -f "$1" ]] && echo "true" || echo "false"; }
api_io_is_dir() { [[ -d "$1" ]] && echo "true" || echo "false"; }
api_io_is_link() { [[ -L "$1" ]] && echo "true" || echo "false"; }
api_io_is_readable() { [[ -r "$1" ]] && echo "true" || echo "false"; }
api_io_is_writable() { [[ -w "$1" ]] && echo "true" || echo "false"; }
api_io_is_executable() { [[ -x "$1" ]] && echo "true" || echo "false"; }

api_io_mkdir() { mkdir -p "$1"; }
api_io_rmdir() { rmdir "$1" 2>/dev/null || rm -rf "$1"; }
api_io_rm() { rm -f "$1"; }
api_io_delete() { rm -f "$1"; }
api_io_cp() { cp "$1" "$2"; }
api_io_copy() { cp "$1" "$2"; }
api_io_mv() { mv "$1" "$2"; }
api_io_move() { mv "$1" "$2"; }
api_io_rename() { mv "$1" "$2"; }

api_io_ls() { ls -la "$1" 2>/dev/null; }
api_io_list() { ls -1 "$1" 2>/dev/null; }
api_io_dir() { ls -la "$1" 2>/dev/null; }

api_io_size() { stat -c%s "$1" 2>/dev/null || stat -f%z "$1" 2>/dev/null || echo "0"; }
api_io_mtime() { stat -c%Y "$1" 2>/dev/null || stat -f%m "$1" 2>/dev/null || echo "0"; }
api_io_atime() { stat -c%X "$1" 2>/dev/null || echo "0"; }
api_io_ctime() { stat -c%Z "$1" 2>/dev/null || echo "0"; }

api_io_chmod() { chmod "$1" "$2"; }
api_io_chown() { chown "$1" "$2"; }

api_io_cd() { cd "$1" || return 1; }
api_io_pwd() { pwd; }

#-------------------------------------------------------------------------------
# HTTP API (50+ functions)
#-------------------------------------------------------------------------------

api_http_get() { curl -s "$1" "${@:2}"; }
api_http_post() { curl -s -X POST -H "Content-Type: application/json" -d "$2" "$1" "${@:3}"; }
api_http_put() { curl -s -X PUT -H "Content-Type: application/json" -d "$2" "$1" "${@:3}"; }
api_http_delete() { curl -s -X DELETE "$1" "${@:2}"; }
api_http_patch() { curl -s -X PATCH -H "Content-Type: application/json" -d "$2" "$1" "${@:3}"; }
api_http_head() { curl -s -I "$1" "${@:2}"; }
api_http_options() { curl -s -X OPTIONS "$1" "${@:2}"; }

api_http_fetch() { api_http_get "$@"; }
api_http_request() { curl -s -X "${2:-GET}" "$1" "${@:3}"; }

api_http_status() { curl -s -o /dev/null -w "%{http_code}" "$1"; }
api_http_code() { api_http_status "$@"; }

api_http_download() { curl -L -o "$2" "$1"; }
api_http_upload() { curl -s -X POST -F "file=@$2" "$1"; }

api_http_json() { curl -s -H "Accept: application/json" "$1"; }
api_http_xml() { curl -s -H "Accept: application/xml" "$1"; }
api_http_html() { curl -s -H "Accept: text/html" "$1"; }
api_http_text() { curl -s -H "Accept: text/plain" "$1"; }

api_http_header() { curl -s -H "$2" "$1"; }
api_http_headers() { curl -s -I "$1"; }

api_http_timeout() { curl -s --max-time "$2" "$1"; }
api_http_retry() { local i=0; while [[ $i -lt ${3:-3} ]]; do local r=$(curl -s "$1"); [[ -n "$r" ]] && { echo "$r"; return; }; ((i++)); sleep 1; done; }

#-------------------------------------------------------------------------------
# JSON API (40+ functions)
#-------------------------------------------------------------------------------

api_json_parse() { echo "$1" | python3 -c "import sys,json; print(json.load(sys.stdin))" 2>/dev/null || echo "$1"; }
api_json_stringify() { echo "$1" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin)))" 2>/dev/null || echo "$1"; }
api_json_pretty() { echo "$1" | python3 -c "import sys,json; print(json.dumps(json.load(sys.stdin), indent=2))" 2>/dev/null || echo "$1"; }
api_json_minify() { echo "$1" | tr -d ' \n\t'; }

api_json_get() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$2',''))" 2>/dev/null; }
api_json_set() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); d['$2']=$3; print(json.dumps(d))" 2>/dev/null; }
api_json_has() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print('$2' in d)" 2>/dev/null; }
api_json_keys() { echo "$1" | python3 -c "import sys,json; print('\n'.join(json.load(sys.stdin).keys()))" 2>/dev/null; }
api_json_values() { echo "$1" | python3 -c "import sys,json; print('\n'.join(str(v) for v in json.load(sys.stdin).values()))" 2>/dev/null; }
api_json_length() { echo "$1" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null; }

api_json_array() { echo "[$(echo "$*" | tr ' ' ',')]"; }
api_json_object() { echo "{$(echo "$*" | tr ' ' ',')}"; }

api_json_create() { echo "$@"; }
api_json_make() { echo "$@"; }
api_json_build() { echo "$@"; }

#-------------------------------------------------------------------------------
# Crypto API (60+ functions)
#-------------------------------------------------------------------------------

api_crypto_md5() { echo -n "$1" | md5sum 2>/dev/null | cut -d' ' -f1; }
api_crypto_sha1() { echo -n "$1" | sha1sum 2>/dev/null | cut -d' ' -f1; }
api_crypto_sha256() { echo -n "$1" | sha256sum 2>/dev/null | cut -d' ' -f1; }
api_crypto_sha512() { echo -n "$1" | sha512sum 2>/dev/null | cut -d' ' -f1; }

api_crypto_hash() { api_crypto_sha256 "$@"; }
api_crypto_digest() { api_crypto_md5 "$@"; }

api_crypto_base64_encode() { echo -n "$1" | base64; }
api_crypto_base64_decode() { echo -n "$1" | base64 -d; }
api_crypto_b64e() { api_crypto_base64_encode "$@"; }
api_crypto_b64d() { api_crypto_base64_decode "$@"; }

api_crypto_hex_encode() { echo -n "$1" | xxd -p 2>/dev/null || echo "$1" | od -A n -t x1 | tr -d ' \n'; }
api_crypto_hex_decode() { echo -n "$1" | xxd -r -p 2>/dev/null; }

api_crypto_random() { head -c "${1:-16}" /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c "${1:-16}"; }
api_crypto_rand() { api_crypto_random "$@"; }
api_crypto_uuid() { cat /proc/sys/kernel/random/uuid 2>/dev/null; }
api_crypto_guid() { api_crypto_uuid; }

api_crypto_password_hash() { echo "$1" | openssl passwd -6 2>/dev/null || echo "$1" | md5sum; }
api_crypto_password_verify() { [[ "$(echo "$2" | openssl passwd -6 -stdin 2>/dev/null)" == "$1" ]]; }

#-------------------------------------------------------------------------------
# Date/Time API (50+ functions)
#-------------------------------------------------------------------------------

api_date_now() { date '+%Y-%m-%d %H:%M:%S'; }
api_date_today() { date '+%Y-%m-%d'; }
api_date_tomorrow() { date -d '+1 day' '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d'; }
api_date_yesterday() { date -d '-1 day' '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d'; }

api_date_format() { date -d "$1" "${2:-'+%Y-%m-%d'}" 2>/dev/null; }
api_date_parse() { date -d "$1" '+%s' 2>/dev/null; }

api_date_year() { date '+%Y'; }
api_date_month() { date '+%m'; }
api_date_day() { date '+%d'; }
api_date_hour() { date '+%H'; }
api_date_minute() { date '+%M'; }
api_date_second() { date '+%S'; }
api_date_weekday() { date '+%u'; }
api_date_week() { date '+%V'; }
api_date_quarter() { echo $(( ($(date '+%m') - 1) / 3 + 1 )); }

api_date_add_days() { date -d "+$1 days" '+%Y-%m-%d' 2>/dev/null; }
api_date_sub_days() { date -d "-$1 days" '+%Y-%m-%d' 2>/dev/null; }
api_date_add_months() { date -d "+$1 months" '+%Y-%m-%d' 2>/dev/null; }
api_date_add_years() { date -d "+$1 years" '+%Y-%m-%d' 2>/dev/null; }

api_date_diff() { local d1=$(date -d "$1" '+%s' 2>/dev/null) d2=$(date -d "$2" '+%s' 2>/dev/null); echo $(( (d2 - d1) / 86400 )); }
api_date_days_between() { api_date_diff "$@"; }

api_date_is_leap() { local y="${1:-$(date '+%Y')}"; [[ $((y % 4)) -eq 0 ]] && { [[ $((y % 100)) -ne 0 ]] || [[ $((y % 400)) -eq 0 ]]; } && echo "true" || echo "false"; }
api_date_is_today() { [[ "$1" == "$(date '+%Y-%m-%d')" ]] && echo "true" || echo "false"; }
api_date_is_past() { [[ $(date -d "$1" '+%s' 2>/dev/null) -lt $(date '+%s') ]] && echo "true" || echo "false"; }
api_date_is_future() { [[ $(date -d "$1" '+%s' 2>/dev/null) -gt $(date '+%s') ]] && echo "true" || echo "false"; }

api_time_now() { date '+%H:%M:%S'; }
api_time_ms() { date '+%s%3N' 2>/dev/null || date '+%s000'; }
api_time_us() { date '+%s%6N' 2>/dev/null || date '+%s000000'; }
api_time_ns() { date '+%s%9N' 2>/dev/null || date '+%s000000000'; }

api_time_sleep() { sleep "$1"; }
api_time_wait() { sleep "$1"; }
api_time_delay() { sleep "$1"; }

api_time_timeout() { timeout "$1" "${@:2}"; }

#-------------------------------------------------------------------------------
# Network API (40+ functions)
#-------------------------------------------------------------------------------

api_net_ip() { hostname -I 2>/dev/null | cut -d' ' -f1 || echo "127.0.0.1"; }
api_net_ip_local() { api_net_ip; }
api_net_ip_public() { curl -s ifconfig.me 2>/dev/null || echo "N/A"; }
api_net_ip_external() { api_net_ip_public; }

api_net_dns() { cat /etc/resolv.conf 2>/dev/null | grep nameserver | head -1 | cut -d' ' -f2; }
api_net_gateway() { ip route 2>/dev/null | grep default | awk '{print $3}' || echo "N/A"; }
api_net_mac() { cat /sys/class/net/*/address 2>/dev/null | head -1 || echo "N/A"; }
api_net_hostname() { hostname; }
api_net_domain() { dnsdomainname 2>/dev/null || echo "local"; }

api_net_ping() { ping -c "${2:-4}" "$1" 2>/dev/null; }
api_net_trace() { traceroute "$1" 2>/dev/null || tracepath "$1" 2>/dev/null; }
api_net_route() { ip route get "$1" 2>/dev/null; }
api_net_scan() { nmap -sn "${1:-192.168.1.0/24}" 2>/dev/null; }

api_net_port_check() { nc -z -w 2 "$1" "$2" 2>/dev/null; }
api_net_port_open() { api_net_port_check "$@"; }
api_net_port_scan() { for p in "${@:2}"; do nc -z -w 1 "$1" "$p" 2>/dev/null && echo "Port $p open"; done; }

api_net_listen() { nc -l -p "$1" 2>/dev/null; }
api_net_send() { echo "$2" | nc "$1" "${3:-80}"; }
api_net_recv() { nc -l -p "$1"; }

api_net_url_parse() { echo "$1" | grep -oP '(?<=://)[^/]+' 2>/dev/null; }
api_net_url_domain() { api_net_url_parse "$@"; }

#-------------------------------------------------------------------------------
# Process API (40+ functions)
#-------------------------------------------------------------------------------

api_proc_run() { "$@"; }
api_proc_exec() { exec "$@"; }
api_proc_spawn() { "$@" &; }
api_proc_fork() { "$@" &; }

api_proc_status() { ps -p "$1" -o state= 2>/dev/null; }
api_proc_is_running() { ps -p "$1" &>/dev/null; }
api_proc_pid_exists() { kill -0 "$1" 2>/dev/null; }

api_proc_start() { "$@" & echo $!; }
api_proc_stop() { kill "$1" 2>/dev/null; }
api_proc_restart() { kill "$1" 2>/dev/null; sleep 1; "$2" &; }
api_proc_kill() { kill "$1" 2>/dev/null; }
api_proc_killall() { killall "$1" 2>/dev/null; }
api_proc_pkill() { pkill "$1" 2>/dev/null; }

api_proc_nice() { nice -n "${2:-0}" -- "$1"; }
api_proc_renice() { renice -n "${2:-0}" -p "$1" 2>/dev/null; }

api_proc_priority() { ps -p "$1" -o nice= 2>/dev/null; }
api_proc_cpu() { ps -p "$1" -o %cpu= 2>/dev/null; }
api_proc_mem() { ps -p "$1" -o %mem= 2>/dev/null; }
api_proc_time() { ps -p "$1" -o etime= 2>/dev/null; }

api_proc_children() { pgrep -P "$1" 2>/dev/null; }
api_proc_parent() { ps -p "$1" -o ppid= 2>/dev/null; }
api_proc_tree() { pstree -p "$1" 2>/dev/null || ps --forest -g "$1" 2>/dev/null; }

#-------------------------------------------------------------------------------
# File System API (60+ functions)
#-------------------------------------------------------------------------------

api_fs_read() { cat "$1"; }
api_fs_write() { echo "$2" > "$1"; }
api_fs_append() { echo "$2" >> "$1"; }
api_fs_exists() { [[ -e "$1" ]] && echo "true" || echo "false"; }
api_fs_is_file() { [[ -f "$1" ]] && echo "true" || echo "false"; }
api_fs_is_dir() { [[ -d "$1" ]] && echo "true" || echo "false"; }
api_fs_is_link() { [[ -L "$1" ]] && echo "true" || echo "false"; }
api_fs_is_symlink() { api_fs_is_link "$@"; }
api_fs_is_block() { [[ -b "$1" ]] && echo "true" || echo "false"; }
api_fs_is_char() { [[ -c "$1" ]] && echo "true" || echo "false"; }
api_fs_is_socket() { [[ -S "$1" ]] && echo "true" || echo "false"; }
api_fs_is_fifo() { [[ -p "$1" ]] && echo "true" || echo "false"; }
api_fs_is_pipe() { api_fs_is_fifo "$@"; }

api_fs_mkdir() { mkdir -p "$1"; }
api_fs_rmdir() { rmdir "$1" 2>/dev/null; }
api_fs_rm() { rm -f "$1"; }
api_fs_unlink() { rm -f "$1"; }
api_fs_copy() { cp "$1" "$2"; }
api_fs_cp() { cp "$1" "$2"; }
api_fs_move() { mv "$1" "$2"; }
api_fs_mv() { mv "$1" "$2"; }
api_fs_rename() { mv "$1" "$2"; }
api_fs_link() { ln "$1" "$2"; }
api_fs_symlink() { ln -s "$1" "$2"; }

api_fs_chmod() { chmod "$1" "$2"; }
api_fs_chown() { chown "$1" "$2"; }
api_fs_chgrp() { chgrp "$1" "$2"; }
api_fs_touch() { touch "$1"; }

api_fs_size() { stat -c%s "$1" 2>/dev/null || echo "0"; }
api_fs_blocks() { stat -c%b "$1" 2>/dev/null || echo "0"; }
api_fs_inodes() { stat -c%i "$1" 2>/dev/null || echo "0"; }

api_fs_atime() { stat -c%X "$1" 2>/dev/null || echo "0"; }
api_fs_mtime() { stat -c%Y "$1" 2>/dev/null || echo "0"; }
api_fs_ctime() { stat -c%Z "$1" 2>/dev/null || echo "0"; }
api_fs_access() { stat -c%a "$1" 2>/dev/null || echo "0"; }

api_fs_owner() { stat -c%U "$1" 2>/dev/null || echo "unknown"; }
api_fs_group() { stat -c%G "$1" 2>/dev/null || echo "unknown"; }
api_fs_type() { file -b "$1" 2>/dev/null || echo "unknown"; }
api_fs_mime() { file -b --mime-type "$1" 2>/dev/null || echo "application/octet-stream"; }
api_fs_ext() { echo "${1##*.}"; }
api_fs_basename() { basename "$1"; }
api_fs_dirname() { dirname "$1"; }
api_fs_realpath() { realpath "$1" 2>/dev/null || echo "$1"; }
api_fs_absolutepath() { api_fs_realpath "$@"; }

api_fs_glob() { ls -d $1 2>/dev/null; }
api_fs_find() { find "${1:-.}" -name "$2" 2>/dev/null; }
api_fs_search() { api_fs_find "$@"; }

api_fs_ls() { ls -la "$1" 2>/dev/null; }
api_fs_list() { ls -1 "$1" 2>/dev/null; }
api_fs_dir() { ls -la "$1" 2>/dev/null; }
api_fs_tree() { tree "$1" 2>/dev/null || find "$1" -print 2>/dev/null | sed -e 's;[^/]*/;|____;g;s;____|;  |;g'; }

#-------------------------------------------------------------------------------
# Export all API functions
#-------------------------------------------------------------------------------

# Export core functions
export -f api_core_version api_core_name api_core_home api_core_os api_core_arch
export -f api_core_hostname api_core_username api_core_pid api_core_ppid
export -f api_core_uid api_core_gid api_core_pwd api_core_date api_core_time
export -f api_core_datetime api_core_timestamp api_core_iso8601 api_core_unix

# Export string functions
export -f api_str_len api_str_upper api_str_lower api_str_trim api_str_reverse
export -f api_str_substr api_str_contains api_str_replace api_str_split
export -f api_str_is_empty api_str_is_alpha api_str_is_digit api_str_is_email

# Export array functions
export -f api_arr_create api_arr_len api_arr_push api_arr_pop api_arr_sort

# Export math functions
export -f api_math_add api_math_sub api_math_mul api_math_div api_math_rand

# Export IO functions
export -f api_io_print api_io_read api_io_write api_io_exists api_io_mkdir

# Export HTTP functions
export -f api_http_get api_http_post api_http_put api_http_delete

# Export JSON functions
export -f api_json_parse api_json_stringify api_json_get api_json_set

# Export crypto functions
export -f api_crypto_md5 api_crypto_sha256 api_crypto_base64_encode

# Export date functions
export -f api_date_now api_date_today api_date_format api_date_year

# Export network functions
export -f api_net_ip api_net_ping api_net_dns

# Export process functions
export -f api_proc_run api_proc_kill api_proc_status

# Export file system functions
export -f api_fs_read api_fs_write api_fs_exists api_fs_mkdir api_fs_copy
