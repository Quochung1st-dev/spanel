#!/bin/bash
#==============================================================================
# SSH Install Script
# Cai dat sshpass cho SSH sync
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

#------------------------------------------------------------------------------
# Check root
#------------------------------------------------------------------------------

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Script phải được chạy với quyền root"
        exit 1
    fi
}

#------------------------------------------------------------------------------
# Print header
#------------------------------------------------------------------------------

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║       SPanel - SSH Install              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
}

#------------------------------------------------------------------------------
# Install sshpass
#------------------------------------------------------------------------------

install_sshpass() {
    echo ""
    log_info "Cai dat sshpass..."

    if command -v sshpass &>/dev/null; then
        log_info "sshpass da duoc cai dat"
        sshpass --version 2>&1 | head -1
        return 0
    fi

    echo ""
    echo "Dang cap nhat package lists..."
    apt-get update -qq 2>/dev/null

    echo "Dang cai dat sshpass..."
    apt-get install -y sshpass 2>/dev/null

    if command -v sshpass &>/dev/null; then
        echo ""
        log_info "Da cai dat sshpass thanh cong!"
        sshpass --version 2>&1 | head -1
    else
        echo ""
        log_error "Cai dat sshpass that bai"
        return 1
    fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    check_root
    print_header

    echo ""
    echo "Script nay cai dat sshpass de ho tro SSH sync."
    echo ""

    install_sshpass

    echo ""
    echo "========================================"
    echo -e "${GREEN}  HOAN TAT${NC}"
    echo "========================================"
    echo ""
}

main "$@"