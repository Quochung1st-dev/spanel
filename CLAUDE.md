# SPanel

## Tổng quan

SPanel là một control panel quản lý server web dựa trên nginx, được viết bằng Lua với các tính năng caching và WAF (Web Application Firewall).

## Stack công nghệ

- **Web Server**: Nginx
- **Scripting**: Lua (LuaJIT)
- **Cache**: Tích hợp module cache cho nginx
- **Security**: WAF (Web Application Firewall)
- **Database**: SQLite

## Cấu trúc thư mục

### Trên Server (Runtime)

```
/var/server/                   # SPANEL_DIR - Thư mục runtime
├── nginx/                     # Nginx web server
│   ├── conf.d/                # Config snippets (cache, lua, waf, ssl)
│   ├── sites-available/       # Vhost configs
│   ├── sites-enabled/         # Enabled vhosts (symlinks)
│   ├── sbin/nginx             # Nginx binary
│   └── logs/                  # Nginx logs (error, access)
├── lua/                       # Lua scripts
├── waf/                       # Web Application Firewall
│   ├── rules/                 # WAF rules (sql-injection, xss, lfi, ...)
│   └── logs/                  # WAF logs
├── cache/                     # Cache files
├── ssl/                       # SSL certificates
├── lib/                       # Database (spanel.db)
├── run/                       # PID files
└── logs/                      # General logs

/var/www/                      # Domain data (website files)
└── {domain}/
    ├── public_html/           # Webroot
    ├── logs/                  # Domain logs
    └── config/                # Domain config

/var/backups/                  # Backup files
```

### Source (Clone git)

```
spanel/                        # SCRIPT_DIR - Thư mục source
├── data/                      # Templates để copy vào /var/server
│   ├── nginx/
│   ├── lua/
│   └── waf/
├── install/                   # Install scripts
│   ├── nginx.sh
│   ├── lua.sh
│   ├── waf.sh
│   ├── ssl.sh
│   ├── domain.sh
│   ├── user.sh
│   ├── spanel.service
│   └── logrotate.conf
├── bin/                       # Management scripts
│   ├── v-check-vps
│   ├── v-manager-domain
│   ├── v-add-domain
│   ├── v-change-domain
│   └── v-delete-domain
└── .env                      # Configuration file
```

## Biến môi trường

| Biến | Mặc định | Mô tả |
|------|----------|-------|
| `SPANEL_DIR` | `/var/server` | Thư mục runtime |
| `SPANEL_USER` | `spanel` | User chạy SPanel |
| `SPANEL_GROUP` | `spanel` | Group của SPanel user |

### Các đường dẫn trong .env

```
# Nginx
NGINX_PID_FILE="$SPANEL_DIR/run/nginx.pid"
NGINX_ERROR_LOG="$SPANEL_DIR/logs/nginx/error.log"
NGINX_ACCESS_LOG="$SPANEL_DIR/logs/nginx/access.log"

# Lua
LUA_PATH="$SPANEL_DIR/lua/?.lua;;"
LUA_CPATH="$SPANEL_DIR/luajit/lib/lua/5.1/?.so;;"

# Cache
CACHE_DIR="$SPANEL_DIR/cache"

# WAF
WAF_LOG_DIR="$SPANEL_DIR/logs/waf"
WAF_RULES_DIR="$SPANEL_DIR/waf/rules"

# Database
DB_PATH="$SPANEL_DIR/lib/spanel.db"

# SSL
SSL_CERT_DIR="$SPANEL_DIR/ssl"

# Backup
BACKUP_DIR="/var/backups"
```

## Thành phần chính

### /var/server

| Thư mục | Mô tả |
|---------|-------|
| `nginx/` | File cấu hình nginx (nginx.conf, conf.d/, sites-available/) |
| `lua/` | Các script Lua xử lý request, authentication, API |
| `waf/` | Rules và cấu hình WAF |
| `cache/` | Module cache và các file cache |
| `ssl/` | SSL certificates |
| `lib/` | Database SQLite |
| `run/` | PID files |
| `logs/` | Logs |

### /var/www/{domain}

Mỗi domain được quản lý độc lập:

| Thư mục | Mô tả |
|---------|-------|
| `public_html/` | Webroot của domain |
| `logs/` | Domain logs (nginx) |
| `config/` | Config files |

## Tính năng

- **Quản lý Domain**: Tạo, sửa, xóa domain với cấu hình độc lập
- **Cache**: Tích hợp reverse proxy cache cho static content
- **WAF**: Bảo vệ website khỏi các cuộc tấn công phổ biến (SQL injection, XSS, LFI,...)
- **Logs**: Theo dõi truy cập và lỗi theo từng domain
- **SSL**: Hỗ trợ Let's Encrypt và SSL tùy chỉnh

## Scripts quản lý

```bash
v-check-vps          # Kiểm tra thông tin VPS
v-manager-domain     # Menu quản lý domain
v-add-domain         # Thêm domain mới
v-change-domain      # Thay đổi cấu hình domain
v-delete-domain      # Xóa domain
```