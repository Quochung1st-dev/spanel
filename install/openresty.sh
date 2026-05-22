#!/bin/bash
#==============================================================================
# OpenResty Installer
# Cài đặt OpenResty (nginx + LuaJIT built-in)
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
OPENRESTY_VERSION="${OPENRESTY_VERSION:-1.27.1}"
OPENRESTY_DIR="${OPENRESTY_DIR:-/usr/local/openresty}"
NGINX_USER="${NGINX_USER:-www-data}"

#------------------------------------------------------------------------------
# Kiểm tra OpenResty đã cài chưa
#------------------------------------------------------------------------------

check_openresty_installed() {
    log_info "Kiểm tra OpenResty..."

    if [[ -f "$OPENRESTY_DIR/nginx/sbin/nginx" ]]; then
        local installed_version=$("$OPENRESTY_DIR/nginx/sbin/nginx" -v 2>&1 | grep -oP '\d+\.\d+\.\d+')
        log_info "OpenResty đã cài: $installed_version"
        return 0
    else
        log_warn "OpenResty chưa được cài đặt"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Kiểm tra OpenResty có Lua module không
#------------------------------------------------------------------------------

check_lua_module() {
    log_info "Kiểm tra Lua module..."

    if "$OPENRESTY_DIR/nginx/sbin/nginx" -V 2>&1 | grep -qi "lua"; then
        log_info "OK - Có Lua module"
        return 0
    else
        log_error "OpenResty không có Lua module"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Thêm OpenResty repo
#------------------------------------------------------------------------------

add_openresty_repo() {
    log_info "Thêm OpenResty repo..."

    # Thêm pgp key
    wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add - 2>/dev/null || \
    wget -qO - https://openresty.org/package/pubkey.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/openresty.gpg

    # Thêm repo
    local codename=$(lsb_release -sc 2>/dev/null || echo "noble")
    echo "deb http://openresty.org/package/ubuntu $codename main" > /etc/apt/sources.list.d/openresty.list

    apt-get update
    log_info "Đã thêm OpenResty repo"
}

#------------------------------------------------------------------------------
# Cài đặt OpenResty
#------------------------------------------------------------------------------

install_openresty() {
    log_info "Cài đặt OpenResty $OPENRESTY_VERSION..."

    # Thêm repo nếu chưa có
    if ! grep -q "openresty.org" /etc/apt/sources.list.d/*.list 2>/dev/null; then
        add_openresty_repo
    fi

    # Cài dependencies trước
    apt-get install -y \
        apt-transport-https \
        gnupg \
        ca-certificates

    # Cài OpenResty và các dependencies
    apt-get install -y \
        openresty-openssl3 \
        openresty-pcre2 \
        openresty-zlib

    # Cài OpenResty version cụ thể nếu có thể
    if apt-cache show "openresty=${OPENRESTY_VERSION}-1~" 2>/dev/null | grep -q "Version"; then
        apt-get install -y "openresty=${OPENRESTY_VERSION}-1~noble1" || \
            apt-get install -y openresty
    else
        apt-get install -y openresty
    fi

    log_info "Đã cài OpenResty"
}

#------------------------------------------------------------------------------
# Kiểm tra và fix OpenSSL compatibility
#------------------------------------------------------------------------------

check_openssl_compatibility() {
    log_info "Kiểm tra OpenSSL compatibility..."

    # Thử chạy nginx
    if ! "$OPENRESTY_DIR/nginx/sbin/nginx" -v 2>&1 | grep -q "nginx"; then
        log_warn "OpenResty không chạy được - kiểm tra OpenSSL..."

        # Kiểm tra OpenSSL version
        local openssl_ver=$(openssl version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
        log_info "System OpenSSL: $openssl_ver"

        # Nếu OpenSSL quá mới, thử cập nhật ldconfig
        if [[ -f /usr/local/openresty/openssl3/lib/libssl.so.3 ]]; then
            echo "/usr/local/openresty/openssl3/lib" > /etc/ld.so.conf.d/openresty.conf
            ldconfig
            log_info "Đã cập nhật library path"
        fi

        # Thử lại
        if ! "$OPENRESTY_DIR/nginx/sbin/nginx" -v 2>&1 | grep -q "nginx"; then
            log_error "OpenResty vẫn không chạy được. Có thể cần OpenSSL cũ hơn."
            return 1
        fi
    fi

    log_info "OK - OpenResty chạy được"
}

#------------------------------------------------------------------------------
# Gỡ OpenResty cũ
#------------------------------------------------------------------------------

uninstall_openresty() {
    log_info "Gỡ OpenResty cũ..."

    # Dừng nginx
    if pgrep -x nginx &>/dev/null; then
        pkill -9 nginx 2>/dev/null || true
        log_info "Đã dừng nginx"
    fi

    # Xóa OpenResty
    if [[ -d "$OPENRESTY_DIR" ]]; then
        rm -rf "$OPENRESTY_DIR"
        log_info "Đã xóa $OPENRESTY_DIR"
    fi

    # Xóa /opt/openresty nếu có
    if [[ -d /opt/openresty ]]; then
        rm -rf /opt/openresty
        log_info "Đã xóa /opt/openresty"
    fi

    # Xóa nginx hệ thống
    if command -v nginx &>/dev/null; then
        apt-get purge -y nginx nginx-common nginx-full 2>/dev/null || true
        log_info "Đã xóa nginx hệ thống"
    fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    log_info "Bắt đầu cài đặt OpenResty..."
    log_info ".env: OPENRESTY_VERSION=$OPENRESTY_VERSION"
    log_info "OpenResty dir: $OPENRESTY_DIR"

    # Kiểm tra đã cài chưa
    if check_openresty_installed; then
        # Kiểm tra Lua module
        if check_lua_module; then
            # Kiểm tra version
            local installed_version=$("$OPENRESTY_DIR/nginx/sbin/nginx" -v 2>&1 | grep -oP '\d+\.\d+\.\d+')
            if [[ "$installed_version" == "$OPENRESTY_VERSION" ]]; then
                log_info "OK - OpenResty $OPENRESTY_VERSION đã được cài"
            else
                log_warn "Version không khớp: $installed_version != $OPENRESTY_VERSION"
                uninstall_openresty
                install_openresty
            fi
        else
            log_warn "OpenResty không có Lua - cài lại"
            uninstall_openresty
            install_openresty
        fi
    else
        install_openresty
    fi

    # Kiểm tra OpenSSL compatibility
    check_openssl_compatibility

    # Kiểm tra cuối
    if check_openresty_installed && check_lua_module; then
        log_info ""
        log_info "========================================"
        log_info "OpenResty đã được cài đặt thành công!"
        log_info "========================================"
        log_info "Binary: $OPENRESTY_DIR/nginx/sbin/nginx"
        "$OPENRESTY_DIR/nginx/sbin/nginx" -v
    else
        log_error "Cài đặt OpenResty thất bại"
        exit 1
    fi
}

main "$@"