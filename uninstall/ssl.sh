#!/bin/bash
#==============================================================================
# Uninstall SSL
# Gỡ SSL certificates
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

SPANEL_DIR="/var/server"
SSL_DIR="$SPANEL_DIR/ssl"

main() {
    log_info "Gỡ SSL certificates..."

    if [[ -d "$SSL_DIR" ]]; then
        # Liệt kê certificates trước khi xóa
        local cert_count=$(find "$SSL_DIR" -name "*.pem" -o -name "*.crt" -o -name "*.key" 2>/dev/null | wc -l)
        if [[ $cert_count -gt 0 ]]; then
            log_warn "Sẽ xóa $cert_count certificate files"
            rm -rf "$SSL_DIR"
            log_info "Đã xóa $SSL_DIR"
        else
            log_info "Không có certificates để xóa"
        fi
    else
        log_info "Không có SSL directory"
    fi

    log_info "Hoàn tất gỡ SSL"
}

main "$@"