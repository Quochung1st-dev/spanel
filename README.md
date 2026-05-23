# SPanel - Web Server Control Panel

SPanel là một control panel quản lý web server dựa trên OpenResty (Nginx + LuaJIT) với các tính năng caching và WAF (Web Application Firewall) tích hợp.

## Tính năng

- **Quản lý Domain**: Tạo, sửa, xóa domain với cấu hình độc lập
- **SSL Certificates**: Hỗ trợ Let's Encrypt và SSL tùy chỉnh
- **Reverse Proxy Caching**: Cache nội dung động và tĩnh
- **WAF (Web Application Firewall)**:
  - Phát hiện SQL Injection
  - Phát hiện XSS (Cross-Site Scripting)
  - Phát hiện LFI (Local File Inclusion)
  - IP Whitelist/Blocklist
  - Rate Limiting theo IP
- **Logs**: Theo dõi truy cập và lỗi theo từng domain
- **Remote Sync**: Đồng bộ domain và SSL từ server từ xa qua SSH

## Stack công nghệ

- **Web Server**: OpenResty (Nginx + LuaJIT)
- **Scripting**: Lua (LuaJIT)
- **Cache**: Proxy Cache của OpenResty
- **Security**: WAF (Lua-based), CrowdSec (optional)
- **Database**: SQLite (cho metadata)

## Yêu cầu hệ thống

- OS: Ubuntu 20.04+ / Debian 11+
- Root access
- RAM: 1GB+
- Disk: 5GB+

## Cài đặt

```bash
# Clone repository
git clone https://github.com/Quochung1st-dev/spanel.git
cd spanel

# Chạy installer
sudo bash install.sh
```

## Cấu trúc thư mục

### Source (Repository)

```
spanel/
├── bin/                    # Scripts quản lý (symlink to /var/server/bin)
├── install/               # Install scripts cho từng component
├── data/                  # Templates cấu hình
│   ├── nginx/            # Nginx configs
│   ├── lua/              # Lua scripts
│   └── waf/              # WAF rules
├── check/                 # System check scripts
├── uninstall/            # Uninstall scripts
├── .env                   # Configuration
├── install.sh             # Main installer
├── update.sh              # Update script
└── uninstall.sh           # Uninstall script
```

### Runtime (Server)

```
/var/server/               # SPANEL_DIR - Thư mục runtime
├── nginx/                 # Nginx configs
│   ├── conf.d/           # Config snippets (cache, lua, ssl, waf)
│   ├── sites-available/ # Vhost configs
│   └── sites-enabled/    # Enabled vhosts (symlinks)
├── lua/                   # Lua scripts
├── waf/                   # WAF
│   ├── rules/            # WAF rule files
│   └── logs/             # WAF logs
├── cache/                 # Cache files
├── ssl/                   # SSL certificates
├── lib/                   # Database
├── run/                   # PID files
└── logs/                  # Logs

/var/www/                  # Domain data
└── {domain}/
    ├── public_html/      # Webroot
    ├── logs/             # Domain logs
    ├── config/           # Domain config
    └── ssl/              # Domain SSL
```

## Scripts quản lý

```bash
# Domain
v-add-domain <domain>              # Thêm domain mới
v-change-domain <domain>          # Thay đổi domain
v-delete-domain <domain>          # Xóa domain
v-rebuild-domain <domain>         # Rebuild domain config
v-list-domain                     # Liệt kê domains

# SSL
v-add-ssl <domain>                # Thêm SSL cho domain
v-delete-ssl <domain>             # Xóa SSL

# Backup
v-backup-domain <domain>          # Backup domain
v-restore-domain <domain> <file>  # Restore domain

# SSH Sync
v-sync-config                     # Quản lý server SSH
v-sync-all                        # Sync domains từ server

# System
v-check-vps                        # Thông tin VPS
```

## Cấu hình .env

```bash
# Paths
SPANEL_DIR=/var/server
SPANEL_USER=spanel
SPANEL_GROUP=spanel

# Nginx
OPENRESTY_VERSION=1.29.2.4
NGINX_PORT=80
NGINX_SSL_PORT=443

# Cache
CACHE_ENABLED=true
CACHE_SIZE=100m

# WAF
WAF_ENABLED=true
WAF_MODE=active              # active | logonly
WAF_BLOCK_STATUS_CODE=403

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQ_PER_SECOND=10

# SSL
SSL_PROTOCOL=TLSv1.2 TLSv1.3
```

## WAF

### Cấu trúc

```
/var/server/waf/
├── rules/
│   ├── sql-injection.rules
│   ├── xss.rules
│   └── lfi.rules
├── whitelist.ip    # IP được bypass WAF
├── blocklist.ip   # IP bị block
└── logs/
    └── blocked.log
```

### Whitelist/Blocklist Format

```
# Comments start with #
127.0.0.1
::1
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
```

### WAF Modes

- **active**: Block requests vi phạm và trả về 403
- **logonly**: Chỉ log, không block

## Domain Proxy

Tạo domain proxy với caching:

```bash
v-add-domain thietbihop.243.com --proxy https://thietbihop.com
```

Proxy cache config:
- Cache valid: 5 phút
- Static files: 30 ngày
- Bypass cache: Cookie `nocache=1`

## VHost Templates

SPanel cung cấp các template có sẵn cho nhiều loại website:

```bash
# Static website
v-add-domain example.com --template static

# PHP website
v-add-domain example.com --template php

# SSL/PHP website
v-add-domain example.com --template ssl

# Proxy với cache
v-add-domain example.com --template proxy --upstream https://example.com

# WordPress
v-add-domain example.com --template wordpress

# Node.js app
v-add-domain example.com --template node --node-port 3000
```

Templates nằm tại `data/vhost/template/`:
- `static.conf` - Static HTML/CSS/JS
- `php.conf` - PHP website
- `ssl.conf` - HTTPS với SSL
- `proxy.conf` - Reverse proxy với caching
- `node.conf` - Node.js/React app
- `wordpress.conf` - WordPress optimized
- `lua.conf` - Lua access phase (include snippet)

## Logging

Logs được lưu tại:
- Nginx: `/var/server/logs/nginx/`
- WAF: `/var/server/logs/waf/blocked.log`
- Domain: `/var/www/{domain}/logs/`

## Update

```bash
sudo bash update.sh
```

Update script sẽ:
1. Cập nhật bin scripts
2. Cập nhật data (nginx, lua, waf)
3. Reload services

## Uninstall

```bash
sudo bash uninstall.sh
```

## Troubleshooting

### Kiểm tra WAF logs

```bash
tail -f /var/server/logs/waf/blocked.log
```

### Kiểm tra Nginx config

```bash
nginx -t -c /var/server/nginx/conf/nginx.conf
```

### Reload Nginx

```bash
systemctl restart spanel-nginx
```

### Test WAF

```bash
# Safe request
curl "http://domain.com/?q=test"
# Output: OK

# SQL injection
curl "http://domain.com/?q=union+select"
# Output: 403 Forbidden
```

## License

MIT License