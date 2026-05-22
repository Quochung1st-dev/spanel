#!/bin/bash
#==============================================================================
# SPanel Update Script
# Cập nhật SPanel từ source code
#==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPANEL_DIR="${SPANEL_DIR:-/var/server}"
OPENRESTY_DIR="${OPENRESTY_DIR:-/usr/local/openresty}"

#------------------------------------------------------------------------------
# Kiểm tra quyền root
#------------------------------------------------------------------------------

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Script phải được chạy với quyền root"
        exit 1
    fi
}

#------------------------------------------------------------------------------
# Kiểm tra SPanel đã cài chưa
#------------------------------------------------------------------------------

check_spanel_installed() {
    if [[ ! -d "$SPANEL_DIR" ]]; then
        log_error "SPanel chưa được cài đặt tại $SPANEL_DIR"
        log_info "Chạy install.sh để cài đặt"
        exit 1
    fi
}

#------------------------------------------------------------------------------
# Update bin scripts
#------------------------------------------------------------------------------

update_bin_scripts() {
    log_info "Cập nhật bin scripts..."

    # Copy bin scripts
    if [[ -d "$SCRIPT_DIR/bin" ]]; then
        mkdir -p "$SPANEL_DIR/bin"
        cp -rf "$SCRIPT_DIR/bin/"* "$SPANEL_DIR/bin/"
        chmod +x "$SPANEL_DIR/bin/"v-* 2>/dev/null || true
        log_info "Đã cập nhật bin scripts"
    else
        log_warn "Không tìm thấy $SCRIPT_DIR/bin"
    fi

    # Update symlinks
    local bin_links=(
        "v-check-vps"
        "v-manager-domain"
        "v-add-domain"
        "v-change-domain"
        "v-delete-domain"
    )

    for bin in "${bin_links[@]}"; do
        if [[ -f "$SPANEL_DIR/bin/$bin" ]]; then
            ln -sf "$SPANEL_DIR/bin/$bin" "/usr/local/bin/$bin"
        fi
    done
    log_info "Đã cập nhật symlinks"
}

#------------------------------------------------------------------------------
# Update data (nginx config, lua, waf)
#------------------------------------------------------------------------------

update_data() {
    log_info "Cập nhật data..."

    # Nginx configs
    if [[ -d "$SCRIPT_DIR/data/nginx" ]]; then
        mkdir -p "$SPANEL_DIR/nginx/conf"
        cp -rf "$SCRIPT_DIR/data/nginx/"* "$SPANEL_DIR/nginx/conf/"
        log_info "Đã cập nhật nginx configs"
    fi

    # Lua scripts
    if [[ -d "$SCRIPT_DIR/data/lua" ]]; then
        mkdir -p "$SPANEL_DIR/lua"
        cp -rf "$SCRIPT_DIR/data/lua/"* "$SPANEL_DIR/lua/"
        log_info "Đã cập nhật lua scripts"
    fi

    # WAF rules
    if [[ -d "$SCRIPT_DIR/data/waf" ]]; then
        mkdir -p "$SPANEL_DIR/waf"
        cp -rf "$SCRIPT_DIR/data/waf/"* "$SPANEL_DIR/waf/"
        log_info "Đã cập nhật waf rules"
    fi

    # Copy .env nếu cần
    if [[ -f "$SCRIPT_DIR/.env" ]] && [[ ! -f "$SPANEL_DIR/.env" ]]; then
        cp "$SCRIPT_DIR/.env" "$SPANEL_DIR/.env"
        chmod 600 "$SPANEL_DIR/.env"
        log_info "Đã copy .env"
    fi
}

#------------------------------------------------------------------------------
# Reload services
#------------------------------------------------------------------------------

reload_services() {
    log_info "Reload services..."

    # Reload nginx
    if [[ -f "$OPENRESTY_DIR/nginx/sbin/nginx" ]]; then
        if pgrep -x nginx > /dev/null 2>&1; then
            "$OPENRESTY_DIR/nginx/sbin/nginx" -s reload 2>/dev/null || \
                ("$OPENRESTY_DIR/nginx/sbin/nginx" -t && "$OPENRESTY_DIR/nginx/sbin/nginx" -s reload")
            log_info "Đã reload nginx"
        else
            log_warn "Nginx không chạy, bỏ qua reload"
        fi
    else
        log_warn "Nginx chưa cài đặt"
    fi

    # Restart CrowdSec
    if systemctl is-active --quiet crowdsec 2>/dev/null; then
        systemctl restart crowdsec
        log_info "Đã restart crowdsec"
    fi

    # Restart SPanel service
    if [[ -f /etc/systemd/system/spanel.service ]]; then
        systemctl restart spanel 2>/dev/null || true
        log_info "Đã restart spanel service"
    fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  SPanel Update${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    log_info "Source: $SCRIPT_DIR"
    log_info "Target: $SPANEL_DIR"
    echo ""

    check_root
    check_spanel_installed

    update_bin_scripts
    echo ""
    update_data
    echo ""
    reload_services

    echo ""
    echo "========================================"
    echo -e "${GREEN}ĐÃ CẬP NHẬT SPANEL${NC}"
    echo "========================================"
    echo ""
}

main "$@"
