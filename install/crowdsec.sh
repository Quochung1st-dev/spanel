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
    if command -v cscli &>/dev/null; then
        log_info "CrowdSec package: $(cscli version 2>/dev/null | head -1)"
        return 0
    else
        return 1
    fi
}

#------------------------------------------------------------------------------
# Thêm CrowdSec repo
#------------------------------------------------------------------------------

add_crowdsec_repo() {
    log_info "Thêm CrowdSec repo..."
    curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | bash
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

    apt-get update
    apt-get install -y crowdsec

    # Tạo config nếu chưa có (trong trường hợp package script lỗi)
    if [[ ! -f /etc/crowdsec/config.yaml ]]; then
        log_info "Tạo CrowdSec config..."
        mkdir -p /etc/crowdsec

        # Dump default config
        /usr/bin/crowdsec -c /etc/crowdsec/config.yaml -t 2>/dev/null || \
            /usr/bin/cscli config generate --force 2>/dev/null || true
    fi

    # Backup config nếu có
    if [[ -f /etc/crowdsec/config.yaml ]]; then
        cp /etc/crowdsec/config.yaml /etc/crowdsec/config.yaml.bak 2>/dev/null || true
    fi

    log_info "Đã cài CrowdSec"
}

#------------------------------------------------------------------------------
# Cấu hình CrowdSec
#------------------------------------------------------------------------------

configure_crowdsec() {
    log_info "Cấu hình CrowdSec..."

    # Tạo thư mục config
    mkdir -p "$SPANEL_DIR/crowdsec"

    # Install scenarios
    cscli collections install crowdsecurity/nginx 2>/dev/null || true
    cscli collections install crowdsecurity/http-crawl 2>/dev/null || true

    # Ensure config is valid
    /usr/bin/crowdsec -c /etc/crowdsec/config.yaml -t 2>/dev/null || {
        log_warn "CrowdSec config lỗi - sửa..."
        mkdir -p /etc/crowdsec
        cat > /etc/crowdsec/config.yaml << 'EOFCONFIG'
common:
  daemonize: false
  log_media: stdout
  log_level: info
  online_client: false

local_api_credentials:
  url: http://127.0.0.1:8080
  login: admin
  password: changeme

api:
  server:
    listen_uri: 127.0.0.1:8080
    profiles_path: /etc/crowdsec/profiles.yaml
    console_path: /etc/crowdsec/console.yaml
    online_client: false

prometheus:
  enabled: true
  level: full
  listen_uri: 127.0.0.1:6060

log_level: info
log_media: stdout
EOFCONFIG
        touch /etc/crowdsec/profiles.yaml
        touch /etc/crowdsec/console.yaml
    }

    # Start service
    systemctl enable crowdsec 2>/dev/null || true
    systemctl restart crowdsec 2>/dev/null || true

    log_info "Đã cấu hình CrowdSec"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    log_info "Bat dau cai dat CrowdSec..."

    if ! check_crowdsec_installed; then
        install_crowdsec
    fi

    configure_crowdsec

    echo ""
    echo "========================================"
    echo -e "${GREEN}CrowdSec da duoc cai dat!${NC}"
    echo "========================================"
    echo "Trang thai: systemctl status crowdsec"
}

main "$@"