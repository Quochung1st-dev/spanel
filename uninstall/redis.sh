#!/bin/bash
#==============================================================================
# Uninstall Redis
# Gỡ cài đặt Redis
#==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

SPANEL_DIR="/var/server"

main() {
    log_info "Gỡ Redis..."

    # Dừng và disable service
    systemctl stop redis-server 2>/dev/null || true
    systemctl disable redis-server 2>/dev/null || true

    # Xóa packages
    apt-get purge -y redis-server redis-tools 2>/dev/null || true

    # Xóa data
    rm -rf /var/lib/redis 2>/dev/null || true
    rm -rf "$SPANEL_DIR/redis" 2>/dev/null || true

    # Xóa logs
    rm -rf /var/log/redis 2>/dev/null || true
    rm -rf "$SPANEL_DIR/logs/redis" 2>/dev/null || true

    # Xóa config (khôi phục backup nếu có)
    if [[ -f /etc/redis/redis.conf.bak ]]; then
        mv /etc/redis/redis.conf.bak /etc/redis/redis.conf
    fi
    rm -f /etc/redis/redis.conf 2>/dev/null || true

    log_info "Hoàn tất gỡ Redis"
}

main "$@"