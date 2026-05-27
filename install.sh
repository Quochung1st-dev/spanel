#!/bin/bash
#==============================================================================
# SPanel Installer
# Cài đặt SPanel lên server mới
#==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Xác định SCRIPT_DIR (thư mục clone git về - source gốc)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env từ SCRIPT_DIR (chứa SPANEL_DIR và các config)
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

# SPANEL_DIR và OPENRESTY_DIR từ .env hoặc mặc định
SPANEL_DIR="${SPANEL_DIR:-/var/server}"
OPENRESTY_DIR="${OPENRESTY_DIR:-/usr/local/openresty}"

#------------------------------------------------------------------------------
# Kiểm tra root
#------------------------------------------------------------------------------

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Script phải được chạy với quyền root"
        exit 1
    fi
}

#------------------------------------------------------------------------------
# Kiểm tra hệ thống
#------------------------------------------------------------------------------

check_dependencies() {
    log_info "Kiểm tra các phụ thuộc..."

    local missing=()

    if ! command -v wget &> /dev/null; then
        missing+=("wget")
    fi

    if ! command -v tar &> /dev/null; then
        missing+=("tar")
    fi

    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Thiếu các phụ thuộc: ${missing[*]}"
        log_info "Cài đặt bằng: apt-get install ${missing[*]}"
        exit 1
    fi

    log_info "Tất cả phụ thuộc cơ bản đã có"
}

#------------------------------------------------------------------------------
# Chạy các script cài đặt
#------------------------------------------------------------------------------

run_install_script() {
    local script=$1
    local name=$2

    log_info "Cài đặt $name..."

    if [[ -f "$SCRIPT_DIR/install/$script" ]]; then
        chmod +x "$SCRIPT_DIR/install/$script"
        pushd "$SCRIPT_DIR" > /dev/null
        bash "install/$script"
        popd > /dev/null
        log_info "Đã cài đặt $name"
    else
        log_warn "Không tìm thấy install/$script, bỏ qua"
    fi
}

#------------------------------------------------------------------------------
# Cài đặt systemd service
#------------------------------------------------------------------------------

install_systemd_service() {
    log_info "Cài đặt systemd service..."

    if [[ -f "$SCRIPT_DIR/install/spanel.service" ]]; then
        cp "$SCRIPT_DIR/install/spanel.service" /etc/systemd/system/
        systemctl daemon-reload
        log_info "Đã cài đặt systemd service"
    else
        log_warn "Không tìm thấy install/spanel.service"
    fi
}

#------------------------------------------------------------------------------
# Cài đặt logrotate
#------------------------------------------------------------------------------

install_logrotate() {
    log_info "Cài đặt logrotate..."

    if [[ -f "$SCRIPT_DIR/install/logrotate.conf" ]]; then
        cp "$SCRIPT_DIR/install/logrotate.conf" /etc/logrotate.d/spanel
        log_info "Đã cài đặt logrotate"
    else
        log_warn "Không tìm thấy install/logrotate.conf"
    fi
}

#------------------------------------------------------------------------------
# Cài đặt bin scripts vào hệ thống
#------------------------------------------------------------------------------

install_bin_scripts() {
    log_info "Cài đặt bin scripts..."

    # Copy các scripts vào $SPANEL_DIR/bin
    mkdir -p "$SPANEL_DIR/bin"

    if [[ -d "$SCRIPT_DIR/bin" ]]; then
        cp -r "$SCRIPT_DIR/bin/"* "$SPANEL_DIR/bin/"
        chmod +x "$SPANEL_DIR/bin"/v-*
        log_info "Đã copy bin scripts vào $SPANEL_DIR/bin"
    fi

    # Tạo symlink vào /usr/local/bin để có thể gọi trực tiếp
    if [[ ! -L /usr/local/bin/v-check-vps ]] && [[ -f "$SPANEL_DIR/bin/v-check-vps" ]]; then
        ln -sf "$SPANEL_DIR/bin/v-check-vps" /usr/local/bin/v-check-vps
        ln -sf "$SPANEL_DIR/bin/v-manager-domain" /usr/local/bin/v-manager-domain
        ln -sf "$SPANEL_DIR/bin/v-add-domain" /usr/local/bin/v-add-domain
        ln -sf "$SPANEL_DIR/bin/v-change-domain" /usr/local/bin/v-change-domain
        ln -sf "$SPANEL_DIR/bin/v-delete-domain" /usr/local/bin/v-delete-domain
        log_info "Đã tạo symlinks trong /usr/local/bin"
    fi
}

#------------------------------------------------------------------------------
# Hoàn tất cài đặt
#------------------------------------------------------------------------------

finish_installation() {
    log_info "Hoàn tất cài đặt..."

    # Tạo các thư mục cần thiết nếu chưa có
    log_info "Tạo thư mục runtime..."
    mkdir -p "$SPANEL_DIR/run"
    mkdir -p "$SPANEL_DIR/logs/nginx"
    mkdir -p "$SPANEL_DIR/logs/waf"
    mkdir -p "$SPANEL_DIR/cache"
    mkdir -p "$SPANEL_DIR/ssl"
    mkdir -p "$SPANEL_DIR/lib"
    mkdir -p "$SPANEL_DIR/bin"
    mkdir -p "$SPANEL_DIR/backup"
    mkdir -p /var/www

    # Phân quyền cho SPanel user
    log_info "Phân quyền thư mục..."
    chown -R $NGINX_USER:$NGINX_GROUP "$SPANEL_DIR" 2>/dev/null || true
    chown -R $NGINX_USER:$NGINX_GROUP /var/www 2>/dev/null || true

    # Tạo file empty cho logs nếu chưa có
    touch "$SPANEL_DIR/logs/nginx/access.log"
    touch "$SPANEL_DIR/logs/nginx/error.log"
    touch "$SPANEL_DIR/logs/waf/audit.log"
    touch "$SPANEL_DIR/logs/waf/error.log"
    chown $NGINX_USER:$NGINX_GROUP "$SPANEL_DIR/logs"/*.log 2>/dev/null || true

    # Test cấu hình Nginx
    log_info "Kiểm tra cấu hình Nginx..."
    if [[ -x "$OPENRESTY_DIR/nginx/sbin/nginx" ]]; then
        if "$OPENRESTY_DIR/nginx/sbin/nginx" -t 2>/dev/null; then
            log_info "Nginx config OK"
        else
            log_warn "Nginx config có lỗi, kiểm tra lại"
        fi
    fi

    # Bật systemd service
    if [[ -f /etc/systemd/system/spanel.service ]]; then
        log_info "Bật SPanel service..."
        systemctl enable spanel 2>/dev/null || true
    fi

    # Hiển thị thông tin cài đặt
    echo ""
    echo "========================================"
    echo -e "${GREEN}SPanel đã được cài đặt thành công!${NC}"
    echo "========================================"
    echo ""
    echo -e "${YELLOW}Thông tin cài đặt:${NC}"
    echo "  Thư mục runtime : $SPANEL_DIR"
    echo "  User             : $NGINX_USER"
    echo "  Nginx            : $OPENRESTY_DIR/nginx/sbin/nginx"
    echo ""
    echo -e "${YELLOW}Cấu trúc thư mục:${NC}"
    echo "  $SPANEL_DIR/nginx/     - Cấu hình Nginx"
    echo "  $SPANEL_DIR/lua/       - Scripts Lua"
    echo "  $SPANEL_DIR/waf/       - WAF rules"
    echo "  $SPANEL_DIR/cache/     - Cache"
    echo "  $SPANEL_DIR/ssl/       - SSL certificates"
    echo "  $SPANEL_DIR/logs/      - Logs"
    echo "  $SPANEL_DIR/bin/       - Scripts quản lý"
    echo "  /var/www/              - Website files"
    echo ""
    echo -e "${YELLOW}Các bước tiếp theo:${NC}"
    echo "  1. Khởi động Nginx:"
    echo "     $OPENRESTY_DIR/nginx/sbin/nginx"
    echo ""
    echo "  2. Kiểm tra hệ thống:"
    echo "     v-check-vps"
    echo ""
    echo "  3. Thêm domain mới:"
    echo "     v-add-domain example.com"
    echo ""
    echo "  4. Quản lý domain:"
    echo "     v-manager-domain"
    echo ""
    echo -e "${YELLOW}Commands có sẵn:${NC}"
    echo "  v-check-vps, v-manager-domain, v-add-domain,"
    echo "  v-change-domain, v-delete-domain, v-list-domain,"
    echo "  v-add-ssl, v-delete-ssl, v-backup-domain, ..."
    echo ""
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    log_info "Bắt đầu cài đặt SPanel..."
    log_info "Thư mục cài đặt: $SPANEL_DIR"

    check_root
    check_dependencies

    # Cài đặt theo thứ tự
    # 1. OpenResty (nginx + LuaJIT) trước vì bao gồm cả hai
    # 2. Redis (session/cache backend)
    # 3. Cấu hình nginx (nginx.conf, sites-available, conf.d)
    # 4. Lua scripts (copy vào /var/server/lua)
    # 5. WAF rules
    # 6. CrowdSec (protection layer trên WAF)
    # 7. SSL certificates
    run_install_script "openresty.sh" "OpenResty (Nginx + LuaJIT)"
    run_install_script "redis.sh" "Redis"
    run_install_script "nginx.sh" "Nginx Config"
    run_install_script "lua.sh" "Lua Scripts"
    run_install_script "waf.sh" "WAF"
    run_install_script "crowdsec.sh" "CrowdSec"
    run_install_script "ssl.sh" "SSL"

    # Cài đặt systemd service và logrotate
    install_systemd_service
    install_logrotate
    install_bin_scripts

    finish_installation
}

main "$@"