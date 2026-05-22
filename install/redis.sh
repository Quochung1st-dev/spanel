#!/bin/bash
#==============================================================================
# Redis Installer
# Cài đặt Redis Server
#==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load .env
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    source "$SCRIPT_DIR/.env"
fi

SPANEL_DIR="${SPANEL_DIR:-/var/server}"

#------------------------------------------------------------------------------
# Kiểm tra Redis đã cài chưa
#------------------------------------------------------------------------------

check_redis_installed() {
    log_info "Kiểm tra Redis..."

    if command -v redis-server &>/dev/null; then
        local version=$(redis-server --version 2>/dev/null | head -1)
        log_info "Redis đã được cài: $version"
        return 0
    else
        log_warn "Redis chưa được cài đặt"
        return 1
    fi
}

#------------------------------------------------------------------------------
# Cài đặt Redis
#------------------------------------------------------------------------------

install_redis() {
    log_info "Cài đặt Redis..."

    # Cài Redis từ repo Ubuntu
    apt-get update
    apt-get install -y redis-server

    # Tạo thư mục data và logs
    mkdir -p "$SPANEL_DIR/redis"
    mkdir -p "$SPANEL_DIR/logs/redis"

    log_info "Đã cài Redis"
}

#------------------------------------------------------------------------------
# Cấu hình Redis
#------------------------------------------------------------------------------

configure_redis() {
    log_info "Cấu hình Redis..."

    # Backup config gốc
    if [[ -f /etc/redis/redis.conf ]] && [[ ! -f /etc/redis/redis.conf.bak ]]; then
        cp /etc/redis/redis.conf /etc/redis/redis.conf.bak
    fi

    # Cấu hình Redis cho SPanel
    cat > /etc/redis/redis.conf << 'EOF'
# SPanel Redis Configuration
bind 127.0.0.1
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300

# Persistence
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis

# Logging
loglevel notice
logfile /var/server/logs/redis/redis.log

# Memory
maxmemory 1gb
maxmemory-policy allkeys-lru
maxmemory-samples 5

# Security
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG ""

# Append only file
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
EOF

    # Phân quyền
    chown redis:redis /etc/redis/redis.conf
    chmod 640 /etc/redis/redis.conf

    # Tạo symlink /etc/redis/redis.conf.default
    ln -sf /etc/redis/redis.conf /etc/redis/redis.conf.default 2>/dev/null || true

    # Chạy Redis (systemd có vấn đề trong một số container)
    pkill redis-server 2>/dev/null || true
    sleep 1

    # Tạo thư mục logs
    mkdir -p "$SPANEL_DIR/logs/redis"
    chown redis:redis "$SPANEL_DIR/logs/redis"
    chmod 750 "$SPANEL_DIR/logs/redis"

    # Disable systemd service nếu không hoạt động
    systemctl stop redis-server 2>/dev/null || true

    # Chạy Redis như daemon
    /usr/bin/redis-server /etc/redis/redis.conf --daemonize yes 2>/dev/null || \
        /usr/bin/redis-server /etc/redis/redis.conf &

    sleep 2

    # Verify Redis đang chạy
    if redis-cli ping &>/dev/null; then
        log_info "Redis đang chạy"
    else
        log_warn "Redis không khởi động được qua systemd"
    fi

    log_info "Đã cấu hình Redis"
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

main() {
    log_info "Bắt đầu cài đặt Redis..."

    if ! check_redis_installed; then
        install_redis
    fi

    configure_redis

    echo ""
    log_info "========================================"
    log_info "Redis đã được cài đặt!"
    log_info "========================================"
    log_info "Host: 127.0.0.1:6379"
    log_info "Trạng thái: systemctl status redis-server"
    log_info "CLI: redis-cli"
}

main "$@"