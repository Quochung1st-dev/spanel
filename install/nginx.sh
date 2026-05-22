#!/bin/bash
#==============================================================================
# Nginx Installer
# Cài đặt và cấu hình Nginx
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
NGINX_USER="${NGINX_USER:-www-data}"
NGINX_VERSION="${NGINX_VERSION:-1.27.0}"

#------------------------------------------------------------------------------
# Kiểm tra Nginx đã cài đặt chưa
#------------------------------------------------------------------------------

check_nginx_installed() {
    log_info "Kiểm tra Nginx..."

    if command -v nginx &> /dev/null; then
        local installed_version=$(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
        log_info "Nginx đã được cài đặt (version: $installed_version)"
        return 0
    else
        log_warn "Nginx chưa được cài đặt"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Cài đặt Nginx từ source
#------------------------------------------------------------------------------

install_nginx_from_source() {
    log_info "Cài đặt Nginx $NGINX_VERSION từ source..."

    local build_dir="/tmp/nginx-build-$$"
    mkdir -p $build_dir
    cd $build_dir

    # Cài đặt các thư viện cần thiết
    apt-get update
    apt-get install -y \
        build-essential \
        libpcre3 \
        libpcre3-dev \
        zlib1g \
        zlib1g-dev \
        libssl-dev \
        libgd-dev \
        libgeoip-dev \
        libperl4-corelibril-perl

    # Tải Nginx
    wget -q https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
    tar -xzf nginx-$NGINX_VERSION.tar.gz
    cd nginx-$NGINX_VERSION

    # Cấu hình build
    ./configure \
        --prefix=$SPANEL_DIR/nginx \
        --user=$NGINX_USER \
        --group=$NGINX_USER \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_v3_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-http_image_filter_module \
        --with-http_slice_module \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_realip_module \
        --with-stream_ssl_preread_module \
        --with-pcre \
        --with-pcre-jit \
        --with-google_rate_limit \
        --with-cc-opt="-O3" \
        --with-ld-opt="-Wl,-rpath,/usr/local/lib" \
        --with-debug

    # Build và cài đặt
    make -j$(nproc)
    make install

    # Cleanup
    cd /
    rm -rf $build_dir

    log_info "Đã cài đặt Nginx $NGINX_VERSION vào $SPANEL_DIR/nginx"
}

#------------------------------------------------------------------------------
# Cài đặt cấu hình Nginx
#------------------------------------------------------------------------------

install_nginx_config() {
    log_info "Cài đặt cấu hình Nginx..."

    local nginx_conf_dir="$SPANEL_DIR/nginx/conf"

    # Copy nginx.conf chính
    cp data/nginx/nginx.conf $nginx_conf_dir/nginx.conf

    # Copy mime.types
    cp data/nginx/mime.types $nginx_conf_dir/mime.types

    # Copy các block config trong conf.d
    mkdir -p $nginx_conf_dir/conf.d
    cp -r data/nginx/conf.d/* $nginx_conf_dir/conf.d/

    # Tạo thư mục sites-available và sites-enabled
    mkdir -p $nginx_conf_dir/sites-available
    mkdir -p $nginx_conf_dir/sites-enabled

    # Tạo symlink các site
    for site in $nginx_conf_dir/sites-available/*; do
        local name=$(basename $site)
        ln -sf $site $nginx_conf_dir/sites-enabled/$name 2>/dev/null || true
    done

    # Phân quyền
    chown -R root:$NGINX_USER $nginx_conf_dir
    chmod 640 $nginx_conf_dir/*.conf
    chmod 640 $nginx_conf_dir/conf.d/*.conf

    log_info "Đã cài đặt cấu hình Nginx"
}

#------------------------------------------------------------------------------
# Tạo system user cho nginx
#------------------------------------------------------------------------------

create_nginx_user() {
    log_info "Tạo user Nginx..."

    if ! getent group $NGINX_USER &> /dev/null; then
        groupadd -r $NGINX_USER
        log_info "Đã tạo group: $NGINX_USER"
    fi

    if ! getent passwd $NGINX_USER &> /dev/null; then
        useradd -r -g $NGINX_USER -s /bin/false -d /nonexistent -c "nginx user" $NGINX_USER
        log_info "Đã tạo user: $NGINX_USER"
    fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    log_info "Bắt đầu cài đặt Nginx..."

    if ! check_nginx_installed; then
        create_nginx_user
        install_nginx_from_source
    fi

    install_nginx_config

    # Test cấu hình
    if $SPANEL_DIR/nginx/sbin/nginx -t 2>/dev/null; then
        log_info "Cấu hình Nginx hợp lệ"
    else
        log_warn "Cấu hình Nginx có lỗi"
    fi

    log_info "Hoàn tất cài đặt Nginx"
}

main "$@"