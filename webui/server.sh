#!/bin/bash
#===============================================================================
# NovaScript WebUI Server
# 基于纯 Bash 的轻量级 HTTP 服务器
#===============================================================================

set -euo pipefail

# 配置
WEBUI_HOST="${WEBUI_HOST:-127.0.0.1}"
WEBUI_PORT="${WEBUI_PORT:-8080}"
WEBUI_ROOT="${NOVA_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
WEBUI_DEBUG="${WEBUI_DEBUG:-false}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%H:%M:%S') $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $(date '+%H:%M:%S') $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%H:%M:%S') $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%H:%M:%S') $1"
}

#-------------------------------------------------------------------------------
# MIME 类型
#-------------------------------------------------------------------------------
get_mime_type() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        html) echo "text/html" ;;
        css)  echo "text/css" ;;
        js)   echo "application/javascript" ;;
        json) echo "application/json" ;;
        png)  echo "image/png" ;;
        jpg|jpeg) echo "image/jpeg" ;;
        gif)  echo "image/gif" ;;
        svg)  echo "image/svg+xml" ;;
        ico)  echo "image/x-icon" ;;
        txt)  echo "text/plain" ;;
        md)   echo "text/markdown" ;;
        nova) echo "text/plain" ;;
        *)    echo "application/octet-stream" ;;
    esac
}

#-------------------------------------------------------------------------------
# URL 解码
#-------------------------------------------------------------------------------
url_decode() {
    local url="${1//+/ }"
    printf '%b' "${url//%/\\x}"
}

#-------------------------------------------------------------------------------
# 处理 API 请求
#-------------------------------------------------------------------------------
handle_api() {
    local endpoint="$1"
    local method="$2"
    local data="$3"
    
    case "$endpoint" in
        /api/status)
            echo '{"status":"running","version":"1.0.0","uptime":"'"$(uptime -p 2>/dev/null || echo "N/A")"'"}'
            ;;
        /api/files/list)
            local path="${data:-.}"
            path=$(url_decode "$path")
            if [[ -d "$path" ]]; then
                echo '{"files":['
                local first=true
                for f in "$path"/*; do
                    [[ -e "$f" ]] || continue
                    local name=$(basename "$f")
                    local type="file"
                    [[ -d "$f" ]] && type="dir"
                    local size=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo "0")
                    if [[ "$first" == true ]]; then
                        first=false
                    else
                        echo ","
                    fi
                    echo '{"name":"'"$name"'","type":"'"$type"'","size":'"$size"'}'
                done
                echo ']}'
            else
                echo '{"error":"Directory not found"}'
            fi
            ;;
        /api/files/read)
            local path=$(url_decode "$data")
            if [[ -f "$path" ]]; then
                cat "$path" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g'
            else
                echo '{"error":"File not found"}'
            fi
            ;;
        /api/files/save)
            # 解析 JSON 数据
            local path=$(echo "$data" | grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
            local content=$(echo "$data" | grep -o '"content"[[:space:]]*:[[:space:]]*".*"' | cut -d'"' -f4-)
            content="${content%\"*}"
            if [[ -n "$path" ]]; then
                echo -e "$content" > "$path"
                echo '{"success":true}'
            else
                echo '{"error":"Invalid path"}'
            fi
            ;;
        /api/terminal/exec)
            local cmd=$(url_decode "$data")
            local result=$(eval "$cmd" 2>&1)
            echo '{"output":"'"$(echo "$result" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')"'"}'
            ;;
        /api/packages/list)
            echo '{"packages":['
            local first=true
            for pkg in "$WEBUI_ROOT/packages/"*; do
                [[ -d "$pkg" ]] || continue
                local name=$(basename "$pkg")
                if [[ "$first" == true ]]; then
                    first=false
                else
                    echo ","
                fi
                local desc="Package: $name"
                [[ -f "$pkg/description.txt" ]] && desc=$(cat "$pkg/description.txt")
                echo '{"name":"'"$name"'","description":"'"$desc"'","installed":true}'
            done
            echo ']}'
            ;;
        /api/projects/create)
            local name=$(echo "$data" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
            local template=$(echo "$data" | grep -o '"template"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
            if [[ -n "$name" ]]; then
                mkdir -p "$name"/{src,lib,test}
                echo '{"success":true,"path":"'"$name"'"}'
            else
                echo '{"error":"Invalid name"}'
            fi
            ;;
        /api/system/info)
            echo '{
                "os":"'"$(uname -s)"'",
                "arch":"'"$(uname -m)"'",
                "hostname":"'"$(hostname 2>/dev/null || echo "unknown")"'",
                "user":"'"${USER:-unknown}"'",
                "home":"'"$HOME"'",
                "nova_version":"1.0.0",
                "termux":"'"${NOVA_IS_TERMUX:-false}"'"
            }'
            ;;
        *)
            echo '{"error":"Unknown endpoint"}'
            ;;
    esac
}

#-------------------------------------------------------------------------------
# 处理 HTTP 请求
#-------------------------------------------------------------------------------
handle_request() {
    local request="$1"
    local response=""
    local status="200 OK"
    local content_type="text/html"
    local body=""
    
    # 解析请求行
    local method=$(echo "$request" | head -1 | cut -d' ' -f1)
    local path=$(echo "$request" | head -1 | cut -d' ' -f2)
    local query=""
    
    # 分离路径和查询参数
    if [[ "$path" == *"?"* ]]; then
        query="${path#*\?}"
        path="${path%%\?*}"
    fi
    
    # 提取请求体
    local body_data=$(echo "$request" | tail -1)
    
    log_info "$method $path"
    
    # API 路由
    if [[ "$path" == /api/* ]]; then
        body=$(handle_api "$path" "$method" "$body_data")
        content_type="application/json"
    # 静态文件
    elif [[ "$path" == /static/* ]]; then
        local file="$WEBUI_ROOT/webui${path}"
        if [[ -f "$file" ]]; then
            body=$(cat "$file")
            content_type=$(get_mime_type "$file")
        else
            status="404 Not Found"
            body="<h1>404 Not Found</h1>"
        fi
    # 主页面
    elif [[ "$path" == "/" ]] || [[ "$path" == "/index.html" ]]; then
        body=$(cat "$WEBUI_ROOT/webui/templates/index.html")
    # 其他页面
    elif [[ -f "$WEBUI_ROOT/webui/templates${path}.html" ]]; then
        body=$(cat "$WEBUI_ROOT/webui/templates${path}.html")
    else
        status="404 Not Found"
        body="<h1>404 Not Found</h1>"
    fi
    
    # 构建响应头
    local content_length=${#body}
    response="HTTP/1.1 $status\r\n"
    response+="Content-Type: $content_type\r\n"
    response+="Content-Length: $content_length\r\n"
    response+="Connection: close\r\n"
    response+="\r\n"
    response+="$body"
    
    echo -e "$response"
}

#-------------------------------------------------------------------------------
# 启动服务器
#-------------------------------------------------------------------------------
start_server() {
    log_info "Starting NovaScript WebUI Server..."
    log_info "Host: $WEBUI_HOST"
    log_info "Port: $WEBUI_PORT"
    log_info "Root: $WEBUI_ROOT"
    echo ""
    log_success "Server is running!"
    log_info "Open http://$WEBUI_HOST:$WEBUI_PORT in your browser"
    echo ""
    log_info "Press Ctrl+C to stop"
    echo ""
    
    # 创建命名管道
    local fifo="/tmp/nova_webui_$$"
    mkfifo "$fifo"
    
    # 启动 netcat 监听
    if command -v nc &>/dev/null; then
        while true; do
            nc -l -p "$WEBUI_PORT" -q 1 < "$fifo" | while read -r line; do
                request+="$line"$'\n'
                # 检测请求结束（空行）
                if [[ -z "${line//$'\r'}" ]]; then
                    response=$(handle_request "$request")
                    echo -e "$response" > "$fifo"
                    request=""
                    break
                fi
            done
        done
    elif command -v socat &>/dev/null; then
        while true; do
            socat TCP-LISTEN:$WEBUI_PORT,reuseaddr,fork SYSTEM:"bash -c 'handle_request'"
        done
    else
        log_error "Neither nc nor socat found. Please install one of them."
        log_info "Termux: pkg install netcat-openbsd"
        log_info "Linux: apt install netcat-openbsd"
        exit 1
    fi
    
    # 清理
    rm -f "$fifo"
}

#-------------------------------------------------------------------------------
# 使用 Python 作为后备
#-------------------------------------------------------------------------------
start_with_python() {
    log_info "Starting WebUI with Python backend..."
    
    python3 -c "
import http.server
import socketserver
import os
import json
import urllib.parse
import subprocess
from http import HTTPStatus

PORT = $WEBUI_PORT
HOST = '$WEBUI_HOST'
WEBUI_ROOT = '$WEBUI_ROOT'

class NovaHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEBUI_ROOT + '/webui/templates', **kwargs)
    
    def do_GET(self):
        if self.path.startswith('/api/'):
            self.handle_api()
        elif self.path.startswith('/static/'):
            self.path = self.path.replace('/static/', WEBUI_ROOT + '/webui/static/')
            super().do_GET()
        elif self.path == '/':
            self.path = WEBUI_ROOT + '/webui/templates/index.html'
            super().do_GET()
        else:
            super().do_GET()
    
    def do_POST(self):
        if self.path.startswith('/api/'):
            self.handle_api()
        else:
            self.send_error(HTTPStatus.NOT_FOUND)
    
    def handle_api(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8') if content_length > 0 else ''
        
        path = self.path.split('?')[0]
        
        response = {}
        
        if path == '/api/status':
            response = {'status': 'running', 'version': '1.0.0'}
        elif path == '/api/system/info':
            import platform
            response = {
                'os': platform.system(),
                'arch': platform.machine(),
                'hostname': subprocess.getoutput('hostname 2>/dev/null || echo unknown'),
                'user': os.environ.get('USER', 'unknown'),
                'nova_version': '1.0.0'
            }
        elif path == '/api/packages/list':
            packages = []
            pkg_dir = WEBUI_ROOT + '/packages'
            if os.path.isdir(pkg_dir):
                for name in os.listdir(pkg_dir):
                    pkg_path = os.path.join(pkg_dir, name)
                    if os.path.isdir(pkg_path):
                        desc = name
                        desc_file = os.path.join(pkg_path, 'description.txt')
                        if os.path.isfile(desc_file):
                            with open(desc_file) as f:
                                desc = f.read().strip()
                        packages.append({'name': name, 'description': desc, 'installed': True})
            response = {'packages': packages}
        elif path == '/api/files/list':
            query = urllib.parse.parse_qs(self.path.split('?')[1]) if '?' in self.path else {}
            path = query.get('path', ['.'])[0]
            path = urllib.parse.unquote(path)
            files = []
            if os.path.isdir(path):
                for name in os.listdir(path):
                    full_path = os.path.join(path, name)
                    files.append({
                        'name': name,
                        'type': 'dir' if os.path.isdir(full_path) else 'file',
                        'size': os.path.getsize(full_path) if os.path.isfile(full_path) else 0
                    })
            response = {'files': files}
        
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(response).encode())

class ReuseAddrServer(socketserver.TCPServer):
    allow_reuse_address = True

with ReuseAddrServer((HOST, PORT), NovaHandler) as httpd:
    print(f'NovaScript WebUI running at http://{HOST}:{PORT}')
    print('Press Ctrl+C to stop')
    httpd.serve_forever()
"
}

#-------------------------------------------------------------------------------
# 主函数
#-------------------------------------------------------------------------------
main() {
    local mode="${1:-auto}"
    
    case "$mode" in
        nc|netcat)
            start_server
            ;;
        python|py)
            start_with_python
            ;;
        auto)
            # 优先尝试 Python（更稳定）
            if command -v python3 &>/dev/null; then
                start_with_python
            elif command -v nc &>/dev/null; then
                start_server
            else
                log_error "No suitable backend found"
                log_info "Please install python3 or netcat"
                exit 1
            fi
            ;;
        *)
            echo "Usage: webui.sh [auto|nc|python]"
            exit 1
            ;;
    esac
}

main "$@"
