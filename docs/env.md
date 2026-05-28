# Environment Variables

File cấu hình chính: `/var/server/.env`

## Paths

| Variable | Default | Mô tả |
|----------|---------|-------|
| `SPANEL_DIR` | `/var/server` | Thư mục runtime chính |
| `OPENRESTY_DIR` | `/usr/local/openresty` | Thư mục cài đặt OpenResty |
| `CACHE_DIR` | `$SPANEL_DIR/cache` | Thư mục cache files |
| `BACKUP_DIR` | `/var/backups` | Thư mục backups |
| `DB_PATH` | `$SPANEL_DIR/lib/spanel.db` | SQLite database path |
| `SSL_CERT_DIR` | `$SPANEL_DIR/ssl` | SSL certificates directory |

## Nginx

| Variable | Default | Mô tả |
|----------|---------|-------|
| `OPENRESTY_VERSION` | `1.29.2.4` | Phiên bản OpenResty |
| `NGINX_VERSION` | `1.29.1` | Phiên bản Nginx |
| `NGINX_USER` | `www-data` | User chạy nginx worker |
| `NGINX_PORT` | `80` | HTTP port |
| `NGINX_SSL_PORT` | `443` | HTTPS port |
| `NGINX_WORKER_PROCESSES` | `auto` | Số worker processes |
| `NGINX_WORKER_CONNECTIONS` | `1024` | Kết nối tối đa mỗi worker |
| `NGINX_PID_FILE` | `$SPANEL_DIR/run/nginx.pid` | PID file |
| `MAX_BODY_SIZE` | `256m` | Kích thước body tối đa |
| `KEEPALIVE_TIMEOUT` | `65` | Keep-alive timeout |

## Lua

| Variable | Default | Mô tả |
|----------|---------|-------|
| `LUA_PATH` | `$SPANEL_DIR/lua/?.lua;;` | Lua module search path |
| `LUA_CPATH` | `$SPANEL_DIR/luajit/lib/lua/5.1/?.so;;` | Lua C module path |

## Cache

| Variable | Default | Mô tả |
|----------|---------|-------|
| `CACHE_ENABLED` | `true` | Bật/tắt cache |
| `CACHE_SIZE` | `100m` | Default cache size |
| `CACHE_INACTIVE` | `60d` | Thời gian inactive trước khi xóa |
| `CACHE_MAX_SIZE` | `5g` | Kích thước cache tối đa |
| `CACHE_USE_STALE` | `error timeout updating` | Dùng stale cache khi nào |
| `CACHE_MIN_USES` | `2` | Số request tối thiểu để cache |

## WAF

| Variable | Default | Mô tả |
|----------|---------|-------|
| `WAF_ENABLED` | `true` | Bật/tắt WAF |
| `WAF_MODE` | `active` | Mode: `active`, `passive`, `off` |
| `WAF_BLOCK_STATUS_CODE` | `403` | HTTP status khi block |
| `WAF_LOG_DIR` | `$SPANEL_DIR/logs/waf` | WAF log directory |
| `WAF_RULES_DIR` | `$SPANEL_DIR/waf/rules` | WAF rules directory |
| `WAF_LOG_LEVEL` | `info` | Log level |

## Rate Limiting

| Variable | Default | Mô tả |
|----------|---------|-------|
| `RATE_LIMIT_ENABLED` | `true` | Bật/tắt rate limit |
| `RATE_LIMIT_REQUESTS` | `10000` | Số requests tối đa |
| `RATE_LIMIT_WINDOW` | `60` | Khung thời gian (giây) |

## SSL

| Variable | Default | Mô tả |
|----------|---------|-------|
| `SSL_PROTOCOL` | `TLSv1.2 TLSv1.3` | TLS versions |
| `SSL_CIPHERS` | Mozilla intermediate | SSL cipher suites |
| `SSL_PREFER_SERVER_CIPHERS` | `on` | Ưu tiên server ciphers |

## Redis

| Variable | Default | Mô tả |
|----------|---------|-------|
| `REDIS_HOST` | `127.0.0.1` | Redis host |
| `REDIS_PORT` | `6379` | Redis port |
| `REDIS_PASSWORD` | `` | Redis password (optional) |
| `REDIS_DATABASE` | `0` | Redis database number |

## Backup

| Variable | Default | Mô tả |
|----------|---------|-------|
| `BACKUP_ENABLED` | `true` | Bật/tắt backup |
| `BACKUP_RETENTION_DAYS` | `30` | Số ngày giữ backup |
| `BACKUP_COMPRESSION` | `gzip` | Nén backup |

## Logging

| Variable | Default | Mô tả |
|----------|---------|-------|
| `LOG_LEVEL` | `info` | Log level |
| `LOG_ROTATE_SIZE` | `100m` | Kích thước trước khi rotate |
| `LOG_ROTATE_DAYS` | `7` | Số ngày giữ log |