# SPanel Documentation

Tài liệu cho SPanel - Control Panel quản lý server web dựa trên OpenResty (Nginx + Lua).

## Tài liệu

| File | Mô tả |
|------|-------|
| [install.md](install.md) | Hướng dẫn cài đặt từng bước |
| [domain.md](domain.md) | Quản lý domain (thêm, xóa, sửa) |
| [commands.md](commands.md) | Tham khảo tất cả lệnh `v-*` |
| [waf.md](waf.md) | Web Application Firewall |
| [cache.md](cache.md) | Proxy cache và purge |
| [ssl.md](ssl.md) | Quản lý SSL certificates |
| [troubleshooting.md](troubleshooting.md) | Khắc phục sự cố |
| [env.md](env.md) | Biến môi trường |

## Quick Start

```bash
# Cài đặt
bash install/openresty.sh
bash install/nginx.sh
bash install/lua.sh
bash install/waf.sh

# Khởi động
bash bin/v-restart start

# Thêm domain
bash bin/v-add-domain example.com --ssl

# Kiểm tra
bash bin/v-check-vps
```
