#!/bin/bash
#==============================================================================
# Check Lua
# Kiểm tra LuaJIT theo version trong .env, gỡ nếu không khớp
#==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

SPANEL_DIR="${SPANEL_DIR:-/var/server}"
LUAJIT_VERSION="${LUAJIT_VERSION:-2.1}"

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
# Lấy version LuaJIT hiện tại
#------------------------------------------------------------------------------

get_installed_luajit_version() {
    if [[ -f "$SPANEL_DIR/luajit/bin/luajit" ]]; then
        local version=$("$SPANEL_DIR/luajit/bin/luajit" -v 2>&1 | grep -oP 'LuaJIT \d+\.\d+' | awk '{print $2}')
        echo "$version"
    elif command -v luajit &>/dev/null; then
        luajit -v 2>&1 | grep -oP 'LuaJIT \d+\.\d+' | awk '{print $2}'
    elif command -v lua &>/dev/null; then
        lua -v 2>&1 | head -1
    else
        echo "not_found"
    fi
}

#------------------------------------------------------------------------------
# Kiểm tra LuaJIT đã cài chưa
#------------------------------------------------------------------------------

check_luajit() {
    log_check "Kiểm tra LuaJIT..."

    if [[ -f "$SPANEL_DIR/luajit/bin/luajit" ]]; then
        log_info "OK - LuaJIT tại $SPANEL_DIR/luajit"
        return 0
    elif command -v luajit &>/dev/null; then
        log_info "OK - LuaJIT system"
        return 0
    else
        log_warn "LuaJIT chưa được cài"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Gỡ LuaJIT
#------------------------------------------------------------------------------

uninstall_luajit() {
    log_fix "Gỡ LuaJIT hiện tại..."

    # Xóa trong SPANEL_DIR
    if [[ -d "$SPANEL_DIR/luajit" ]]; then
        rm -rf "$SPANEL_DIR/luajit"
        log_info "Đã xóa $SPANEL_DIR/luajit"
    fi

    # Xóa system luajit nếu có
    if command -v luajit &>/dev/null; then
        rm -f /usr/local/bin/luajit
        rm -f /usr/local/bin/luajit-*
        log_info "Đã xóa LuaJIT system"
    fi
}

#------------------------------------------------------------------------------
# Cài LuaJIT từ source
#------------------------------------------------------------------------------

install_luajit() {
    log_fix "Cài đặt LuaJIT $LUAJIT_VERSION..."

    local build_dir="/tmp/luajit-build-$$"
    mkdir -p $build_dir
    cd $build_dir

    # Cài đặt thư viện cần thiết
    apt-get update
    apt-get install -y build-essential libpcre3-dev

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

    log_info "Đã cài LuaJIT $LUAJIT_VERSION vào $SPANEL_DIR/luajit"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo ""
    echo "========================================"
    echo -e "${BLUE}Check LuaJIT${NC}"
    echo "========================================"

    log_check ".env: LUAJIT_VERSION=$LUAJIT_VERSION"

    local installed_version=$(get_installed_luajit_version)
    log_check "Installed: $installed_version"

    if check_luajit; then
        # So sánh version
        if [[ "$installed_version" != "$LUAJIT_VERSION" ]]; then
            log_warn "Version không khớp: $installed_version != $LUAJIT_VERSION"
            uninstall_luajit
            install_luajit
        else
            log_info "OK - Version khớp"
        fi
    else
        install_luajit
    fi

    echo ""
}

main "$@"