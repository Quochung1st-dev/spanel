#!/bin/bash
#==============================================================================
# Uninstall WAF
# Gỡ cài đặt WAF
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

SPANEL_DIR="/var/server"

main() {
    log_info "Gỡ WAF..."

    # Xóa WAF directory
    if [[ -d "$SPANEL_DIR/waf" ]]; then
        rm -rf "$SPANEL_DIR/waf"
        log_info "Đã xóa $SPANEL_DIR/waf"
    fi

    # Xóa log files
    if [[ -d /var/log/spanel/waf ]]; then
        rm -rf /var/log/spanel/waf
        log_info "Đã xóa WAF logs"
    fi

    log_info "Hoàn tất gỡ WAF"
}

main "$@"