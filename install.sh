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

# Load .env nếu có (chứa SPANEL_DIR và các config)
if [[ -f .env ]]; then
    source .env
fi

# Xác định SCRIPT_DIR (thư mục clone git về - source gốc)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# SPANEL_DIR từ .env hoặc mặc định
# Trong prod: /var/server (đã set trong .env)
# Trong dev: có thể = SCRIPT_DIR nếu chạy tại chỗ
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

    if [[ -f install/$script ]]; then
        chmod +x install/$script
        pushd "$SCRIPT_DIR" > /dev/null
        bash install/$script
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

    if [[ -f install/spanel.service ]]; then
        cp install/spanel.service /etc/systemd/system/
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

    if [[ -f install/logrotate.conf ]]; then
        cp install/logrotate.conf /etc/logrotate.d/spanel
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
    mkdir -p $SPANEL_DIR/bin

    if [[ -d $SCRIPT_DIR/bin ]]; then
        cp -r $SCRIPT_DIR/bin/* $SPANEL_DIR/bin/
        chmod +x $SPANEL_DIR/bin/v-*
        log_info "Đã copy bin scripts vào $SPANEL_DIR/bin"
    fi

    # Tạo symlink vào /usr/local/bin để có thể gọi trực tiếp
    if [[ ! -L /usr/local/bin/v-check-vps ]] && [[ -f $SPANEL_DIR/bin/v-check-vps ]]; then
        ln -sf $SPANEL_DIR/bin/v-check-vps /usr/local/bin/v-check-vps
        ln -sf $SPANEL_DIR/bin/v-manager-domain /usr/local/bin/v-manager-domain
        ln -sf $SPANEL_DIR/bin/v-add-domain /usr/local/bin/v-add-domain
        ln -sf $SPANEL_DIR/bin/v-change-domain /usr/local/bin/v-change-domain
        ln -sf $SPANEL_DIR/bin/v-delete-domain /usr/local/bin/v-delete-domain
        log_info "Đã tạo symlinks trong /usr/local/bin"
    fi
}

#------------------------------------------------------------------------------
# Hoàn tất cài đặt
#------------------------------------------------------------------------------

finish_installation() {
    log_info "Hoàn tất cài đặt..."

    # Phân quyền
    chown -R $SPANEL_USER:$SPANEL_GROUP $SPANEL_DIR 2>/dev/null || true

    # Tạo file .env nếu chưa có
    if [[ ! -f $SPANEL_DIR/.env ]]; then
        cp $SCRIPT_DIR/.env $SPANEL_DIR/.env
        chmod 600 $SPANEL_DIR/.env
        log_warn "Đã tạo $SPANEL_DIR/.env - vui lòng chỉnh sửa"
    fi

    echo ""
    echo "========================================"
    echo -e "${GREEN}SPanel đã được cài đặt thành công!${NC}"
    echo "========================================"
    echo ""
    echo "Thư mục cài đặt: $SPANEL_DIR"
    echo ""
    echo "Các bước tiếp theo:"
    echo "  1. Chỉnh sửa $SPANEL_DIR/.env"
    echo "  2. Khởi động Nginx: $OPENRESTY_DIR/nginx/sbin/nginx"
    echo "  3. Kiểm tra VPS: v-check-vps"
    echo "  4. Quản lý domain: v-manager-domain"
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
    # 2. Cấu hình nginx (nginx.conf, sites-available, conf.d)
    # 3. WAF rules
    # 4. SSL certificates
    # 5. User & Group (tạo cuối để tránh lỗi phân quyền)
    run_install_script "openresty.sh" "OpenResty (Nginx + LuaJIT)"
    run_install_script "nginx.sh" "Nginx Config"
    run_install_script "waf.sh" "WAF"
    run_install_script "ssl.sh" "SSL"
    run_install_script "user.sh" "User & Group"

    # Cài đặt systemd service và logrotate
    install_systemd_service
    install_logrotate
    install_bin_scripts

    finish_installation
}

main "$@"