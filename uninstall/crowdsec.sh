#!/bin/bash
#==============================================================================
# Uninstall CrowdSec
# Gỡ cài đặt CrowdSec
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

SPANEL_DIR="/var/server"

main() {
    log_info "Gỡ CrowdSec..."

    # Dừng và disable service
    systemctl stop crowdsec 2>/dev/null || true
    systemctl disable crowdsec 2>/dev/null || true

    # Xóa packages
    apt-get purge -y crowdsec crowdsec-nginx-bouncer crowdsec-lapi-bouncer 2>/dev/null || true

    # Xóa repo
    if [[ -f /etc/apt/sources.list.d/crowdsec_crowdsec.list ]]; then
        rm -f /etc/apt/sources.list.d/crowdsec_crowdsec.list
        log_info "Đã xóa CrowdSec repo"
    fi

    # Xóa thư mục config
    if [[ -d "$SPANEL_DIR/crowdsec" ]]; then
        rm -rf "$SPANEL_DIR/crowdsec"
        log_info "Đã xóa $SPANEL_DIR/crowdsec"
    fi

    # Xóa data
    rm -rf /var/lib/crowdsec 2>/dev/null || true
    rm -rf /etc/crowdsec 2>/dev/null || true

    log_info "Hoàn tất gỡ CrowdSec"
}

main "$@"