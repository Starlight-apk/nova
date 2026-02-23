#!/bin/bash
#===============================================================================
# NovaScript Data API Library
# 数据处理 API - 100+ 函数
#===============================================================================

#-------------------------------------------------------------------------------
# CSV API
#-------------------------------------------------------------------------------
api_csv_parse() { echo "$1" | tr ',' '\n'; }
api_csv_stringify() { echo "$*" | tr '\n' ','; }
api_csv_read() { while IFS=, read -r line; do echo "$line"; done < "$1"; }
api_csv_write() { echo "$2" >> "$1"; }
api_csv_to_json() { head -1 "$1" | tr ',' '\n' | while read h; do echo "\"$h\":"; done; }
api_csv_from_json() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(','.join(d.keys()))" 2>/dev/null; }
api_csv_get_column() { cut -d',' -f"$2" "$1"; }
api_csv_get_row() { sed -n "${2}p" "$1"; }
api_csv_count() { wc -l < "$1"; }
api_csv_headers() { head -1 "$1"; }
api_csv_data() { tail -n +2 "$1"; }

#-------------------------------------------------------------------------------
# XML API
#-------------------------------------------------------------------------------
api_xml_parse() { echo "$1" | python3 -c "import sys,xml.etree.ElementTree as ET; print(ET.fromstring(sys.stdin.read()))" 2>/dev/null; }
api_xml_stringify() { echo "$1"; }
api_xml_get() { echo "$1" | grep -oP "<$2[^>]*>\\K[^<]*" 2>/dev/null; }
api_xml_find() { echo "$1" | grep -o "<$2[^>]*>[^<]*</$2>" 2>/dev/null; }
api_xml_count() { grep -c "<$2" <<< "$1"; }
api_xml_to_json() { echo "$1" | python3 -c "import sys,xml.etree.ElementTree as ET,json; t=ET.fromstring(sys.stdin.read()); print(json.dumps({t.tag: {c.tag:c.text for c in t}}))" 2>/dev/null; }
api_xml_validate() { echo "$1" | python3 -c "import sys,xml.etree.ElementTree as ET; ET.fromstring(sys.stdin.read())" 2>/dev/null && echo "true" || echo "false"; }

#-------------------------------------------------------------------------------
# YAML API
#-------------------------------------------------------------------------------
api_yaml_parse() { echo "$1" | python3 -c "import sys,yaml; print(yaml.safe_load(sys.stdin))" 2>/dev/null; }
api_yaml_stringify() { echo "$1" | python3 -c "import sys,yaml; print(yaml.dump(yaml.safe_load(sys.stdin)))" 2>/dev/null; }
api_yaml_to_json() { echo "$1" | python3 -c "import sys,yaml,json; print(json.dumps(yaml.safe_load(sys.stdin)))" 2>/dev/null; }
api_yaml_from_json() { echo "$1" | python3 -c "import sys,yaml,json; print(yaml.dump(json.load(sys.stdin)))" 2>/dev/null; }
api_yaml_get() { echo "$1" | python3 -c "import sys,yaml; d=yaml.safe_load(sys.stdin); print(d.get('$2',''))" 2>/dev/null; }
api_yaml_set() { echo "$1" | python3 -c "import sys,yaml; d=yaml.safe_load(sys.stdin); d['$2']=$3; print(yaml.dump(d))" 2>/dev/null; }

#-------------------------------------------------------------------------------
# TOML API
#-------------------------------------------------------------------------------
api_toml_parse() { echo "$1" | python3 -c "import sys,toml; print(toml.loads(sys.stdin.read()))" 2>/dev/null; }
api_toml_stringify() { echo "$1" | python3 -c "import sys,toml; print(toml.dumps(toml.loads(sys.stdin.read())))" 2>/dev/null; }
api_toml_to_json() { echo "$1" | python3 -c "import sys,toml,json; print(json.dumps(toml.loads(sys.stdin.read())))" 2>/dev/null; }
api_toml_get() { echo "$1" | python3 -c "import sys,toml; d=toml.loads(sys.stdin.read()); print(d.get('$2',''))" 2>/dev/null; }

#-------------------------------------------------------------------------------
# Query API
#-------------------------------------------------------------------------------
api_query_select() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(v) for v in eval('d$2')]" 2>/dev/null; }
api_query_where() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(i) for i,v in enumerate(d) if $2]" 2>/dev/null; }
api_query_filter() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps([i for i in d if $2]))" 2>/dev/null; }
api_query_map() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps([$2 for i in d]))" 2>/dev/null; }
api_query_reduce() { echo "$1" | python3 -c "import sys,json,functools; d=json.load(sys.stdin); print(functools.reduce($2,d))" 2>/dev/null; }
api_query_find() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(next((i for i in d if $2),None))" 2>/dev/null; }
api_query_sort() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(sorted(d,key=lambda x:$2)))" 2>/dev/null; }
api_query_group() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); from itertools import groupby; print(json.dumps({k:list(g) for k,g in groupby(sorted(d,key=lambda x:$2),key=lambda x:$2)}))" 2>/dev/null; }

#-------------------------------------------------------------------------------
# Transform API
#-------------------------------------------------------------------------------
api_transform_upper() { echo "$1" | tr '[:lower:]' '[:upper:]'; }
api_transform_lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }
api_transform_title() { echo "$1" | sed 's/\b\(.\)/\u\1/g'; }
api_transform_reverse() { echo "$1" | rev; }
api_transform_rot13() { echo "$1" | tr 'A-Za-z' 'N-ZA-Mn-za-m'; }
api_transform_base64() { echo "$1" | base64; }
api_transform_urlencode() { python3 -c "import urllib.parse; print(urllib.parse.quote('$1'))" 2>/dev/null; }
api_transform_htmlencode() { echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'; }
api_transform_json_encode() { echo "$1" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))" 2>/dev/null; }

#-------------------------------------------------------------------------------
# Validate API
#-------------------------------------------------------------------------------
api_validate_email() { [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] && echo "true" || echo "false"; }
api_validate_url() { [[ "$1" =~ ^https?://[a-zA-Z0-9] ]] && echo "true" || echo "false"; }
api_validate_ip() { [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo "true" || echo "false"; }
api_validate_ipv6() { [[ "$1" =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]] && echo "true" || echo "false"; }
api_validate_mac() { [[ "$1" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]] && echo "true" || echo "false"; }
api_validate_phone() { [[ "$1" =~ ^\+?[0-9\s\-\(\)]{8,20}$ ]] && echo "true" || echo "false"; }
api_validate_credit_card() { [[ "$1" =~ ^[0-9]{13,19}$ ]] && echo "true" || echo "false"; }
api_validate_zip() { [[ "$1" =~ ^[0-9]{5}(-[0-9]{4})?$ ]] && echo "true" || echo "false"; }
api_validate_date() { [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && echo "true" || echo "false"; }
api_validate_time() { [[ "$1" =~ ^[0-9]{2}:[0-9]{2}(:[0-9]{2})?$ ]] && echo "true" || echo "false"; }
api_validate_datetime() { [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2} ]] && echo "true" || echo "false"; }
api_validate_uuid() { [[ "$1" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] && echo "true" || echo "false"; }
api_validate_json() { echo "$1" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null && echo "true" || echo "false"; }
api_validate_xml() { echo "$1" | python3 -c "import sys,xml.etree.ElementTree as ET; ET.fromstring(sys.stdin.read())" 2>/dev/null && echo "true" || echo "false"; }
api_validate_integer() { [[ "$1" =~ ^-?[0-9]+$ ]] && echo "true" || echo "false"; }
api_validate_float() { [[ "$1" =~ ^-?[0-9]+\.[0-9]+$ ]] && echo "true" || echo "false"; }
api_validate_number() { [[ "$1" =~ ^-?[0-9]+\.?[0-9]*$ ]] && echo "true" || echo "false"; }
api_validate_boolean() { [[ "$1" == "true" || "$1" == "false" || "$1" == "0" || "$1" == "1" ]] && echo "true" || echo "false"; }
api_validate_required() { [[ -n "$1" ]] && echo "true" || echo "false"; }
api_validate_min_length() { [[ ${#1} -ge $2 ]] && echo "true" || echo "false"; }
api_validate_max_length() { [[ ${#1} -le $2 ]] && echo "true" || echo "false"; }
api_validate_length() { [[ ${#1} -eq $2 ]] && echo "true" || echo "false"; }
api_validate_min() { [[ $1 -ge $2 ]] && echo "true" || echo "false"; }
api_validate_max() { [[ $1 -le $2 ]] && echo "true" || echo "false"; }
api_validate_range() { [[ $1 -ge $2 && $1 -le $3 ]] && echo "true" || echo "false"; }
api_validate_in() { local v="$1"; shift; for i in "$@"; do [[ "$v" == "$i" ]] && { echo "true"; return; }; done; echo "false"; }
api_validate_regex() { [[ "$1" =~ $2 ]] && echo "true" || echo "false"; }

#-------------------------------------------------------------------------------
# Convert API
#-------------------------------------------------------------------------------
api_convert_to_int() { echo "$((10#${1:-0}))"; }
api_convert_to_float() { printf "%f" "${1:-0}"; }
api_convert_to_string() { echo "$1"; }
api_convert_to_bool() { [[ "$1" == "true" || "$1" == "1" || "$1" == "yes" ]] && echo "true" || echo "false"; }
api_convert_to_array() { echo "$1" | tr ',' '\n'; }
api_convert_to_json() { echo "$1" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))" 2>/dev/null; }
api_convert_from_json() { echo "$1" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d)" 2>/dev/null; }
api_convert_to_base64() { echo -n "$1" | base64; }
api_convert_from_base64() { echo -n "$1" | base64 -d; }
api_convert_to_hex() { echo -n "$1" | xxd -p 2>/dev/null; }
api_convert_from_hex() { echo -n "$1" | xxd -r -p 2>/dev/null; }
api_convert_to_binary() { printf "%d" "$1" | awk '{str="";n=$1;while(n>0){str=n%2 str;n=int(n/2)}print str}'; }
api_convert_from_binary() { echo "$((2#$1))"; }
api_convert_to_octal() { printf "%o" "$1"; }
api_convert_from_octal() { echo "$((8#$1))"; }
api_convert_deg2rad() { echo "$1 * 3.14159265359 / 180" | bc -l 2>/dev/null; }
api_convert_rad2deg() { echo "$1 * 180 / 3.14159265359" | bc -l 2>/dev/null; }
api_convert_km2mi() { echo "$1 * 0.621371" | bc -l 2>/dev/null; }
api_convert_mi2km() { echo "$1 * 1.60934" | bc -l 2>/dev/null; }
api_convert_kg2lb() { echo "$1 * 2.20462" | bc -l 2>/dev/null; }
api_convert_lb2kg() { echo "$1 * 0.453592" | bc -l 2>/dev/null; }
api_convert_c2f() { echo "$1 * 9/5 + 32" | bc -l 2>/dev/null; }
api_convert_f2c() { echo "($1 - 32) * 5/9" | bc -l 2>/dev/null; }
api_convert_m2ft() { echo "$1 * 3.28084" | bc -l 2>/dev/null; }
api_convert_ft2m() { echo "$1 * 0.3048" | bc -l 2>/dev/null; }
api_convert_l2gal() { echo "$1 * 0.264172" | bc -l 2>/dev/null; }
api_convert_gal2l() { echo "$1 * 3.78541" | bc -l 2>/dev/null; }

#-------------------------------------------------------------------------------
# Cache API
#-------------------------------------------------------------------------------
api_cache_dir="${NOVA_CACHE_DIR:-/tmp/nova_cache}"

api_cache_init() { mkdir -p "$api_cache_dir"; }
api_cache_set() { echo "$2" > "$api_cache_dir/$1"; }
api_cache_get() { cat "$api_cache_dir/$1" 2>/dev/null; }
api_cache_has() { [[ -f "$api_cache_dir/$1" ]]; }
api_cache_delete() { rm -f "$api_cache_dir/$1"; }
api_cache_clear() { rm -rf "$api_cache_dir"/*; }
api_cache_ttl() { local f="$api_cache_dir/$1"; [[ -f "$f" ]] && { local now=$(date +%s); local mtime=$(stat -c%Y "$f" 2>/dev/null); echo $((now - mtime)); } || echo "-1"; }
api_cache_expired() { local ttl=$(api_cache_ttl "$1"); [[ $ttl -gt ${2:-3600} ]] && echo "true" || echo "false"; }
api_cache_remember() { local key="$1" cmd="$2"; local val=$(api_cache_get "$key"); if [[ -z "$val" ]]; then val=$($cmd); api_cache_set "$key" "$val"; fi; echo "$val"; }

#-------------------------------------------------------------------------------
# Log API
#-------------------------------------------------------------------------------
api_log_dir="${NOVA_LOG_DIR:-$HOME/.nova/logs}"

api_log_init() { mkdir -p "$api_log_dir"; }
api_log_write() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$api_log_dir/nova.log"; }
api_log_info() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >> "$api_log_dir/nova.log"; }
api_log_warn() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $*" >> "$api_log_dir/nova.log"; }
api_log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >> "$api_log_dir/nova.log"; }
api_log_debug() { [[ "${NOVA_DEBUG:-}" == "true" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $*" >> "$api_log_dir/nova.log"; }
api_log_read() { cat "$api_log_dir/nova.log"; }
api_log_tail() { tail -${2:-100} "$api_log_dir/nova.log"; }
api_log_clear() { rm -f "$api_log_dir"/*.log; }
api_log_rotate() { [[ -f "$api_log_dir/nova.log" ]] && mv "$api_log_dir/nova.log" "$api_log_dir/nova.log.$(date +%Y%m%d)"; }

#-------------------------------------------------------------------------------
# Config API
#-------------------------------------------------------------------------------
api_config_dir="${NOVA_CONFIG_DIR:-$HOME/.nova}"
api_config_file="${api_config_dir}/config.json"

api_config_init() { mkdir -p "$api_config_dir"; [[ ! -f "$api_config_file" ]] && echo '{}' > "$api_config_file"; }
api_config_get() { cat "$api_config_file" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$1',''))" 2>/dev/null; }
api_config_set() { local k="$1" v="$2"; python3 -c "import json; d=json.load(open('$api_config_file')); d['$k']=$v; json.dump(d,open('$api_config_file','w'))" 2>/dev/null; }
api_config_has() { cat "$api_config_file" | python3 -c "import sys,json; d=json.load(sys.stdin); print('$1' in d)" 2>/dev/null; }
api_config_delete() { python3 -c "import json; d=json.load(open('$api_config_file')); del d['$1']; json.dump(d,open('$api_config_file','w'))" 2>/dev/null; }
api_config_all() { cat "$api_config_file"; }
api_config_reset() { echo '{}' > "$api_config_file"; }

#-------------------------------------------------------------------------------
# Events API
#-------------------------------------------------------------------------------
declare -A api_events_handlers

api_events_on() { local event="$1" handler="$2"; api_events_handlers["$event"]+="$handler "; }
api_events_off() { local event="$1"; unset api_events_handlers["$event"]; }
api_events_emit() { local event="$1"; shift; for handler in ${api_events_handlers["$event"]}; do $handler "$@"; done; }
api_events_once() { local event="$1" handler="$2"; api_events_on "$event" "$handler && api_events_off '$event'"; }
api_events_listeners() { echo "${!api_events_handlers[@]}"; }

#-------------------------------------------------------------------------------
# Export functions
#-------------------------------------------------------------------------------
export -f api_csv_parse api_csv_stringify api_csv_read api_csv_write
export -f api_xml_parse api_xml_get api_xml_find api_xml_count
export -f api_yaml_parse api_yaml_stringify api_yaml_get api_yaml_set
export -f api_query_select api_query_where api_query_filter api_query_map
export -f api_transform_upper api_transform_lower api_transform_reverse
export -f api_validate_email api_validate_url api_validate_ip api_validate_json
export -f api_convert_to_int api_convert_to_float api_convert_to_bool
export -f api_cache_set api_cache_get api_cache_has api_cache_delete api_cache_clear
export -f api_log_write api_log_info api_log_error api_log_read api_log_tail
export -f api_config_get api_config_set api_config_has api_config_delete
export -f api_events_on api_events_off api_events_emit
