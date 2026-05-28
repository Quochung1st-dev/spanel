# SPanel Commands Reference

## Domain Management

| Lệnh | Mô tả |
|------|-------|
| `v-add-domain <domain> [options]` | Thêm domain mới |
| `v-delete-domain <domain> [options]` | Xóa domain |
| `v-change-domain <cmd> <domain> [args]` | Thay đổi cấu hình |
| `v-list-domain [domain]` | Liệt kê domain |
| `v-template-domain <domain> <template> [ssl]` | Tạo domain từ template |
| `v-rebuild-domain <domain> [options]` | Rebuild domain |

## SSL

| Lệnh | Mô tả |
|------|-------|
| `v-add-ssl <domain> [type]` | Thêm SSL (`letssl` hoặc `ssl`) |
| `v-delete-ssl <domain>` | Xóa SSL |

## Backup & Restore

| Lệnh | Mô tả |
|------|-------|
| `v-backup-domain <domain>` | Backup domain |
| `v-backup-domains` | Backup toàn bộ domain |
| `v-restore-domain <domain> <file> [options]` | Restore từ backup |

## WAF & IP Management

| Lệnh | Mô tả |
|------|-------|
| `v-add-blocklist <IP> [reason]` | Thêm IP vào blocklist |
| `v-delete-blocklist <IP>` | Xóa IP khỏi blocklist |
| `v-list-blocklist` | Liệt kê blocked IPs |
| `v-add-whitelist <IP> [reason]` | Thêm IP vào whitelist |
| `v-delete-whitelist <IP>` | Xóa IP khỏi whitelist |
| `v-list-whitelist` | Liệt kê whitelisted IPs |

## System

| Lệnh | Mô tả |
|------|-------|
| `v-check-vps` | Kiểm tra thông tin VPS |
| `v-restart [action]` | Quản lý dịch vụ |

### v-restart actions

| Action | Mô tả |
|--------|-------|
| `restart` (mặc định) | Restart nginx + redis + crowdsec |
| `start` | Khởi động dịch vụ |
| `stop` | Dừng dịch vụ |
| `status` | Xem trạng thái |
| `reload-only` | Reload nginx |

## Chi tiết lệnh

### v-add-domain

```bash
v-add-domain <domain> [--ssl] [--letsencrypt] [--proxy <url>]
```

Tạo cấu trúc thư mục `/var/www/<domain>/` (public_html, logs, config, ssl).
Tạo nginx vhost config. Option `--proxy` tạo reverse proxy với cache.

### v-change-domain

```bash
v-change-domain <command> <domain> [arguments]
```

| Command | Arguments | Mô tả |
|---------|-----------|-------|
| `document-root` | `<path>` | Đổi document root |
| `port` | `<port>` | Đổi listen port |
| `ssl` | `on\|off` | Bật/tắt SSL |
| `php` | `<version>` | Đổi PHP version |
| `cache` | `on\|off` | Bật/tắt cache |
| `waf` | `<mode>` | Đổi WAF mode |

### v-add-ssl

```bash
v-add-ssl <domain> [type]
```

| Type | Mô tả |
|------|-------|
| `letssl` | Let's Encrypt (mặc định) |
| `ssl` | Self-signed certificate |

### v-template-domain

```bash
v-template-domain <domain> <template> [ssl-type]
```

Tạo domain từ template với các biến tùy chỉnh.

#### Templates có sẵn

| Template | Mô tả |
|---------|-------|
| `template_nginx_cache_lua_proxy` | Nginx proxy với cache, Lua WAF, rate limiting |
| `domain-ssl` | Domain đơn giản với SSL |
| `domain` | Domain cơ bản |
| `default` | Default template |
| `panel` | SPanel panel |
| `cache` | Chỉ cache config (không phải domain template) |

#### SSL Types

| Type | Mô tả |
|------|-------|
| `ssl` | Tạo self-signed certificate |
| `letsencrypt` | Cài đặt Let's Encrypt certificate |
| (không ghi) | Không tạo SSL |

#### Ví dụ

```bash
# Tạo domain không có SSL
v-template-domain example.com template_nginx_cache_lua_proxy

# Tạo domain với self-signed SSL
v-template-domain example.com template_nginx_cache_lua_proxy ssl

# Tạo domain với Let's Encrypt
v-template-domain example.com template_nginx_cache_lua_proxy letsencrypt
```

#### Tùy chọn khác

```bash
# Liệt kê templates
v-template-domain --list

# Xem thông tin template
v-template-domain --info template_nginx_cache_lua_proxy

# Trợ giúp
v-template-domain --help
```

#### Output thư mục

Khi tạo domain, script tạo:
- `/var/www/<domain>/public_html/` - Webroot
- `/var/www/<domain>/logs/` - Nginx logs
- `/var/www/<domain>/config/` - Cấu hình domain
- `/var/www/<domain>/ssl/` - SSL certificates (nếu dùng ssl-type)
- `/var/server/nginx/conf/conf.d/cache_<domain>.conf` - Cache config (nếu template yêu cầu)
- `/var/server/nginx/conf/sites-enabled/<domain>.conf` - Symlink đến config
