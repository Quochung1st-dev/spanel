#!/bin/bash
#==============================================================================
# Uninstall Directory
# Gỡ thư mục SPanel
# Usage: bash dir.sh [true|false]
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
    log_info "Gỡ thư mục SPanel..."

    if [[ -d "$SPANEL_DIR" ]]; then
        # Kiểm tra thư mục có data không
        local dir_count=$(find "$SPANEL_DIR" -mindepth 1 -type f 2>/dev/null | wc -l)
        if [[ $dir_count -gt 0 ]]; then
            log_warn "Thư mục có $dir_count files - xóa..."
            rm -rf "$SPANEL_DIR"
            log_info "Đã xóa $SPANEL_DIR"
        else
            log_info "Thư mục trống - xóa..."
            rm -rf "$SPANEL_DIR"
            log_info "Đã xóa $SPANEL_DIR"
        fi
    else
        log_info "Thư mục $SPANEL_DIR không tồn tại"
    fi

    # Xóa /var/www nếu có --clear
    if [[ "$CLEAR_DATA" == "true" ]] && [[ -d "$WWW_DIR" ]]; then
        log_warn "Xóa $WWW_DIR..."
        rm -rf "$WWW_DIR"
        log_info "Đã xóa $WWW_DIR"
    fi

    # Xóa logrotate config
    if [[ -f /etc/logrotate.d/spanel ]]; then
        rm -f /etc/logrotate.d/spanel
        log_info "Đã xóa logrotate config"
    fi

    # Xóa systemd service
    if [[ -f /etc/systemd/system/spanel.service ]]; then
        systemctl stop spanel 2>/dev/null || true
        systemctl disable spanel 2>/dev/null || true
        rm -f /etc/systemd/system/spanel.service
        systemctl daemon-reload
        log_info "Đã xóa spanel.service"
    fi

    # Xóa bin symlinks
    rm -f /usr/local/bin/v-check-vps
    rm -f /usr/local/bin/v-manager-domain
    rm -f /usr/local/bin/v-add-domain
    rm -f /usr/local/bin/v-change-domain
    rm -f /usr/local/bin/v-delete-domain
    log_info "Đã xóa bin symlinks"

    log_info "Hoàn tất gỡ thư mục SPanel"
}

main "$@"