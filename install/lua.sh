#!/bin/bash
#==============================================================================
# Lua Installer
# Cài đặt LuaJIT và các module Lua
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
LUAJIT_VERSION="${LUAJIT_VERSION:-2.1}"

#------------------------------------------------------------------------------
# Kiểm tra Lua đã cài đặt chưa
#------------------------------------------------------------------------------

check_lua_installed() {
    log_info "Kiểm tra Lua..."

    if command -v lua &> /dev/null || command -v luajit &> /dev/null; then
        log_info "Lua/LuaJIT đã được cài đặt"
        return 0
    else
        log_warn "Lua chưa được cài đặt"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Cài đặt LuaJIT từ source
#------------------------------------------------------------------------------

install_luajit_from_source() {
    log_info "Cài đặt LuaJIT $LUAJIT_VERSION từ source..."

    local build_dir="/tmp/luajit-build-$$"
    mkdir -p $build_dir
    cd $build_dir

    # Cài đặt các thư viện cần thiết
    apt-get update
    apt-get install -y \
        build-essential \
        libpcre3-dev

    # Tải LuaJIT
    wget -q https://github.com/LuaJIT/LuaJIT/archive/v${LUAJIT_VERSION}.tar.gz
    tar -xzf v${LUAJIT_VERSION}.tar.gz
    cd LuaJIT-${LUAJIT_VERSION}

    # Build
    make -j$(nproc)

    # Cài đặt
    make install PREFIX=$SPANEL_DIR/luajit

    # Cleanup
    cd /
    rm -rf $build_dir

    log_info "Đã cài đặt LuaJIT vào $SPANEL_DIR/luajit"
}

#------------------------------------------------------------------------------
# Cài đặt Lua scripts
#------------------------------------------------------------------------------

install_lua_scripts() {
    log_info "Cài đặt Lua scripts..."

    local lua_dir="$SPANEL_DIR/lua"
    mkdir -p $lua_dir

    # Copy tất cả script Lua
    cp -r data/lua/* $lua_dir/

    # Phân quyền
    chown -R root:root $lua_dir
    chmod 644 $lua_dir/*.lua

    log_info "Đã cài đặt Lua scripts vào $lua_dir"
}

#------------------------------------------------------------------------------
# Cài đặt các module Lua bổ sung
#------------------------------------------------------------------------------

install_lua_modules() {
    log_info "Cài đặt các module Lua..."

    local lua_modules=(
        "resty.http"
        "resty.limits"
        "lua-resty-auto-ssl"
        "lua-resty-iputils"
    )

    for module in "${lua_modules[@]}"; do
        log_info "Cài đặt $module..."
        # Cài đặt từ luarocks hoặc git
        if command -v luarocks &> /dev/null; then
            luarocks install $module 2>/dev/null || log_warn "Không thể cài $module"
        else
            log_warn "luarocks không có sẵn, bỏ qua $module"
        fi
    done

    log_info "Hoàn tất cài đặt Lua modules"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    log_info "Bắt đầu cài đặt Lua..."

    if ! check_lua_installed; then
        install_luajit_from_source
    fi

    install_lua_scripts
    install_lua_modules

    log_info "Hoàn tất cài đặt Lua"
}

main "$@"