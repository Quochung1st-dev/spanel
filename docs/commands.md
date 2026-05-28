# SPanel Commands Reference

## Domain Management

| Lệnh | Mô tả |
|------|-------|
| `v-add-domain <domain> [options]` | Thêm domain mới |
| `v-delete-domain <domain> [options]` | Xóa domain |
| `v-change-domain <cmd> <domain> [args]` | Thay đổi cấu hình |
| `v-list-domain [domain]` | Liệt kê domain |
| `v-template-domain <domain> <template>` | Tạo domain từ template |
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
