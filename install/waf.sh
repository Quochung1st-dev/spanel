#!/bin/bash
#==============================================================================
# WAF Installer
# Cài đặt Web Application Firewall rules và module
#==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SPANEL_DIR="${SPANEL_DIR:-/var/server}"
NGINX_USER="${NGINX_USER:-www-data}"

# Xác định SCRIPT_DIR (thư mục source - git clone)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

#------------------------------------------------------------------------------
# Cài đặt WAF rules
#------------------------------------------------------------------------------

install_waf_rules() {
    log_info "Cài đặt WAF rules..."

    local waf_dir="$SPANEL_DIR/waf"
    mkdir -p $waf_dir/rules
    mkdir -p $waf_dir/logs

    # Copy WAF rules
    cp -r "$SCRIPT_DIR/data/waf/"* $waf_dir/

    # Phân quyền
    chown -R root:$NGINX_USER $waf_dir
    chmod 640 $waf_dir/*.lua 2>/dev/null || true
    chmod 640 $waf_dir/rules/* 2>/dev/null || true
    chmod 755 $waf_dir/logs

    log_info "Đã cài đặt WAF rules vào $waf_dir"
}

#------------------------------------------------------------------------------
# Cài đặt ModSecurity (nếu cần)
#------------------------------------------------------------------------------

install_modsecurity() {
    log_info "Kiểm tra ModSecurity..."

    if command -v modsecurity &> /dev/null; then
        log_info "ModSecurity đã được cài đặt"
    else
        log_warn "ModSecurity không được cài đặt (tùy chọn)"
        log_info "SPanel sử dụng WAF dựa trên Lua thuần"
    fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    log_info "Bắt đầu cài đặt WAF..."

    install_waf_rules
    install_modsecurity

    log_info "Hoàn tất cài đặt WAF"
}

main "$@"