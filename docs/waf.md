# WAF - Web Application Firewall

SPanel tích hợp WAF viết bằng Lua, bảo vệ website khỏi các cuộc tấn công phổ biến.

## Tính năng

- **SQL Injection Detection** - Phát hiện các pattern như UNION SELECT, OR 1=1, stacked queries
- **XSS Detection** - Phát hiện script tags, event handlers, javascript protocols
- **LFI Detection** - Phát hiện directory traversal, file inclusion attempts
- **IP Blocking** - Block IP tạm thời khi phát hiện tấn công
- **Whitelist** - Bypass WAF cho IP đáng tin cậy
- **Logging** - Ghi log request bị block

## Cấu hình

File `.env`:

```bash
WAF_ENABLED="true"
WAF_MODE="active"           # active | passive | off
WAF_BLOCK_STATUS_CODE="403"
WAF_LOG_DIR="/var/server/logs/waf"
WAF_RULES_DIR="/var/server/waf/rules"
```

### WAF Modes

| Mode | Hành vi |
|------|---------|
| `active` | Block và trả về 403 khi phát hiện tấn công |
| `passive` | Chỉ log, không block request |
| `off` | Tắt hoàn toàn WAF |

## Quản lý IP

### Block IP

```bash
# Block IP
bash bin/v-add-blocklist 192.168.1.100 "Spam attacks"

# List blocked IPs
bash bin/v-list-blocklist

# Unblock IP
bash bin/v-delete-blocklist 192.168.1.100
```

### Whitelist IP

```bash
# Whitelist IP (bypass WAF hoàn toàn)
bash bin/v-add-whitelist 10.0.0.1 "Internal server"

# List whitelisted IPs
bash bin/v-list-whitelist

# Remove from whitelist
bash bin/v-delete-whitelist 10.0.0.1
```

Default whitelist chứa:
- `127.0.0.1`, `::1` (localhost)
- `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` (private networks)

## WAF Rules

Rules nằm trong `/var/server/waf/rules/`:

```
/var/server/waf/
├── rules/
│   ├── sql-injection.rules
│   ├── xss.rules
│   └── lfi.rules
└── logs/
    └── blocked.log
```

### SQL Injection Patterns

```regex
union\s+select
union\s+all\s+select
select\s+from
insert\s+into
delete\s+from
drop\s+table
exec\s*\(
's*or\s*'1'\s*=\s*'1
```

### XSS Patterns

```regex
<script
javascript:
onerror\s*=
onload\s*=
eval\s*\(
document\.cookie
```

### LFI Patterns

```regex
\.\.\/
/etc/passwd
/proc/self
```

## Logs

Block log: `/var/server/logs/waf/blocked.log`

Format:
```
[TIMESTAMP] IP | RULE | REASON | URI
```

Ví dụ:
```
[2026-05-28 10:30:00] 192.168.1.100 | sql_injection | SQL Injection Pattern | /search?q=test' OR 1=1
```

## Per-Domain WAF

Thay đổi WAF cho một domain cụ thể:

```bash
bash bin/v-change-domain waf example.com active
bash bin/v-change-domain waf example.com passive
bash bin/v-change-domain waf example.com off
```