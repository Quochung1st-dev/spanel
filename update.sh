#!/bin/bash
#==============================================================================
# SPanel Update Script
# Cập nhật SPanel từ source code
#==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env từ SCRIPT_DIR nếu có
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

SPANEL_DIR="${SPANEL_DIR:-/var/server}"
OPENRESTY_DIR="${OPENRESTY_DIR:-/usr/local/openresty}"

#------------------------------------------------------------------------------
# Kiểm tra quyền root
#------------------------------------------------------------------------------

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Script phải được chạy với quyền root"
        exit 1
    fi
}

#------------------------------------------------------------------------------
# Kiểm tra SPanel đã cài chưa
#------------------------------------------------------------------------------

check_spanel_installed() {
    if [[ ! -d "$SPANEL_DIR" ]]; then
        log_error "SPanel chưa được cài đặt tại $SPANEL_DIR"
        log_info "Chạy install.sh để cài đặt"
        exit 1
    fi
}

#------------------------------------------------------------------------------
# Update bin scripts
#------------------------------------------------------------------------------

update_bin_scripts() {
    log_info "Cập nhật bin scripts..."

    if [[ -d "$SCRIPT_DIR/bin" ]]; then
        mkdir -p "$SPANEL_DIR/bin"

        # Copy only regular files, skip symlinks
        for file in "$SCRIPT_DIR/bin"/*; do
            if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
                cp -f "$file" "$SPANEL_DIR/bin/"
                chmod +x "$file" 2>/dev/null || true
            fi
        done

        chmod +x "$SPANEL_DIR/bin/"v-* 2>/dev/null || true
        log_info "Đã cập nhật bin scripts"
    else
        log_warn "Không tìm thấy $SCRIPT_DIR/bin"
    fi

    # Create symlinks for all v-* scripts
    for bin in "$SPANEL_DIR/bin"/v-*; do
        if [[ -f "$bin" ]] && [[ ! -L "$bin" ]]; then
            local name=$(basename "$bin")
            ln -sf "$bin" "/usr/local/bin/$name"
        fi
    done
    log_info "Đã cập nhật symlinks"
}

#------------------------------------------------------------------------------
# Update data (nginx config, lua, waf)
#------------------------------------------------------------------------------

update_data() {
    log_info "Cập nhật data..."

    if [[ -d "$SCRIPT_DIR/data/nginx" ]]; then
        mkdir -p "$SPANEL_DIR/nginx/conf"

        # Copy nginx configs (skip symlinks)
        for file in "$SCRIPT_DIR/data/nginx"/*; do
            if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
                cp -f "$file" "$SPANEL_DIR/nginx/conf/"
            fi
        done

        log_info "Đã cập nhật nginx configs"

        # Create sites-enabled symlinks
        mkdir -p "$SPANEL_DIR/nginx/conf/sites-enabled"
        if [[ -f "$SPANEL_DIR/nginx/conf/sites-available/default.conf" ]]; then
            ln -sf "$SPANEL_DIR/nginx/conf/sites-available/default.conf" "$SPANEL_DIR/nginx/conf/sites-enabled/default.conf" 2>/dev/null || true
        fi
        if [[ -f "$SPANEL_DIR/nginx/conf/sites-available/panel.conf" ]]; then
            ln -sf "$SPANEL_DIR/nginx/conf/sites-available/panel.conf" "$SPANEL_DIR/nginx/conf/sites-enabled/panel.conf" 2>/dev/null || true
        fi
        log_info "Đã tạo sites-enabled symlinks"
    fi

    if [[ -d "$SCRIPT_DIR/data/lua" ]]; then
        mkdir -p "$SPANEL_DIR/lua"
        for file in "$SCRIPT_DIR/data/lua"/*; do
            if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
                cp -f "$file" "$SPANEL_DIR/lua/"
            fi
        done
        log_info "Đã cập nhật lua scripts"
    fi

    if [[ -d "$SCRIPT_DIR/data/waf" ]]; then
        mkdir -p "$SPANEL_DIR/waf"
        # Copy all files including subdirectories
        find "$SCRIPT_DIR/data/waf" -type f | while read file; do
            local rel_path="${file#$SCRIPT_DIR/data/waf/}"
            local target_dir="$SPANEL_DIR/waf/$(dirname "$rel_path")"
            mkdir -p "$target_dir"
            cp -f "$file" "$target_dir/"
        done
        log_info "Đã cập nhật waf rules và IP lists"
    fi

    if [[ -d "$SCRIPT_DIR/data/vhost" ]]; then
        mkdir -p "$SPANEL_DIR/nginx/conf/vhost"
        cp -rf "$SCRIPT_DIR/data/vhost/"* "$SPANEL_DIR/nginx/conf/vhost/"
        log_info "Đã cập nhật vhost templates"
    fi
}

#------------------------------------------------------------------------------
# Reload services
#------------------------------------------------------------------------------

reload_services() {
    log_info "Reload services..."

    if [[ -f "$OPENRESTY_DIR/nginx/sbin/nginx" ]]; then
        if pgrep -x nginx > /dev/null 2>&1; then
            if "$OPENRESTY_DIR/nginx/sbin/nginx" -t 2>/dev/null; then
                # Kill and restart nginx instead of reload
                pkill nginx 2>/dev/null || true
                sleep 1
                "$OPENRESTY_DIR/nginx/sbin/nginx" -c "$SPANEL_DIR/nginx/conf/nginx.conf"
                log_info "Đã restart nginx"
            else
                log_warn "Nginx config lỗi, bỏ qua reload"
            fi
        else
            # Start nginx if not running
            "$OPENRESTY_DIR/nginx/sbin/nginx" -c "$SPANEL_DIR/nginx/conf/nginx.conf"
            log_info "Đã start nginx"
        fi
    else
        log_warn "Nginx chưa cài đặt"
    fi

    if systemctl is-active --quiet crowdsec 2>/dev/null; then
        systemctl restart crowdsec
        log_info "Đã restart crowdsec"
    fi

    if [[ -f /etc/systemd/system/spanel.service ]]; then
        systemctl restart spanel 2>/dev/null || true
        log_info "Đã restart spanel service"
    fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    echo ""
    echo "========================================"
    echo -e "${BLUE}  SPanel Update${NC}"
    echo "========================================"
    echo ""
    echo "Source: $SCRIPT_DIR"
    echo "Target: $SPANEL_DIR"
    echo ""

    check_root
    check_spanel_installed

    update_bin_scripts
    echo ""
    update_data
    echo ""
    reload_services

    echo ""
    echo "========================================"
    echo -e "${GREEN}  DA CAP NHAT SPANEL${NC}"
    echo "========================================"
    echo ""
}

main "$@"