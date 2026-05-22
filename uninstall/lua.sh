#!/bin/bash
#==============================================================================
# Uninstall LuaJIT
# Gỡ cài đặt LuaJIT
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

SPANEL_DIR="/var/server"

main() {
    log_info "Gỡ LuaJIT..."

    # Xóa LuaJIT trong SPanel directory
    if [[ -d "$SPANEL_DIR/luajit" ]]; then
        rm -rf "$SPANEL_DIR/luajit"
        log_info "Đã xóa $SPANEL_DIR/luajit"
    fi

    # Xóa Lua source nếu có
    if [[ -d "$SPANEL_DIR/lua" ]]; then
        rm -rf "$SPANEL_DIR/lua"
        log_info "Đã xóa $SPANEL_DIR/lua"
    fi

    log_info "Hoàn tất gỡ LuaJIT"
}

main "$@"