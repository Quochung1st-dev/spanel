#!/bin/bash
#==============================================================================
# Uninstall OpenResty
# Gỡ cài đặt OpenResty
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

OPENRESTY_DIR="/usr/local/openresty"

main() {
    log_info "Gỡ OpenResty..."

    # Dừng nginx
    if pgrep -x nginx &>/dev/null; then
        pkill -9 nginx 2>/dev/null || true
        log_info "Đã dừng nginx"
    fi

    # Xóa OpenResty package
    if command -v apt-get &>/dev/null; then
        apt-get purge -y openresty openresty-openssl3 openresty-pcre2 openresty-zlib 2>/dev/null || true
        log_info "Đã gỡ OpenResty packages"
    fi

    # Xóa thư mục cài đặt
    if [[ -d "$OPENRESTY_DIR" ]]; then
        rm -rf "$OPENRESTY_DIR"
        log_info "Đã xóa $OPENRESTY_DIR"
    fi

    # Xóa repo
    if [[ -f /etc/apt/sources.list.d/openresty.list ]]; then
        rm -f /etc/apt/sources.list.d/openresty.list
        log_info "Đã xóa OpenResty repo"
    fi

    # Xóa pgp key
    if [[ -f /etc/apt/trusted.gpg.d/openresty.gpg ]]; then
        rm -f /etc/apt/trusted.gpg.d/openresty.gpg
    fi

    log_info "Hoàn tất gỡ OpenResty"
}

main "$@"