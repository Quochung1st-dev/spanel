#!/bin/bash
#==============================================================================
# Domain Manager
# Quản lý domain trong SPanel
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
NGINX_CONF_DIR="$SPANEL_DIR/nginx"
SPANEL_USER="${SPANEL_USER:-spanel}"
SPANEL_GROUP="${SPANEL_GROUP:-spanel}"

#------------------------------------------------------------------------------
# Tạo cấu trúc thư mục domain
#------------------------------------------------------------------------------

create_domain_dirs() {
    local domain=$1

    log_info "Tạo cấu trúc thư mục cho $domain..."

    mkdir -p $SCRIPT_DIR/var/www/$domain/{config,logs,public_html,cgi,tmp}
    mkdir -p $SCRIPT_DIR/var/www/$domain/logs/{nginx,ssl}
    mkdir -p $SCRIPT_DIR/var/www/$domain/config/{ssl,backup}

    # Tạo .htaccess mặc định
    cat > $SCRIPT_DIR/var/www/$domain/public_html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>$domain</title>
</head>
<body>
    <h1>Welcome to $domain</h1>
</body>
</html>
EOF

    # Phân quyền
    chown -R $SPANEL_USER:$SPANEL_GROUP $SCRIPT_DIR/var/www/$domain
    chmod 755 $SCRIPT_DIR/var/www/$domain/public_html

    log_info "Đã tạo cấu trúc thư mục cho $domain"
}

#------------------------------------------------------------------------------
# Tạo Nginx vhost config
#------------------------------------------------------------------------------

create_vhost() {
    local domain=$1
    local port=${2:-80}
    local ssl=${3:-false}

    log_info "Tạo Nginx vhost cho $domain..."

    local conf_file="$NGINX_CONF_DIR/sites-available/$domain.conf"

    if $ssl; then
        local ssl_cert="$SPANEL_DIR/ssl/$domain/fullchain.pem"
        local ssl_key="$SPANEL_DIR/ssl/$domain/privkey.pem"

        cat > $conf_file <<EOF
server {
    listen 80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    root $SCRIPT_DIR/var/www/$domain/public_html;
    index index.php index.html index.htm;

    access_log $SCRIPT_DIR/var/www/$domain/logs/nginx/access.log;
    error_log $SCRIPT_DIR/var/www/$domain/logs/nginx/error.log;

    ssl_certificate $ssl_cert;
    ssl_certificate_key $ssl_key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers on;

    # WAF
    set \$waf_mode active;
    set \$waf_rule_dir $SPANEL_DIR/waf/rules;

    # Cache config
    set \$cache_enabled true;

    include $SPANEL_DIR/nginx/conf.d/cache.conf;
    include $SPANEL_DIR/nginx/conf.d/lua.conf;
    include $SPANEL_DIR/nginx/conf.d/waf.conf;
}
EOF
    else
        cat > $conf_file <<EOF
server {
    listen $port;
    server_name $domain;

    root $SCRIPT_DIR/var/www/$domain/public_html;
    index index.php index.html index.htm;

    access_log $SCRIPT_DIR/var/www/$domain/logs/nginx/access.log;
    error_log $SCRIPT_DIR/var/www/$domain/logs/nginx/error.log;

    # WAF
    set \$waf_mode active;
    set \$waf_rule_dir $SPANEL_DIR/waf/rules;

    # Cache config
    set \$cache_enabled true;

    include $SPANEL_DIR/nginx/conf.d/cache.conf;
    include $SPANEL_DIR/nginx/conf.d/lua.conf;
    include $SPANEL_DIR/nginx/conf.d/waf.conf;
}
EOF
    fi

    log_info "Đã tạo vhost config tại $conf_file"
}

#------------------------------------------------------------------------------
# Enable domain
#------------------------------------------------------------------------------

enable_domain() {
    local domain=$1

    log_info "Enable domain $domain..."

    local conf_file="$NGINX_CONF_DIR/sites-available/$domain.conf"
    local enabled_link="$NGINX_CONF_DIR/sites-enabled/$domain.conf"

    if [[ ! -f $conf_file ]]; then
        log_error "Không tìm thấy config cho $domain"
        return 1
    fi

    if [[ ! -L $enabled_link ]]; then
        ln -sf $conf_file $enabled_link
        log_info "Đã enable $domain"
    else
        log_warn "$domain đã được enable"
    fi

    # Test và reload nginx
    if $SPANEL_DIR/nginx/sbin/nginx -t 2>/dev/null; then
        $SPANEL_DIR/nginx/sbin/nginx -s reload 2>/dev/null || true
        log_info "Đã reload Nginx"
    else
        log_error "Cấu hình Nginx có lỗi"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Disable domain
#------------------------------------------------------------------------------

disable_domain() {
    local domain=$1

    log_info "Disable domain $domain..."

    local enabled_link="$NGINX_CONF_DIR/sites-enabled/$domain.conf"

    if [[ -L $enabled_link ]]; then
        rm $enabled_link
        log_info "Đã disable $domain"
    else
        log_warn "$domain chưa được enable"
    fi

    # Reload nginx
    $SPANEL_DIR/nginx/sbin/nginx -s reload 2>/dev/null || true
}

#------------------------------------------------------------------------------
# Delete domain
#------------------------------------------------------------------------------

delete_domain() {
    local domain=$1

    log_info "Xóa domain $domain..."

    read -p "Bạn có chắc muốn xóa $domain? (y/n): " confirm
    if [[ $confirm != "y" ]]; then
        log_info "Đã hủy"
        return 0
    fi

    # Disable trước
    disable_domain $domain

    # Xóa config
    rm -f $NGINX_CONF_DIR/sites-available/$domain.conf

    # Xóa thư mục
    rm -rf $SCRIPT_DIR/var/www/$domain

    log_info "Đã xóa $domain"
}

#------------------------------------------------------------------------------
# List domains
#------------------------------------------------------------------------------

list_domains() {
    log_info "Danh sách domains..."

    echo ""
    echo "Enabled domains:"
    for conf in $NGINX_CONF_DIR/sites-enabled/*; do
        if [[ -L $conf ]]; then
            basename $conf .conf
        fi
    done

    echo ""
    echo "Available domains:"
    for conf in $NGINX_CONF_DIR/sites-available/*.conf; do
        if [[ -f $conf ]]; then
            basename $conf .conf
        fi
    done
    echo ""
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    local action=${1:-help}

    case $action in
        create)
            create_domain_dirs $2
            create_vhost $2 ${3:-80} ${4:-false}
            enable_domain $2
            ;;
        enable)
            enable_domain $2
            ;;
        disable)
            disable_domain $2
            ;;
        delete)
            delete_domain $2
            ;;
        list)
            list_domains
            ;;
        *)
            echo "Usage: $0 {create|enable|disable|delete|list} [domain] [port] [ssl]"
            ;;
    esac
}

main "$@"