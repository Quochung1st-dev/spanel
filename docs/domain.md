# Quản lý Domain

SPanel cung cấp các lệnh quản lý domain trong thư mục `bin/`.

## Thêm domain mới

```bash
bash bin/v-add-domain example.com
```

Options:
- `--ssl` - Bật SSL
- `--letsencrypt` - Dùng Let's Encrypt
- `--proxy URL` - Tạo reverse proxy (VD: `--proxy https://example.com`)

### Ví dụ:

```bash
# Domain đơn giản
bash bin/v-add-domain example.com

# Domain với SSL tự ký
bash bin/v-add-domain example.com --ssl

# Domain với Let's Encrypt
bash bin/v-add-domain example.com --letsencrypt

# Reverse proxy
bash bin/v-add-domain proxy.example.com --proxy https://backend.internal.com
```

## Xóa domain

```bash
bash bin/v-delete-domain example.com
```

Options:
- `--force` - Xóa không cần backup
- `--no-backup` - Không backup trước khi xóa
- `--list` - Liệt kê domain có thể xóa

## Liệt kê domain

```bash
bash bin/v-list-domain
```

Output:
```
╔════════════════════════════════════════╗
║       SPanel - Domain List              ║
╚════════════════════════════════════════╝

── Enabled ──
  example.com       | SSL ○ | /var/www/example.com
  proxy.example.com | SSL ● | Proxy → https://backend.com

────────────────────────────────────────
  Total: 2                 enabled: 2 | disabled: 0
```

Xem chi tiết một domain:

```bash
bash bin/v-list-domain example.com
```

## Thay đổi domain

### Đổi document root

```bash
bash bin/v-change-domain document-root example.com /var/www/example.com/public
```

### Đổi port

```bash
bash bin/v-change-domain port example.com 8080
```

### Bật/tắt SSL

```bash
# Bật SSL
bash bin/v-change-domain ssl example.com on

# Tắt SSL
bash bin/v-change-domain ssl example.com off
```

### Đổi PHP version

```bash
bash bin/v-change-domain php example.com php81
```

Các PHP version hỗ trợ: `php74`, `php81`, `php82`, `php83`

### Bật/tắt cache

```bash
# Bật cache
bash bin/v-change-domain cache example.com on

# Tắt cache
bash bin/v-change-domain cache example.com off
```

### Đổi WAF mode

```bash
bash bin/v-change-domain waf example.com active
```

Modes:
- `active` - Block request vi phạm (mặc định)
- `passive` - Chỉ log, không block
- `off` - Tắt WAF hoàn toàn

## Rebuild domain

Reset domain về trạng thái mặc định:

```bash
bash bin/v-rebuild-domain example.com
```

Options:
- `--keep-logs` - Giữ lại log hiện tại
- `--list` - Liệt kê domain có thể rebuild

## Cấu trúc thư mục domain

```
/var/www/{domain}/
├── public_html/           # Webroot
│   ├── index.html
│   └── ...
├── logs/                  # Nginx logs
│   ├── access.log
│   └── error.log
├── config/                # Config files (auto-loaded)
│   └── nginx.conf
└── ssl/                   # SSL certificates (nếu có)
    ├── server.crt
    └── server.key
```