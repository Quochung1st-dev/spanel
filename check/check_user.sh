#!/bin/bash
#==============================================================================
# Check User & Group
# Kiểm tra user/group theo .env, tạo hoặc sửa nếu cần
#==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

SPANEL_DIR="${SPANEL_DIR:-/var/server}"
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
# Kiểm tra group
#------------------------------------------------------------------------------

check_group() {
    log_check "Kiểm tra group $NGINX_GROUP..."

    if getent group "$NGINX_GROUP" &>/dev/null; then
        log_info "OK - Group $NGINX_GROUP đã tồn tại"
        return 0
    else
        log_warn "Group $NGINX_GROUP chưa tồn tại"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Kiểm tra user
#------------------------------------------------------------------------------

check_user() {
    log_check "Kiểm tra user $NGINX_USER..."

    if id "$NGINX_USER" &>/dev/null; then
        log_info "OK - User $NGINX_USER đã tồn tại (uid=$(id -u $NGINX_USER))"
        return 0
    else
        log_warn "User $NGINX_USER chưa tồn tại"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Kiểm tra nginx user
#------------------------------------------------------------------------------

check_nginx_user() {
    log_check "Kiểm tra nginx user $NGINX_USER..."

    if getent passwd "$NGINX_USER" &>/dev/null; then
        log_info "OK - User nginx $NGINX_USER đã tồn tại"
        return 0
    else
        log_warn "User nginx $NGINX_USER chưa tồn tại"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Kiểm tra user có trong group đúng không
#------------------------------------------------------------------------------

check_user_groups() {
    log_check "Kiểm tra user $NGINX_USER thuộc group $NGINX_GROUP..."

    if id "$NGINX_USER" | grep -q "$NGINX_GROUP"; then
        log_info "OK - User $NGINX_USER thuộc group $NGINX_GROUP"
        return 0
    else
        log_warn "User $NGINX_USER không thuộc group $NGINX_GROUP"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Tạo group
#------------------------------------------------------------------------------

create_group() {
    log_fix "Tạo group $NGINX_GROUP..."
    groupadd -r "$NGINX_GROUP" 2>/dev/null || groupadd "$NGINX_GROUP"
    log_info "Đã tạo group $NGINX_GROUP"
}

#------------------------------------------------------------------------------
# Tạo user
#------------------------------------------------------------------------------

create_user() {
    log_fix "Tạo user $NGINX_USER..."
    useradd -r -g "$NGINX_GROUP" -s /bin/false -d "$SPANEL_DIR" -c "SPanel user" "$NGINX_USER"
    log_info "Đã tạo user $NGINX_USER"
}

#------------------------------------------------------------------------------
# Tạo nginx user
#------------------------------------------------------------------------------

create_nginx_user() {
    log_fix "Tạo nginx user $NGINX_USER..."
    if ! getent group "$NGINX_USER" &>/dev/null; then
        groupadd -r "$NGINX_USER"
    fi
    if ! getent passwd "$NGINX_USER" &>/dev/null; then
        useradd -r -g "$NGINX_USER" -s /bin/false -d /nonexistent -c "nginx user" "$NGINX_USER"
    fi
    log_info "Đã tạo user $NGINX_USER"
}

#------------------------------------------------------------------------------
# Thêm user vào group
#------------------------------------------------------------------------------

add_user_to_group() {
    log_fix "Thêm $NGINX_USER vào group $NGINX_GROUP..."
    usermod -aG "$NGINX_GROUP" "$NGINX_USER"
    log_info "Đã thêm $NGINX_USER vào group $NGINX_GROUP"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo ""
    echo "========================================"
    echo -e "${BLUE}Check User & Group${NC}"
    echo "========================================"

    log_check ".env: User=$NGINX_USER, Group=$NGINX_GROUP"
    log_check ".env: NGINX_USER=$NGINX_USER"

    # Kiểm tra và tạo group
    if ! check_group; then
        create_group
    fi

    # Kiểm tra và tạo user
    if ! check_user; then
        create_user
    fi

    # Kiểm tra và tạo nginx user
    if ! check_nginx_user; then
        create_nginx_user
    fi

    # Kiểm tra user thuộc group
    if ! check_user_groups; then
        add_user_to_group
    fi

    echo ""
    log_info "Hoàn tất kiểm tra user/group"
    echo ""
}

main "$@"