#!/bin/bash
#==============================================================================
# SPanel Updater
# Cập nhật SPanel lên phiên bản mới
#==============================================================================

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Các biến
SPANEL_DIR="/opt/spanel"
BACKUP_DIR="/opt/spanel-backup-$(date +%Y%m%d-%H%M%S)"
GIT_REMOTE="${GIT_REMOTE:-origin}"
GIT_BRANCH="${GIT_BRANCH:-main}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Script phải được chạy với quyền root"
        exit 1
    fi
}

#-------------------------------------------------------------------------------
# Backup trước khi update
#-------------------------------------------------------------------------------

backup_before_update() {
    log_info "Tạo backup trước khi cập nhật..."

    mkdir -p $BACKUP_DIR

    # Backup các file quan trọng
    [[ -f $SPANEL_DIR/.env ]] && cp $SPANEL_DIR/.env $BACKUP_DIR/
    [[ -f $SPANEL_DIR/var/server/nginx/nginx.conf ]] && cp -r $SPANEL_DIR/var/server/nginx $BACKUP_DIR/
    [[ -d $SPANEL_DIR/var/www ]] && cp -r $SPANEL_DIR/var/www $BACKUP_DIR/
    [[ -d $SPANEL_DIR/logs ]] && cp -r $SPANEL_DIR/logs $BACKUP_DIR/
    [[ -d $SPANEL_DIR/var/server/waf ]] && cp -r $SPANEL_DIR/var/server/waf $BACKUP_DIR/

    log_info "Backup đã được lưu tại: $BACKUP_DIR"
}

#-------------------------------------------------------------------------------
# Kiểm tra phiên bản hiện tại
#-------------------------------------------------------------------------------

check_current_version() {
    if [[ -f $SPANEL_DIR/.env ]]; then
        source $SPANEL_DIR/.env
        log_info "Phiên bản hiện tại: ${SPANEL_VERSION:-unknown}"
    fi
}

#-------------------------------------------------------------------------------
# Pull code mới từ Git
#-------------------------------------------------------------------------------

pull_latest_code() {
    log_info "Đang tải phiên bản mới..."

    if [[ -d .git ]]; then
        git fetch $GIT_REMOTE
        git checkout $GIT_BRANCH
        git pull $GIT_REMOTE $GIT_BRANCH
        log_info "Đã cập nhật code từ Git"
    else
        log_error "Không tìm thấy .git repository"
        exit 1
    fi
}

#-------------------------------------------------------------------------------
# Cập nhật cấu hình Nginx
#-------------------------------------------------------------------------------

update_nginx_config() {
    log_info "Cập nhật cấu hình Nginx..."

    # Chỉ update config mới, không ghi đè config tùy chỉnh
    [[ -f install/nginx/nginx.conf ]] && cp install/nginx/nginx.conf $SPANEL_DIR/var/server/nginx/nginx.conf

    # Update các block config trong conf.d
    [[ -d install/nginx/conf.d ]] && cp -r install/nginx/conf.d/* $SPANEL_DIR/var/server/nginx/conf.d/ 2>/dev/null || true

    log_info "Đã cập nhật cấu hình Nginx"
}

#-------------------------------------------------------------------------------
# Cập nhật Lua scripts
#-------------------------------------------------------------------------------

update_lua_scripts() {
    log_info "Cập nhật Lua scripts..."

    [[ -d install/lua ]] && cp -r install/lua/* $SPANEL_DIR/var/server/lua/

    log_info "Đã cập nhật Lua scripts"
}

#-------------------------------------------------------------------------------
# Cập nhật WAF rules
#-------------------------------------------------------------------------------

update_waf_rules() {
    log_info "Cập nhật WAF rules..."

    [[ -d install/waf ]] && cp -r install/waf/* $SPANEL_DIR/var/server/waf/

    log_info "Đã cập nhật WAF rules"
}

#-------------------------------------------------------------------------------
# Cập nhật binary scripts
#-------------------------------------------------------------------------------

update_bin_scripts() {
    log_info "Cập nhật binary scripts..."

    [[ -d install/bin ]] && cp -r install/bin/* $SPANEL_DIR/bin/

    # Cập nhật symlinks
    for script in $SPANEL_DIR/bin/*; do
        local name=$(basename $script)
        ln -sf $script /usr/local/bin/spanel-$name 2>/dev/null || true
    done

    chmod +x $SPANEL_DIR/bin/*

    log_info "Đã cập nhật binary scripts"
}

#-------------------------------------------------------------------------------
# Cập nhật systemd service
#-------------------------------------------------------------------------------

update_systemd_service() {
    log_info "Cập nhật systemd service..."

    [[ -f install/spanel.service ]] && cp install/spanel.service /etc/systemd/system/
    systemctl daemon-reload

    log_info "Đã cập nhật systemd service"
}

#-------------------------------------------------------------------------------
# Chạy migration scripts
#-------------------------------------------------------------------------------

run_migrations() {
    log_info "Chạy migration scripts..."

    if [[ -d install/migrations ]]; then
        for migration in install/migrations/*.sh; do
            if [[ -f $migration ]]; then
                log_info "Chạy: $(basename $migration)"
                bash $migration
            fi
        done
    fi

    log_info "Đã chạy migrations"
}

#-------------------------------------------------------------------------------
# Kiểm tra cấu hình
#-------------------------------------------------------------------------------

validate_config() {
    log_info "Kiểm tra cấu hình..."

    if nginx -t 2>/dev/null; then
        log_info "Cấu hình Nginx hợp lệ"
    else
        log_warn "Cấu hình Nginx có lỗi"
    fi
}

#-------------------------------------------------------------------------------
# Restart services
#-------------------------------------------------------------------------------

restart_services() {
    log_info "Khởi động lại services..."

    systemctl restart span el

    log_info "Đã khởi động lại services"
}

#-------------------------------------------------------------------------------
# MAIN
#-------------------------------------------------------------------------------

main() {
    log_info "Bắt đầu cập nhật SPanel..."

    check_root
    check_current_version
    backup_before_update
    pull_latest_code
    update_nginx_config
    update_lua_scripts
    update_waf_rules
    update_bin_scripts
    update_systemd_service
    run_migrations
    validate_config

    echo ""
    echo "========================================"
    echo -e "${GREEN}SPanel đã được cập nhật thành công!${NC}"
    echo "========================================"
    echo ""
    echo "Thông tin:"
    echo "  Backup: $BACKUP_DIR"
    echo "  Phiên bản mới: $GIT_BRANCH"
    echo ""
    echo "Hành động:"
    echo "  1. Kiểm tra thay đổi: diff -r $BACKUP_DIR $SPANEL_DIR"
    echo "  2. Khởi động lại service: systemctl restart span el"
    echo ""

    read -p "Khởi động lại services ngay? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restart_services
    fi
}

main "$@"