#!/bin/bash
#==============================================================================
# Uninstall Lua
# Gỡ Lua scripts trong SPanel
# Note: LuaJIT đã được cài đặt cùng OpenResty, không cần gỡ riêng
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

SPANEL_DIR="/var/server"

main() {
    log_info "Gỡ Lua scripts..."

    # Xóa Lua scripts trong SPanel directory
    if [[ -d "$SPANEL_DIR/lua" ]]; then
        rm -rf "$SPANEL_DIR/lua"
        log_info "Đã xóa $SPANEL_DIR/lua"
    fi

    # LuaJIT đã được gỡ cùng OpenResty - không cần xử lý thêm

    log_info "Hoàn tất gỡ Lua"
}

main "$@"