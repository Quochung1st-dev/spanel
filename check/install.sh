#!/bin/bash
#==============================================================================
# Check All - Main Entry Point
# Chạy tất cả các check
#==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_section() { echo ""; echo -e "${BLUE}========================================${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}========================================${NC}"; }

#------------------------------------------------------------------------------
# Load .env
#------------------------------------------------------------------------------

if [[ -f "$SCRIPT_DIR/../.env" ]]; then
    source "$SCRIPT_DIR/../.env"
fi

SPANEL_DIR="${SPANEL_DIR:-/var/server}"
NGINX_PORT="${NGINX_PORT:-80}"
NGINX_SSL_PORT="${NGINX_SSL_PORT:-443}"

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo ""
    echo "========================================"
    echo -e "${BLUE}SPanel Full System Check${NC}"
    echo "========================================"
    echo ""
    echo "SPANEL_DIR: $SPANEL_DIR"
    echo "NGINX_PORT: $NGINX_PORT"
    echo "SSL_PORT: $NGINX_SSL_PORT"
    echo ""

    local start_time=$(date +%s)

    # Chạy tất cả các check
    log_section "System Check"
    bash "$SCRIPT_DIR/check_system.sh"

    log_section "Dependencies Check"
    bash "$SCRIPT_DIR/check_deps.sh"

    log_section "User & Group Check"
    bash "$SCRIPT_DIR/check_user.sh"

    log_section "Directory Check"
    bash "$SCRIPT_DIR/check_dir.sh"

    log_section "Nginx Check"
    bash "$SCRIPT_DIR/check_nginx.sh"

    log_section "Lua Check"
    bash "$SCRIPT_DIR/check_lua.sh"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    echo "========================================"
    echo -e "${GREEN}HOÀN TẤT KIỂM TRA${NC}"
    echo "========================================"
    echo ""
    echo "Thời gian: ${duration}s"
    echo ""
    echo "Có thể tiến hành cài đặt với:"
    echo "  bash $SCRIPT_DIR/../install.sh"
    echo ""
}

main "$@"