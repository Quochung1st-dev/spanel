#!/bin/bash
#==============================================================================
# Check Directory
# Kiểm tra thư mục theo cấu hình .env
#==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

SPANEL_DIR="${SPANEL_DIR:-/var/server}"
SPANEL_USER="${SPANEL_USER:-spanel}"
SPANEL_GROUP="${SPANEL_GROUP:-spanel}"

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
# Cấu trúc thư mục cần tạo
#------------------------------------------------------------------------------

SPANEL_DIRS=(
    "$SPANEL_DIR"
    "$SPANEL_DIR/nginx"
    "$SPANEL_DIR/nginx/conf"
    "$SPANEL_DIR/nginx/conf/conf.d"
    "$SPANEL_DIR/nginx/sites-available"
    "$SPANEL_DIR/nginx/sites-enabled"
    "$SPANEL_DIR/nginx/logs"
    "$SPANEL_DIR/lua"
    "$SPANEL_DIR/luajit"
    "$SPANEL_DIR/waf"
    "$SPANEL_DIR/waf/rules"
    "$SPANEL_DIR/waf/logs"
    "$SPANEL_DIR/cache"
    "$SPANEL_DIR/ssl"
    "$SPANEL_DIR/lib"
    "$SPANEL_DIR/run"
    "$SPANEL_DIR/logs"
    "$SPANEL_DIR/logs/nginx"
    "$SPANEL_DIR/logs/waf"
    "$SPANEL_DIR/logs/spanel"
    "$SPANEL_DIR/tmp"
    "$SPANEL_DIR/var"
)

WWW_DIRS=(
    "/var/www"
)

#------------------------------------------------------------------------------
# Kiểm tra thư mục SPanel
#------------------------------------------------------------------------------

check_spanel_dirs() {
    log_check "Kiểm tra cấu trúc thư mục SPanel..."

    local missing_dirs=()
    local wrong_owner=()

    for dir in "${SPANEL_DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
        elif [[ -d "$dir" ]]; then
            local owner=$(stat -c '%U' "$dir" 2>/dev/null)
            if [[ "$owner" != "$SPANEL_USER" ]]; then
                wrong_owner+=("$dir:$owner")
            fi
        fi
    done

    if [[ ${#missing_dirs[@]} -gt 0 ]]; then
        log_warn "Thiếu ${#missing_dirs[@]} thư mục"
        return 1
    fi

    if [[ ${#wrong_owner[@]} -gt 0 ]]; then
        log_warn "Sai chủ sở hữu: ${wrong_owner[*]}"
        return 1
    fi

    log_info "OK - Cấu trúc thư mục đầy đủ và đúng chủ sở hữu"
    return 0
}

#------------------------------------------------------------------------------
# Tạo thư mục
#------------------------------------------------------------------------------

create_dirs() {
    log_fix "Tạo cấu trúc thư mục..."

    for dir in "${SPANEL_DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "Tạo: $dir"
        fi
    done

    for dir in "${WWW_DIRS[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_info "Tạo: $dir"
        fi
    done
}

#------------------------------------------------------------------------------
# Sửa quyền sở hữu
#------------------------------------------------------------------------------

fix_ownership() {
    log_fix "Sửa quyền sở hữu: $SPANEL_USER:$SPANEL_GROUP..."

    chown -R "$SPANEL_USER:$SPANEL_GROUP" "$SPANEL_DIR"

    # WWW dir có thể thuộc root
    for dir in "${WWW_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            chown -R root:root "$dir"
        fi
    done

    log_info "Đã sửa quyền sở hữu"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo ""
    echo "========================================"
    echo -e "${BLUE}Check Directory${NC}"
    echo "========================================"

    log_check ".env: SPANEL_DIR=$SPANEL_DIR"
    log_check ".env: SPANEL_USER=$SPANEL_USER, SPANEL_GROUP=$SPANEL_GROUP"

    if ! check_spanel_dirs; then
        create_dirs
        fix_ownership
        check_spanel_dirs || true
    fi

    echo ""
    log_info "Hoàn tất kiểm tra thư mục"
    echo ""
}

main "$@"