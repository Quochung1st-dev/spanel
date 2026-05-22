#!/bin/bash
#==============================================================================
# Check Nginx
# Kiểm tra nginx theo version trong .env
# Dùng OpenResty (nginx + LuaJIT đã build sẵn)
#==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

SPANEL_DIR="${SPANEL_DIR:-/var/server}"
NGINX_VERSION="${NGINX_VERSION:-1.29.2}"
NGINX_USER="${NGINX_USER:-www-data}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_check() { echo -e "${BLUE}[CHECK]${NC} $1"; }
log_fix() { echo -e "${YELLOW}[FIX]${NC} $1"; }

#------------------------------------------------------------------------------
# Lấy version nginx hiện tại
#------------------------------------------------------------------------------

get_installed_nginx_version() {
    # Ưu tiên: /usr/local/openresty > SPanel nginx > System nginx
    if [[ -f /usr/local/openresty/nginx/sbin/nginx ]]; then
        /usr/local/openresty/nginx/sbin/nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+'
    elif [[ -f /opt/openresty/nginx/sbin/nginx ]]; then
        /opt/openresty/nginx/sbin/nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+'
    elif [[ -f "$SPANEL_DIR/nginx/sbin/nginx" ]]; then
        "$SPANEL_DIR/nginx/sbin/nginx" -v 2>&1 | grep -oP '\d+\.\d+\.\d+'
    elif command -v nginx &>/dev/null; then
        nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+'
    else
        echo "not_found"
    fi
}

#------------------------------------------------------------------------------
# Lấy đường dẫn nginx binary
#------------------------------------------------------------------------------

get_nginx_bin() {
    if [[ -f /usr/local/openresty/nginx/sbin/nginx ]]; then
        echo "/usr/local/openresty/nginx/sbin/nginx"
    elif [[ -f /opt/openresty/nginx/sbin/nginx ]]; then
        echo "/opt/openresty/nginx/sbin/nginx"
    elif [[ -f "$SPANEL_DIR/nginx/sbin/nginx" ]]; then
        echo "$SPANEL_DIR/nginx/sbin/nginx"
    elif command -v nginx &>/dev/null; then
        which nginx
    else
        echo ""
    fi
}

#------------------------------------------------------------------------------
# Kiểm tra nginx có Lua module không
#------------------------------------------------------------------------------

check_nginx_lua_module() {
    log_check "Kiểm tra Lua module..."

    local nginx_bin=$(get_nginx_bin)

    if [[ -z "$nginx_bin" ]]; then
        log_error "Không tìm thấy nginx binary"
        return 1
    fi

    if $nginx_bin -V 2>&1 | grep -qi "lua"; then
        log_info "OK - Có Lua module"
        return 0
    else
        log_error "Nginx không có Lua module"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Gỡ nginx không phù hợp
#------------------------------------------------------------------------------

uninstall_nginx() {
    log_fix "Gỡ nginx hiện tại..."

    # Dừng nginx
    if pgrep -x nginx &>/dev/null; then
        pkill -9 nginx 2>/dev/null || true
        log_info "Đã dừng nginx"
    fi

    # Xóa OpenResty
    if [[ -d /usr/local/openresty ]]; then
        rm -rf /usr/local/openresty
        log_info "Đã xóa OpenResty"
    fi
    if [[ -d /opt/openresty ]]; then
        rm -rf /opt/openresty
        log_info "Đã xóa OpenResty (opt)"
    fi

    # Xóa nginx trong SPANEL_DIR
    if [[ -d "$SPANEL_DIR/nginx" ]]; then
        rm -rf "$SPANEL_DIR/nginx"
        log_info "Đã xóa $SPANEL_DIR/nginx"
    fi

    # Xóa nginx hệ thống
    if command -v nginx &>/dev/null; then
        apt-get purge -y nginx nginx-common nginx-full 2>/dev/null || true
        log_info "Đã xóa nginx hệ thống"
    fi
}

#------------------------------------------------------------------------------
# Cài OpenResty (nginx + Lua đã build sẵn)
#------------------------------------------------------------------------------

install_openresty() {
    log_fix "Cài đặt OpenResty..."

    # Thêm OpenResty repo nếu chưa có
    if ! grep -q "openresty" /etc/apt/sources.list.d/*.list 2>/dev/null; then
        log_info "Thêm OpenResty repo..."
        apt-get update
        apt-get install -y apt-transport-https gnupg
        wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add -
        echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/openresty.list
    fi

    # Cài OpenResty version tương thích với OpenSSL 3.0.x
    # 1.27.1.x yêu cầu openssl3 >= 3.0.15 (tương thích với Ubuntu 24.04)
    apt-get update
    apt-get install -y openresty-openssl3 openresty-pcre2 openresty-zlib
    apt-get install -y "openresty=1.27.1.2-1~noble1" || apt-get install -y openresty

    log_info "Đã cài OpenResty"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo ""
    echo "========================================"
    echo -e "${BLUE}Check Nginx (OpenResty)${NC}"
    echo "========================================"

    log_check ".env: NGINX_VERSION=$NGINX_VERSION"
    log_info "Sử dụng OpenResty (nginx + LuaJIT built-in)"

    local installed_version=$(get_installed_nginx_version)
    log_check "Installed: $installed_version"

    # Kiểm tra Lua module
    if ! check_nginx_lua_module; then
        log_warn "Nginx không có Lua - Cần cài OpenResty"
        uninstall_nginx
        install_openresty

        installed_version=$(get_installed_nginx_version)
        log_check "OpenResty version: $installed_version"

        if check_nginx_lua_module; then
            log_info "OK - OpenResty với Lua đã được cài đặt"
        fi
        echo ""
        return 0
    fi

    # So sánh version (chỉ cảnh báo, không gỡ vì OpenResty đã có Lua)
    local ver_major=$(echo "$installed_version" | cut -d. -f1)
    local ver_minor=$(echo "$installed_version" | cut -d. -f2)

    if [[ "$ver_major" != "1" ]] || [[ "$ver_minor" != "29" ]]; then
        log_warn "OpenResty version: $installed_version (khuyến nghị: 1.29.x)"
        log_info "Có thể cần cập nhật OpenResty để tương thích"
    else
        log_info "OK - OpenResty version tương thích"
    fi

    echo ""
}

main "$@"