#!/bin/bash
#==============================================================================
# Uninstall Domains
# Gỡ domain configs
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

SPANEL_DIR="/var/server"
WWW_DIR="/var/www"

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

    log_info "Hoàn tất gỡ domain configs"
    log_warn "Dữ liệu website tại $WWW_DIR vẫn còn - xóa thủ công nếu cần"
}

main "$@"