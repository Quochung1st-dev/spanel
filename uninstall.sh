#!/bin/bash
#==============================================================================
# SPanel Uninstaller
# Gỡ cài đặt SPanel và tất cả components
#
# Usage: bash uninstall.sh [--clear]
#   --clear    Xóa luôn /var/www (dữ liệu website)
#==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

SPANEL_DIR="${SPANEL_DIR:-/var/server}"
SPANEL_USER="${SPANEL_USER:-spanel}"
SPANEL_GROUP="${SPANEL_GROUP:-spanel}"

# Parse arguments
CLEAR_DATA=false
for arg in "$@"; do
    case $arg in
        --clear)
            CLEAR_DATA=true
            ;;
        --help|-h)
            echo "Usage: bash uninstall.sh [--clear]"
            echo "  --clear    Xóa luôn /var/www (dữ liệu website)"
            exit 0
            ;;
    esac
done

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo ""; echo -e "${BLUE}========================================${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}========================================${NC}"; }

#------------------------------------------------------------------------------
# Confirm uninstall
#------------------------------------------------------------------------------

confirm_uninstall() {
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  CẢNH BÁO: GỠ CÀI ĐẶT SPANEL${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Thư mục SPanel: $SPANEL_DIR"
    echo "User: $SPANEL_USER"
    echo ""
    echo "Script này sẽ gỡ:"
    echo "  - OpenResty/Nginx"
    echo "  - Redis"
    echo "  - Lua scripts"
    echo "  - WAF"
    echo "  - CrowdSec"
    echo "  - SSL certificates"
    echo "  - User và group spanel"
    echo "  - Thư mục $SPANEL_DIR"
    echo ""

    if [[ "$CLEAR_DATA" == "true" ]]; then
        echo -e "${RED}  -- CÓ: Xóa luôn /var/www${NC}"
    else
        echo -e "${YELLOW}  -- KHÔNG xóa /var/www (thêm --clear để xóa)${NC}"
    fi
    echo ""
    printf "Chắc chắn muốn gỡ cài đặt? (yes/no): "
    read -r REPLY
    case "$REPLY" in
        yes|Yes|YES)
            echo ""
            ;;
        *)
            echo "Đã hủy."
            exit 0
            ;;
    esac
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo ""
    echo "========================================"
    echo -e "${RED}SPanel Uninstaller${NC}"
    echo "========================================"

    confirm_uninstall

    # Chạy lần lượt các script gỡ (theo thứ tự ngược lại với install)
    # 1. SSL trước (cần remove configs)
    # 2. Redis
    # 3. CrowdSec
    # 4. WAF
    # 5. User & Group (cần xóa user trước khi xóa dir)
    # 6. Lua scripts
    # 7. Directory (xóa /var/www nếu có --clear)
    # 8. OpenResty cuối (cần stop nginx trước)
    log_section "Gỡ SSL"
    bash "$SCRIPT_DIR/uninstall/ssl.sh"

    log_section "Gỡ Redis"
    bash "$SCRIPT_DIR/uninstall/redis.sh"

    log_section "Gỡ CrowdSec"
    bash "$SCRIPT_DIR/uninstall/crowdsec.sh"

    log_section "Gỡ WAF"
    bash "$SCRIPT_DIR/uninstall/waf.sh"

    log_section "Gỡ User & Group"
    bash "$SCRIPT_DIR/uninstall/user.sh"

    log_section "Gỡ Lua scripts"
    bash "$SCRIPT_DIR/uninstall/lua.sh"

    log_section "Gỡ thư mục SPanel"
    bash "$SCRIPT_DIR/uninstall/dir.sh" "$CLEAR_DATA"

    log_section "Gỡ OpenResty"
    bash "$SCRIPT_DIR/uninstall/openresty.sh"

    echo ""
    echo "========================================"
    echo -e "${GREEN}ĐÃ GỠ CÀI ĐẶT SPANEL${NC}"
    echo "========================================"
    echo ""

    if [[ "$CLEAR_DATA" == "true" ]]; then
        echo "Đã xóa /var/www"
    else
        echo "Thư mục /var/www vẫn còn với dữ liệu website."
        echo "Xóa thủ công nếu cần: rm -rf /var/www"
    fi
    echo ""
}

main "$@"