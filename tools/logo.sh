#!/bin/bash
#===============================================================================
# NovaScript Logo Display
# 彩色 Logo + Neofetch 风格系统信息
#===============================================================================

#-------------------------------------------------------------------------------
# 颜色定义
#-------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BRIGHT_RED='\033[1;31m'
BRIGHT_GREEN='\033[1;32m'
BRIGHT_YELLOW='\033[1;33m'
BRIGHT_BLUE='\033[1;34m'
BRIGHT_MAGENTA='\033[1;35m'
BRIGHT_CYAN='\033[1;36m'
BRIGHT_WHITE='\033[1;37m'

# 渐变颜色
GRADIENT1='\033[38;5;75m'
GRADIENT2='\033[38;5;69m'
GRADIENT3='\033[38;5;63m'
GRADIENT4='\033[38;5;57m'
GRADIENT5='\033[38;5;56m'

# 重置
NC='\033[0m'

#-------------------------------------------------------------------------------
# 获取系统信息
#-------------------------------------------------------------------------------
get_os() {
    if [[ -n "${TERMUX_VERSION:-}" ]] || [[ -d "/data/data/com.termux" ]]; then
        echo "Termux (Android)"
    else
        uname -s 2>/dev/null || echo "Unknown"
    fi
}

get_kernel() {
    uname -r 2>/dev/null || echo "Unknown"
}

get_arch() {
    uname -m 2>/dev/null || echo "Unknown"
}

get_shell() {
    echo "${SHELL##*/}"
}

get_bash_version() {
    echo "$BASH_VERSION"
}

get_uptime() {
    if [[ -f /proc/uptime ]]; then
        local uptime_seconds=$(cut -d. -f1 /proc/uptime)
        local days=$((uptime_seconds / 86400))
        local hours=$(((uptime_seconds % 86400) / 3600))
        local mins=$(((uptime_seconds % 3600) / 60))
        
        if [[ $days -gt 0 ]]; then
            echo "${days}d ${hours}h ${mins}m"
        elif [[ $hours -gt 0 ]]; then
            echo "${hours}h ${mins}m"
        else
            echo "${mins}m"
        fi
    else
        echo "Unknown"
    fi
}

get_memory() {
    if command -v free &>/dev/null; then
        local total=$(free -m | awk 'NR==2{print $2}')
        local used=$(free -m | awk 'NR==2{print $3}')
        echo "${used}MiB / ${total}MiB"
    else
        echo "Unknown"
    fi
}

get_disk() {
    if [[ -d "$NOVA_HOME" ]]; then
        local used=$(du -sh "$NOVA_HOME" 2>/dev/null | cut -f1)
        echo "${used:-Unknown}"
    else
        echo "Unknown"
    fi
}

get_packages() {
    local count=0
    if [[ -d "$NOVA_HOME/packages" ]]; then
        count=$(find "$NOVA_HOME/packages" -maxdepth 1 -type d 2>/dev/null | wc -l)
        count=$((count - 1))  # 减去 packages 目录本身
    fi
    echo "$count"
}

get_hostname() {
    hostname 2>/dev/null || echo "unknown"
}

get_user() {
    echo "${USER:-$(whoami 2>/dev/null || echo "unknown")}"
}

#-------------------------------------------------------------------------------
# Logo ASCII 艺术（无版本号）
#-------------------------------------------------------------------------------
print_logo_ascii() {
    echo -e "${GRADIENT1} █████╗  ██████╗  ██████╗  ███████╗${NC}"
    echo -e "${GRADIENT3}██╔══██╗██╔═══██╗██╔═══██╗██╔════╝${NC}"
    echo -e "${GRADIENT4}███████║██║   ██║██║   ██║███████╗${NC}"
    echo -e "${GRADIENT5}██╔══██║██║   ██║██║   ██║╚════██║${NC}"
    echo -e "${BRIGHT_MAGENTA}██║  ██║╚██████╔╝╚██████╔╝███████║${NC}"
    echo -e "${BRIGHT_RED}╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚══════╝${NC}"
}

#-------------------------------------------------------------------------------
# Neofetch 风格显示
#-------------------------------------------------------------------------------
print_neofetch() {
    local logo_lines=6
    local info_lines=14
    
    # 获取所有信息
    local os_info=$(get_os)
    local kernel_info=$(get_kernel)
    local arch_info=$(get_arch)
    local shell_info=$(get_shell)
    local bash_info=$(get_bash_version)
    local uptime_info=$(get_uptime)
    local memory_info=$(get_memory)
    local disk_info=$(get_disk)
    local packages_info=$(get_packages)
    local hostname_info=$(get_hostname)
    local user_info=$(get_user)
    
    echo ""
    
    # 第 1 行 - Logo + 标题
    echo -e "  ${GRADIENT1} █████╗  ██████╗  ██████╗  ███████╗${NC}    ${BRIGHT_WHITE}${user_info}${NC}@${BRIGHT_WHITE}${hostname_info}${NC}"
    
    # 第 2 行
    echo -e "  ${GRADIENT3}██╔══██╗██╔═══██╗██╔═══██╗██╔════╝${NC}    ${BRIGHT_CYAN}─────────────────${NC}"
    
    # 第 3 行 + OS
    printf "  ${GRADIENT4}███████║██║   ██║██║   ██║███████╗${NC}    ${BRIGHT_WHITE}OS:${NC}            %s\n" "$os_info"
    
    # 第 4 行 + Kernel
    printf "  ${GRADIENT5}██╔══██║██║   ██║██║   ██║╚════██║${NC}    ${BRIGHT_WHITE}Kernel:${NC}        %s\n" "$kernel_info"
    
    # 第 5 行 + Arch
    printf "  ${BRIGHT_MAGENTA}██║  ██║╚██████╔╝╚██████╔╝███████║${NC}    ${BRIGHT_WHITE}Architecture:${NC}  %s\n" "$arch_info"
    
    # 第 6 行 + Shell
    printf "  ${BRIGHT_RED}╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚══════╝${NC}    ${BRIGHT_WHITE}Shell:${NC}         %s\n" "$shell_info"
    
    # 额外信息行
    echo -e "                                       ${BRIGHT_WHITE}Bash:${NC}          $bash_info"
    echo -e "                                       ${BRIGHT_WHITE}Uptime:${NC}        $uptime_info"
    echo -e "                                       ${BRIGHT_WHITE}Memory:${NC}        $memory_info"
    echo -e "                                       ${BRIGHT_WHITE}Packages:${NC}      $packages_info"
    echo -e "                                       ${BRIGHT_WHITE}Nova Home:${NC}     $NOVA_HOME"
    
    # 标语
    echo ""
    echo -e "         ${BRIGHT_YELLOW}✨${NC} ${BRIGHT_CYAN}The Future of Scripting${NC} ${BRIGHT_YELLOW}✨${NC}"
    echo ""
}

#-------------------------------------------------------------------------------
# 仅 Logo（小型）
#-------------------------------------------------------------------------------
print_logo_only() {
    echo ""
    echo -e "${GRADIENT1} █████╗  ██████╗  ██████╗  ███████╗${NC}"
    echo -e "${GRADIENT3}██╔══██╗██╔═══██╗██╔═══██╗██╔════╝${NC}"
    echo -e "${GRADIENT4}███████║██║   ██║██║   ██║███████╗${NC}"
    echo -e "${GRADIENT5}██╔══██║██║   ██║██║   ██║╚════██║${NC}"
    echo -e "${BRIGHT_MAGENTA}██║  ██║╚██████╔╝╚██████╔╝███████║${NC}"
    echo -e "${BRIGHT_RED}╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚══════╝${NC}"
    echo ""
}

#-------------------------------------------------------------------------------
# 动画 Logo
#-------------------------------------------------------------------------------
print_logo_animated() {
    local delay=0.1
    
    echo ""
    echo -ne "${GRADIENT1} █████╗${NC}"; sleep $delay
    echo -ne "  ${BRIGHT_CYAN}██████╗${NC}"; sleep $delay
    echo -ne "  ${BRIGHT_CYAN}██████╗${NC}"; sleep $delay
    echo -ne "  ${GRADIENT1}███████╗${NC}"; sleep $delay
    echo ""
    
    echo -ne "${GRADIENT3}██╔══██╗${NC}"; sleep $delay
    echo -ne "${BRIGHT_CYAN}██╔═══██╗${NC}"; sleep $delay
    echo -ne "${BRIGHT_CYAN}██╔═══██╗${NC}"; sleep $delay
    echo -ne "${GRADIENT3}██╔════╝${NC}"; sleep $delay
    echo ""
    
    echo -ne "${GRADIENT4}███████║${NC}"; sleep $delay
    echo -ne "${BRIGHT_CYAN}██║   ██║${NC}"; sleep $delay
    echo -ne "${BRIGHT_CYAN}██║   ██║${NC}"; sleep $delay
    echo -ne "${GRADIENT4}███████╗${NC}"; sleep $delay
    echo ""
    
    echo -ne "${GRADIENT5}██╔══██║${NC}"; sleep $delay
    echo -ne "${BRIGHT_CYAN}██║   ██║${NC}"; sleep $delay
    echo -ne "${BRIGHT_CYAN}██║   ██║${NC}"; sleep $delay
    echo -ne "${GRADIENT5}╚════██║${NC}"; sleep $delay
    echo ""
    
    echo -ne "${BRIGHT_MAGENTA}██║  ██║${NC}"; sleep $delay
    echo -ne "${BRIGHT_CYAN}╚██████╔╝${NC}"; sleep $delay
    echo -ne "${BRIGHT_CYAN}╚██████╔╝${NC}"; sleep $delay
    echo -ne "${BRIGHT_MAGENTA}███████║${NC}"; sleep $delay
    echo ""
    
    echo -ne "${BRIGHT_RED}╚═╝  ╚═╝${NC}"; sleep $delay
    echo -ne "${BRIGHT_CYAN} ╚═════╝${NC}"; sleep $delay
    echo -ne "${BRIGHT_CYAN} ╚═════╝${NC}"; sleep $delay
    echo -ne "${BRIGHT_RED}╚══════╝${NC}"; sleep $delay
    echo ""
}

#-------------------------------------------------------------------------------
# 彩虹 Logo
#-------------------------------------------------------------------------------
print_logo_rainbow() {
    echo ""
    echo -e "${RED} █████╗  ██████╗  ██████╗  ███████╗${NC}"
    echo -e "${YELLOW}██╔══██╗██╔═══██╗██╔═══██╗██╔════╝${NC}"
    echo -e "${GREEN}███████║██║   ██║██║   ██║███████╗${NC}"
    echo -e "${CYAN}██╔══██║██║   ██║██║   ██║╚════██║${NC}"
    echo -e "${BLUE}██║  ██║╚██████╔╝╚██████╔╝███████║${NC}"
    echo -e "${MAGENTA}╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚══════╝${NC}"
    echo ""
}

#-------------------------------------------------------------------------------
# 主函数
#-------------------------------------------------------------------------------
main() {
    local mode="${1:-neofetch}"
    
    # 确保 NOVA_HOME 已设置
    export NOVA_HOME="${NOVA_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
    
    case "$mode" in
        neofetch|n|neo)
            print_neofetch
            ;;
        logo|l|small|s)
            print_logo_only
            ;;
        animated|a|anim)
            print_logo_animated
            ;;
        rainbow|r|rainbow)
            print_logo_rainbow
            ;;
        full|f|*)
            print_neofetch
            ;;
    esac
}

# 如果直接运行则执行 main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
