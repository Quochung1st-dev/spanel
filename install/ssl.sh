#!/bin/bash
#==============================================================================
# SSL Certificate Manager
# Quản lý SSL certificates cho các domain
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
SSL_CERT_DIR="${SSL_CERT_DIR:-$SPANEL_DIR/ssl}"
SSL_PROTOCOL="${SSL_PROTOCOL:-TLSv1.2 TLSv1.3}"

#------------------------------------------------------------------------------
# Kiểm tra Certbot đã cài đặt chưa
#------------------------------------------------------------------------------

check_certbot() {
    if command -v certbot &> /dev/null; then
        return 0
    else
        log_warn "Certbot chưa được cài đặt"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Tạo self-signed certificate cho testing
#------------------------------------------------------------------------------

create_self_signed() {
    local domain=$1
    local cert_dir="$SSL_CERT_DIR/$domain"

    log_info "Tạo self-signed certificate cho $domain..."

    mkdir -p $cert_dir

    openssl req -x509 \
        -nodes -days 365 -newkey rsa:2048 \
        -keyout $cert_dir/privkey.pem \
        -out $cert_dir/fullchain.pem \
        -subj "/C=VN/ST=HCM/L=HCM/O=SPanel/CN=$domain"

    log_info "Đã tạo certificate tại $cert_dir"
}

#------------------------------------------------------------------------------
# Cài đặt Let's Encrypt certificate
#------------------------------------------------------------------------------

install_letsencrypt() {
    local domain=$1
    local email="${2:-admin@$domain}"
    local cert_dir="$SSL_CERT_DIR/$domain"

    log_info "Cài đặt Let's Encrypt cho $domain..."

    if ! check_certbot; then
        log_error "Vui lòng cài đặt certbot trước"
        exit 1
    fi

    mkdir -p $cert_dir

    certbot certonly --webroot \
        --webroot-path /var/www/$domain/public_html \
        --domain $domain \
        --email $email \
        --agree-tos \
        --noninteractive \
        --cert-path $cert_dir/fullchain.pem \
        --key-path $cert_dir/privkey.pem

    log_info "Đã cài đặt Let's Encrypt certificate cho $domain"
}

#------------------------------------------------------------------------------
# Renew certificates
#------------------------------------------------------------------------------

renew_certificates() {
    log_info "Renew SSL certificates..."

    if ! check_certbot; then
        log_error "Certbot không có sẵn"
        return 1
    fi

    certbot renew --noninteractive

    log_info "Đã renew certificates"
}

#------------------------------------------------------------------------------
# Kiểm tra certificate
#------------------------------------------------------------------------------

check_certificate() {
    local domain=$1
    local cert_file="$SSL_CERT_DIR/$domain/fullchain.pem"

    if [[ -f $cert_file ]]; then
        openssl x509 -in $cert_file -noout -dates
        openssl x509 -in $cert_file -noout -subject
    else
        log_error "Certificate không tồn tại cho $domain"
        return 1
    fi
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    local action=${1:-help}

    case $action in
        self-signed)
            create_self_signed $2
            ;;
        letsencrypt)
            install_letsencrypt $2 $3
            ;;
        renew)
            renew_certificates
            ;;
        check)
            check_certificate $2
            ;;
        *)
            echo "Usage: $0 {self-signed|letsencrypt|renew|check} [domain] [email]"
            ;;
    esac
}

main "$@"