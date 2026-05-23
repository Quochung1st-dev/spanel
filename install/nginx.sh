#!/bin/bash
#==============================================================================
# Nginx Config Installer
# Cài đặt và cấu hình Nginx config (OpenResty đã cài ở openresty.sh)
#==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SPANEL_DIR="${SPANEL_DIR:-/var/server}"
NGINX_USER="${NGINX_USER:-www-data}"
OPENRESTY_DIR="${OPENRESTY_DIR:-/usr/local/openresty}"

# Xác định SCRIPT_DIR (thư mục source - git clone)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

#------------------------------------------------------------------------------
# Kiểm tra OpenResty/Nginx đã cài đặt chưa
#------------------------------------------------------------------------------

check_nginx_installed() {
    log_info "Kiểm tra OpenResty/Nginx..."

    if [[ -f "$OPENRESTY_DIR/nginx/sbin/nginx" ]]; then
        local installed_version=$("$OPENRESTY_DIR/nginx/sbin/nginx" -v 2>&1 | grep -oP '\d+\.\d+\.\d+')
        log_info "OpenResty/Nginx đã được cài đặt (version: $installed_version)"
        return 0
    else
        log_error "OpenResty/Nginx chưa được cài đặt - chạy openresty.sh trước"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Cài đặt cấu hình Nginx
#------------------------------------------------------------------------------

install_nginx_config() {
    log_info "Cài đặt cấu hình Nginx..."

    local nginx_conf_dir="$SPANEL_DIR/nginx/conf"

    # Tạo thư mục
    mkdir -p $nginx_conf_dir
    mkdir -p $nginx_conf_dir/conf.d
    mkdir -p $nginx_conf_dir/sites-available
    mkdir -p $nginx_conf_dir/sites-enabled

    # Copy nginx.conf chính
    cp "$SCRIPT_DIR/data/nginx/nginx.conf" $nginx_conf_dir/nginx.conf

    # Copy mime.types
    cp "$SCRIPT_DIR/data/nginx/mime.types" $nginx_conf_dir/mime.types

    # Tạo thư mục run
    mkdir -p "$SPANEL_DIR/run"

    # Copy systemd service file
    if [[ -f "$SCRIPT_DIR/install/spanel-nginx.service" ]]; then
        cp "$SCRIPT_DIR/install/spanel-nginx.service" /etc/systemd/system/spanel-nginx.service
        systemctl daemon-reload
    fi

    # Copy các block config trong conf.d
    if [[ -d "$SCRIPT_DIR/data/nginx/conf.d" ]]; then
        cp -r "$SCRIPT_DIR/data/nginx/conf.d/"* $nginx_conf_dir/conf.d/
    fi

    # Copy các site configs từ data
    if [[ -d "$SCRIPT_DIR/data/nginx/sites-available" ]]; then
        cp -r "$SCRIPT_DIR/data/nginx/sites-available/"* $nginx_conf_dir/sites-available/
    fi

    # Copy vhost configs
    if [[ -d "$SCRIPT_DIR/data/vhost/sites-available" ]]; then
        mkdir -p $nginx_conf_dir/vhost
        cp -r "$SCRIPT_DIR/data/vhost/"* $nginx_conf_dir/vhost/
    fi

    # Tạo symlink các site
    for site in $nginx_conf_dir/sites-available/*.conf; do
        if [[ -f "$site" ]]; then
            local name=$(basename "$site")
            ln -sf "$site" $nginx_conf_dir/sites-enabled/"$name" 2>/dev/null || true
        fi
    done

    # Phân quyền
    chown -R root:$NGINX_USER $nginx_conf_dir
    chmod 640 $nginx_conf_dir/*.conf
    chmod 640 $nginx_conf_dir/conf.d/*.conf

    log_info "Đã cài đặt cấu hình Nginx"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    log_info "Bắt đầu cài đặt Nginx Config..."

    # OpenResty phải được cài trước
    if ! check_nginx_installed; then
        log_error "Vui lòng chạy openresty.sh trước"
        exit 1
    fi

    install_nginx_config

    # Test cấu hình
    if "$OPENRESTY_DIR/nginx/sbin/nginx" -t 2>/dev/null; then
        log_info "Cấu hình Nginx hợp lệ"
    else
        log_warn "Cấu hình Nginx có lỗi"
    fi

    log_info "Hoàn tất cài đặt Nginx Config"
}

main "$@"