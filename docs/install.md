# SPanel - Hướng dẫn cài đặt

## Yêu cầu hệ thống

- **OS**: Ubuntu 20.04+ / Debian 11+
- **RAM**: Tối thiểu 1GB
- **Disk**: Tối thiểu 10GB
- **Quyền**: root

## Cài đặt từng bước

### 1. Clone source

```bash
git clone https://github.com/Quochung1st-dev/spanel.git /root/spanel
cd /root/spanel
```

### 2. Cấu hình .env

Sao chép và chỉnh sửa file cấu hình:

```bash
cp .env .env.local
nano .env
```

Các biến quan trọng cần kiểm tra:

| Biến | Mặc định | Mô tả |
|------|----------|-------|
| `SPANEL_DIR` | `/var/server` | Thư mục runtime |
| `OPENRESTY_VERSION` | `1.29.2.4` | Phiên bản OpenResty |
| `NGINX_USER` | `www-data` | User chạy nginx |

### 3. Cài đặt OpenResty

```bash
bash install/openresty.sh
```

Script tự động:
- Thêm repo OpenResty
- Cài đặt OpenResty + OpenSSL3, PCRE, Zlib
- Kiểm tra Lua module

### 4. Cài đặt Nginx config

```bash
bash install/nginx.sh
```

Copy cấu hình nginx vào `/var/server/nginx/conf/`:
- `nginx.conf` - Master config
- `conf.d/` - Lua, cache, WAF, SSL config
- `sites-available/` - Default, panel, debug
- `vhost/` - Template files

Cài đặt systemd service `spanel-nginx`.

### 5. Cài đặt Lua scripts

```bash
bash install/lua.sh
```

Copy Lua scripts vào `/var/server/lua/`:
- `waf.lua` - WAF module
- `access.lua` - Access phase handler
- `rewrite.lua`, `header_filter.lua`, `body_filter.lua`, `log.lua`

### 6. Cài đặt WAF rules

```bash
bash install/waf.sh
```

Tạo cấu trúc thư mục `/var/server/waf/`:
- `rules/` - SQL injection, XSS, LFI rules
- `logs/` - WAF log files
- `whitelist.ip` - IP whitelist (mặc định: localhost + private networks)
- `blocklist.ip` - IP blocklist

### 7. Cài đặt Redis (tuỳ chọn)

```bash
bash install/redis.sh
```

Cấu hình Redis:
- Bind 127.0.0.1:6379
- Max memory 1GB (LRU)
- AOF persistence
- Disable FLUSHDB, FLUSHALL, CONFIG

### 8. Cài đặt CrowdSec (tuỳ chọn)

```bash
bash install/crowdsec.sh
```

Cài đặt CrowdSec + nginx collection + http-crawl collection.

### 9. Cài đặt logrotate

```bash
cp install/logrotate.conf /etc/logrotate.d/spanel
```

Rotation:
- SSL keys: weekly, 52 weeks
- Nginx logs: daily, 14 days
- WAF logs: daily, 30 days

### 10. Khởi động dịch vụ

```bash
systemctl enable spanel-nginx
systemctl start spanel-nginx
```

Hoặc dùng lệnh SPanel:

```bash
bash bin/v-restart start
```

## Kiểm tra cài đặt

```bash
# Kiểm tra thông tin VPS
bash bin/v-check-vps

# Kiểm tra trạng thái dịch vụ
bash bin/v-restart status

# Kiểm tra config nginx
/usr/local/openresty/nginx/sbin/nginx -t -c /var/server/nginx/conf/nginx.conf
```

## Gỡ cài đặt

```bash
# Dừng dịch vụ
systemctl stop spanel-nginx
systemctl disable spanel-nginx

# Xóa SPanel
rm -rf /var/server
rm -f /etc/systemd/system/spanel-nginx.service
systemctl daemon-reload
```
