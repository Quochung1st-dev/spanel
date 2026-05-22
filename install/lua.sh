#!/bin/bash
#==============================================================================
# Lua Scripts Installer
# Copy Lua scripts vào /var/server/lua
# Note: LuaJIT đã được cài sẵn trong OpenResty
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

# Xác định SCRIPT_DIR (thư mục source - git clone)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    log_info "Bắt đầu cài đặt Lua scripts..."

    local lua_dir="$SPANEL_DIR/lua"

    # Tạo thư mục
    mkdir -p $lua_dir

    # Copy Lua scripts từ data/lua
    if [[ -d "$SCRIPT_DIR/data/lua" ]]; then
        cp -r "$SCRIPT_DIR/data/lua/"* $lua_dir/
        log_info "Đã copy Lua scripts vào $lua_dir"
    else
        log_warn "Không tìm thấy $SCRIPT_DIR/data/lua"
    fi

    # Phân quyền
    chown -R root:root $lua_dir
    chmod 644 $lua_dir/*.lua 2>/dev/null || true

    log_info "Hoàn tất cài đặt Lua scripts"
}

main "$@"