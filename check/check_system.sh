#!/bin/bash
#==============================================================================
# Check System
# Kiểm tra OS, disk space, ports
#==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

SPANEL_DIR="${SPANEL_DIR:-/var/server}"
NGINX_PORT="${NGINX_PORT:-80}"
NGINX_SSL_PORT="${NGINX_SSL_PORT:-443}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_check() { echo -e "${BLUE}[CHECK]${NC} $1"; }
log_fix() { echo -e "${YELLOW}[FIX]${NC} $1"; }

#------------------------------------------------------------------------------
# Kiểm tra OS
#------------------------------------------------------------------------------

check_os() {
    log_check "Kiểm tra hệ điều hành..."

    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        log_info "OK - $PRETTY_NAME"

        if [[ "$ID" == "ubuntu" ]]; then
            return 0
        else
            log_warn "Khuyến nghị dùng Ubuntu"
            return 0
        fi
    fi

    log_error "Không xác định được OS"
    return 1
}

#------------------------------------------------------------------------------
# Kiểm tra quyền root
#------------------------------------------------------------------------------

check_root() {
    log_check "Kiểm tra quyền root..."

    if [[ $EUID -ne 0 ]]; then
        log_error "Cần quyền root để cài đặt"
        return 1
    fi

    log_info "OK - Đang chạy với quyền root"
}

#------------------------------------------------------------------------------
# Kiểm tra disk space
#------------------------------------------------------------------------------

check_disk_space() {
    log_check "Kiểm tra disk space..."

    local required_mb=500
    local available_mb=$(df -m "$SPANEL_DIR" 2>/dev/null | tail -1 | awk '{print $4}')

    if [[ -z "$available_mb" ]]; then
        available_mb=$(df -m / | tail -1 | awk '{print $4}')
    fi

    if [[ $available_mb -lt $required_mb ]]; then
        log_error "Không đủ disk space: ${available_mb}MB (cần ${required_mb}MB)"
        return 1
    fi

    log_info "OK - Còn ${available_mb}MB disk space"
}

#------------------------------------------------------------------------------
# Kiểm tra ports
#------------------------------------------------------------------------------

check_ports() {
    log_check "Kiểm tra ports $NGINX_PORT/$NGINX_SSL_PORT..."

    local issues=()

    if ss -tlnp 2>/dev/null | grep -q ":$NGINX_PORT "; then
        log_warn "Port $NGINX_PORT đang được sử dụng (nginx đang chạy)"
    else
        log_info "OK - Port $NGINX_PORT trống"
    fi

    if ss -tlnp 2>/dev/null | grep -q ":$NGINX_SSL_PORT "; then
        log_warn "Port $NGINX_SSL_PORT đang được sử dụng"
    else
        log_info "OK - Port $NGINX_SSL_PORT trống"
    fi
}

#------------------------------------------------------------------------------
# Kiểm tra memory
#------------------------------------------------------------------------------

check_memory() {
    log_check "Kiểm tra memory..."

    local total_mb=$(free -m | grep Mem | awk '{print $2}')
    local available_mb=$(free -m | grep Mem | awk '{print $7}')

    log_info "Memory: ${total_mb}MB total, ${available_mb}MB available"

    if [[ $total_mb -lt 512 ]]; then
        log_warn "Memory thấp (< 512MB), có thể ảnh hưởng hiệu năng"
    fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo ""
    echo "========================================"
    echo -e "${BLUE}Check System${NC}"
    echo "========================================"

    check_root || return 1
    check_os || return 1
    check_disk_space || return 1
    check_memory
    check_ports  # Chỉ cảnh báo, không fail

    echo ""
    log_info "Hoàn tất kiểm tra system"
    echo ""
}

main "$@"