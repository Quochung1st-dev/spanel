# Troubleshooting

## Nginx không start

### Kiểm tra config

```bash
/usr/local/openresty/nginx/sbin/nginx -t -c /var/server/nginx/conf/nginx.conf
```

### Lỗi "Address already in use"

```bash
# Kiểm tra process đang chiếm port
fuser 80/tcp 443/tcp

# Kill process và restart
fuser -k 80/tcp 443/tcp
sleep 2
/usr/local/openresty/nginx/sbin/nginx -c /var/server/nginx/conf/nginx.conf
```

### Lỗi "PID file not found"

```bash
# Tìm nginx master process
pgrep -a nginx

# Kill và restart
kill -9 $(pgrep -f "nginx.*master")
sleep 2
/usr/local/openresty/nginx/sbin/nginx -c /var/server/nginx/conf/nginx.conf
```

## Lỗi 500 Internal Server Error

### Nguyên nhân thường gặp

1. **Lua syntax error** - Kiểm tra error log:
```bash
tail -50 /var/www/{domain}/logs/error.log
```

2. **Module not found** - Kiểm tra Lua path:
```bash
ls -la /var/server/lua/waf.lua
```

3. **Variable not declared** - Cần `set $variable ""` trước `access_by_lua_block`

### Debug Lua

Thêm log tạm thời vào Lua code:
```lua
ngx.log(ngx.ERR, "[DEBUG] key = ", key)
```

Kiểm tra log:
```bash
tail -f /var/www/{domain}/logs/error.log | grep DEBUG
```

## Lỗi 403 Forbidden

### Kiểm tra nguồn 403

```bash
# Kiểm tra WAF log
cat /var/server/logs/waf/blocked.log

# Kiểm tra nginx error log
tail -20 /var/www/{domain}/logs/error.log

# Kiểm tra access log
tail -20 /var/www/{domain}/logs/access.log | grep 403
```

### WAF false positive

1. Tắt WAF tạm thời:
```bash
# Sửa .env
WAF_ENABLED="false"
# Restart nginx
```

2. Whitelist IP:
```bash
bash bin/v-add-whitelist 192.168.1.100 "Office IP"
```

3. Whitelist WordPress admin paths - đã tích hợp sẵn trong `access.lua`:
   - `/wp-admin/`
   - `/wp-login.php`
   - `/wp-admin/admin-ajax.php`

### 403 từ upstream (Cloudflare)

Nếu proxy đến website sử dụng Cloudflare:
```bash
# Test trực tiếp upstream
curl -sk -X POST https://upstream.com/wp-admin/admin-ajax.php -d "action=test"
```

Nếu upstream trả 403, đây là Cloudflare block, không phải SPanel.

## Lỗi 502 Bad Gateway

### Nguyên nhân

1. **Upstream không khả dụng** - Kiểm tra:
```bash
curl -sI https://upstream.com/
```

2. **IPv6 không khả dụng** - Thêm vào nginx config:
```nginx
resolver 8.8.8.8 8.8.4.4 ipv6=off;
```

3. **DNS không resolve** - Thêm resolver vào nginx config

## Cache không hoạt động

### Kiểm tra cache status

```bash
curl -sI https://example.com/ | grep X-Cache-Status
```

### Cache MISS liên tục

Nguyên nhân:
1. Query string luôn có - cache tự động bypass
2. Cookie WordPress - cache bypass cho user đã đăng nhập
3. `proxy_ignore_headers` thiếu - upstream set `Cache-Control: no-cache`

### Cache purge

```bash
# Purge một URL
curl https://example.com/purge/path/to/page

# Purge toàn bộ
curl https://example.com/purge-all
```

## Rate Limit

### Mặc định

- **Giới hạn**: 10000 requests / 60 giây / IP
- **Response**: 429 Too Many Requests khi vượt giới hạn

### Thay đổi giới hạn

Sửa trong `access.lua` hoặc inline Lua:
```lua
local rate_limit_req = tonumber(os.getenv("RATE_LIMIT_REQUESTS") or "10000")
local rate_limit_window = tonumber(os.getenv("RATE_LIMIT_WINDOW") or "60")
```

## Logs

### Vị trí log

| Log | Đường dẫn |
|-----|-----------|
| Nginx access | `/var/www/{domain}/logs/access.log` |
| Nginx error | `/var/www/{domain}/logs/error.log` |
| WAF blocked | `/var/server/logs/waf/blocked.log` |
| Nginx global | `/var/server/logs/nginx/error.log` |

### Xem log real-time

```bash
# Domain access log
tail -f /var/www/{domain}/logs/access.log

# Domain error log
tail -f /var/www/{domain}/logs/error.log

# WAF log
tail -f /var/server/logs/waf/blocked.log

# Tất cả nginx errors
tail -f /var/server/logs/nginx/error.log
```
