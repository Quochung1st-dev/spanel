#!/bin/bash
#==============================================================================
# Check Dependencies
# Kiểm tra packages cần thiết theo .env
#==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

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
# Packages cần thiết cho build
#------------------------------------------------------------------------------

BUILD_DEPS=(
    "build-essential"
    "libpcre3-dev"
    "zlib1g-dev"
    "libssl-dev"
)

# Packages cần thiết cho nginx
NGINX_DEPS=(
    "libpcre3"
    "zlib1g"
)

# Tools cần thiết
TOOLS=(
    "wget"
    "tar"
    "git"
)

#------------------------------------------------------------------------------
# Kiểm tra tools
#------------------------------------------------------------------------------

check_tools() {
    log_check "Kiểm tra tools..."

    local missing=()
    for tool in "${TOOLS[@]}"; do
        if command -v "$tool" &>/dev/null; then
            local version=$("$tool" --version 2>&1 | head -1)
            log_info "OK - $tool: $version"
        else
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Thiếu tools: ${missing[*]}"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Kiểm tra build dependencies
#------------------------------------------------------------------------------

check_build_deps() {
    log_check "Kiểm tra build dependencies..."

    local missing=()
    local installed=()

    for dep in "${BUILD_DEPS[@]}"; do
        if dpkg -l | grep -q "^ii.*$dep"; then
            installed+=("$dep")
        else
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Thiếu build deps: ${missing[*]}"
        return 1
    fi

    log_info "OK - Tất cả build deps đã cài: ${installed[*]}"
}

#------------------------------------------------------------------------------
# Kiểm tra nginx dependencies
#------------------------------------------------------------------------------

check_nginx_deps() {
    log_check "Kiểm tra nginx dependencies..."

    local missing=()

    for dep in "${NGINX_DEPS[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$dep"; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Thiếu nginx deps: ${missing[*]}"
        return 1
    fi

    log_info "OK - Tất cả nginx deps đã cài"
}

#------------------------------------------------------------------------------
# Cài đặt dependencies
#------------------------------------------------------------------------------

install_deps() {
    log_fix "Cài đặt dependencies..."

    apt-get update
    apt-get install -y "${BUILD_DEPS[@]}" "${NGINX_DEPS[@]}" "${TOOLS[@]}"

    log_info "Đã cài tất cả dependencies"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo ""
    echo "========================================"
    echo -e "${BLUE}Check Dependencies${NC}"
    echo "========================================"

    local needs_install=0

    if ! check_tools; then
        needs_install=1
    fi

    if ! check_build_deps; then
        needs_install=1
    fi

    if ! check_nginx_deps; then
        needs_install=1
    fi

    if [[ $needs_install -eq 1 ]]; then
        install_deps
    fi

    echo ""
    log_info "Hoàn tất kiểm tra dependencies"
    echo ""
}

main "$@"