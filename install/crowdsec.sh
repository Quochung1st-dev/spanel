#!/bin/bash
#==============================================================================
# CrowdSec Installer
# Cài đặt CrowdSec cho Nginx protection
#==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

SPANEL_DIR="${SPANEL_DIR:-/var/server}"
OPENRESTY_DIR="${OPENRESTY_DIR:-/usr/local/openresty}"

#------------------------------------------------------------------------------
# Kiểm tra CrowdSec đã cài chưa
#------------------------------------------------------------------------------

check_crowdsec_installed() {
    log_info "Kiểm tra CrowdSec..."

    if command -v cscli &>/dev/null; then
        local version=$(cscli version 2>/dev/null | head -1)
        log_info "CrowdSec đã được cài: $version"
        return 0
    else
        log_warn "CrowdSec chưa được cài đặt"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Thêm CrowdSec repo
#------------------------------------------------------------------------------

add_crowdsec_repo() {
    log_info "Thêm CrowdSec repo..."

    if command -v curl &>/dev/null; then
        curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | bash
    else
        log_error "curl không có sẵn"
        return 1
    fi

    log_info "Đã thêm CrowdSec repo"
}

#------------------------------------------------------------------------------
# Cài đặt CrowdSec
#------------------------------------------------------------------------------

install_crowdsec() {
    log_info "Cài đặt CrowdSec..."

    # Thêm repo nếu chưa có
    if ! grep -q "crowdsec.io" /etc/apt/sources.list.d/*.list 2>/dev/null; then
        add_crowdsec_repo
    fi

    # Cài CrowdSec
    apt-get update
    apt-get install -y crowdsec crowdsec-nginx-bouncer

    # Cài Nginx bouncer cho OpenResty
    apt-get install -y crowdsec-lapi-bouncer || log_warn "Không cài được crowdsec-lapi-bouncer"

    log_info "Đã cài CrowdSec"
}

#------------------------------------------------------------------------------
# Cấu hình CrowdSec cho OpenResty
#------------------------------------------------------------------------------

configure_crowdsec() {
    log_info "Cấu hình CrowdSec cho OpenResty..."

    # Tạo thư mục config
    mkdir -p "$SPANEL_DIR/crowdsec"

    # Copy config nếu có
    if [[ -d "$SCRIPT_DIR/data/crowdsec" ]]; then
        cp -r "$SCRIPT_DIR/data/crowdsec/"* "$SPANEL_DIR/crowdsec/"
        log_info "Đã copy CrowdSec config"
    fi

    # Register Nginx scenario
    cscli collections install crowdsecurity/nginx || true
    cscli scenarios install crowdsecurity/http-crawl && true || true

    # Update GeoIP database
    cscli collections install crowdsecurity/geoip-database || true

    # Restart CrowdSec
    systemctl restart crowdsec 2>/dev/null || true

    log_info "Đã cấu hình CrowdSec"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    log_info "Bắt đầu cài đặt CrowdSec..."

    if ! check_crowdsec_installed; then
        install_crowdsec
    fi

    configure_crowdsec

    echo ""
    log_info "========================================"
    log_info "CrowdSec đã được cài đặt!"
    log_info "========================================"
    log_info "Xem trạng thái: systemctl status crowdsec"
    log_info "Xem ban list: cscli ban list"
    log_info "Dashboard: cscli dashboard setup"
}

main "$@"