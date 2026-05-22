#!/bin/bash
#==============================================================================
# Uninstall User & Group
# Gỡ user và group spanel
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

SPANEL_USER="spanel"
SPANEL_GROUP="spanel"

main() {
    log_info "Gỡ user và group..."

    # Xóa user spanel
    if id "$SPANEL_USER" &>/dev/null; then
        userdel -r "$SPANEL_USER" 2>/dev/null || userdel "$SPANEL_USER"
        log_info "Đã xóa user $SPANEL_USER"
    else
        log_info "User $SPANEL_USER không tồn tại"
    fi

    # Xóa group spanel
    if getent group "$SPANEL_GROUP" &>/dev/null; then
        groupdel "$SPANEL_GROUP" 2>/dev/null || true
        log_info "Đã xóa group $SPANEL_GROUP"
    else
        log_info "Group $SPANEL_GROUP không tồn tại"
    fi

    log_info "Hoàn tất gỡ user/group"
}

main "$@"