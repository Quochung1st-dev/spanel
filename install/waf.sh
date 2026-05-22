#!/bin/bash
#==============================================================================
# WAF Installer
# Cài đặt Web Application Firewall rules dựa trên Lua
# Không cài ModSecurity - chỉ dùng Lua WAF thuần
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

main() {
    log_info "Bắt đầu cài đặt WAF..."

    log_info "WAF dựa trên Lua (không dùng ModSecurity)..."

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
    log_info "Hoàn tất cài đặt WAF"
}

main "$@"