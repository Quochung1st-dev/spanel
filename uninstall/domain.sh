#!/bin/bash
#==============================================================================
# Uninstall Domains
# Gỡ domain configs
# Usage: bash domain.sh [true|false]
#   true = xóa luôn /var/www, false = giữ lại (mặc định)
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

SPANEL_DIR="/var/server"
WWW_DIR="/var/www"

CLEAR_DATA="${1:-false}"

main() {
    log_info "Gỡ domain configs..."

    # Xóa sites-available và sites-enabled
    if [[ -d "$SPANEL_DIR/nginx/sites-available" ]]; then
        rm -rf "$SPANEL_DIR/nginx/sites-available"
        log_info "Đã xóa sites-available"
    fi

    if [[ -d "$SPANEL_DIR/nginx/sites-enabled" ]]; then
        rm -rf "$SPANEL_DIR/nginx/sites-enabled"
        log_info "Đã xóa sites-enabled"
    fi

    # Xóa conf.d
    if [[ -d "$SPANEL_DIR/nginx/conf.d" ]]; then
        rm -rf "$SPANEL_DIR/nginx/conf.d"
        log_info "Đã xóa conf.d"
    fi

    # Xóa /var/www nếu có --clear
    if [[ "$CLEAR_DATA" == "true" ]] && [[ -d "$WWW_DIR" ]]; then
        log_warn "Xóa $WWW_DIR..."
        rm -rf "$WWW_DIR"
        log_info "Đã xóa $WWW_DIR"
    else
        log_info "Giữ lại $WWW_DIR (thêm --clear để xóa)"
    fi

    log_info "Hoàn tất gỡ domain configs"
}

main "$@"