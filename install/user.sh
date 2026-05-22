#!/bin/bash
#==============================================================================
# User & Group Manager
# Tạo user và group cho SPanel
#==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SPANEL_DIR="${SPANEL_DIR:-/var/server}"
SPANEL_USER="${SPANEL_USER:-spanel}"
SPANEL_GROUP="${SPANEL_GROUP:-spanel}"
NGINX_USER="${NGINX_USER:-www-data}"

#------------------------------------------------------------------------------
# Tạo user và group
#------------------------------------------------------------------------------

create_spanel_user() {
    log_info "Tạo user SPanel..."

    # Tạo group
    if ! getent group $SPANEL_GROUP &> /dev/null; then
        groupadd -r $SPANEL_GROUP
        log_info "Đã tạo group: $SPANEL_GROUP"
    else
        log_info "Group $SPANEL_GROUP đã tồn tại"
    fi

    # Tạo user
    if ! getent passwd $SPANEL_USER &> /dev/null; then
        useradd -r -g $SPANEL_GROUP -s /bin/false -d $SPANEL_DIR -c "SPanel user" $SPANEL_USER
        log_info "Đã tạo user: $SPANEL_USER"
    else
        log_info "User $SPANEL_USER đã tồn tại"
    fi

    # Đảm bảo nginx user thuộc group span el
    if ! groups $NGINX_USER | grep -q $SPANEL_GROUP; then
        usermod -aG $SPANEL_GROUP $NGINX_USER
        log_info "Đã thêm $NGINX_USER vào group $SPANEL_GROUP"
    fi
}

#------------------------------------------------------------------------------
# Tạo cấu trúc thư mục
#------------------------------------------------------------------------------

create_directory_structure() {
    log_info "Tạo cấu trúc thư mục..."

    # Thư mục chính
    mkdir -p $SPANEL_DIR/{bin,var/{server/{nginx,lua,cache,waf},www},logs,run,tmp}

    # Thư mục nginx
    mkdir -p $SPANEL_DIR/nginx/{conf,conf.d,sites-available,sites-enabled,logs,pid}
    mkdir -p $SPANEL_DIR/nginx/{client_body_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp}

    # Thư mục WAF
    mkdir -p $SPANEL_DIR/waf/{rules,logs,tmp}

    # Thư mục cache
    mkdir -p $SPANEL_DIR/cache

    # Thư mục logs
    mkdir -p $SPANEL_DIR/logs/{nginx,waf,spanel}
    mkdir -p $SPANEL_DIR/nginx/logs

    # Thư mục run
    mkdir -p $SPANEL_DIR/run

    # Thư mục tmp
    mkdir -p $SPANEL_DIR/tmp

    # Phân quyền thư mục
    chown -R $SPANEL_USER:$SPANEL_GROUP $SPANEL_DIR
    chmod 755 $SPANEL_DIR
    chmod 700 $SPANEL_DIR/tmp
    chmod 700 $SPANEL_DIR/logs
    chmod 700 $SPANEL_DIR/run

    log_info "Đã tạo cấu trúc thư mục tại $SPANEL_DIR"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    log_info "Bắt đầu tạo user và cấu trúc..."

    create_spanel_user
    create_directory_structure

    log_info "Hoàn tất tạo user và cấu trúc"
}

main "$@"