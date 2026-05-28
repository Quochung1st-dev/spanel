# Proxy Cache

SPanel tích hợp reverse proxy cache dựa trên nginx proxy_cache, hỗ trợ cache purge.

## Cấu hình cache

File `.env`:

```bash
CACHE_ENABLED="true"
CACHE_DIR="/var/server/cache"
CACHE_SIZE="100m"
CACHE_INACTIVE="60d"
CACHE_MAX_SIZE="5g"
CACHE_USE_STALE="error timeout updating"
CACHE_MIN_USES="2"
```

## Cache behavior

### Nội dung dynamic (HTML/PHP)

- **Cache time**: 5 phút
- **Cache key**: `$scheme$host$request_uri`
- **Bypass**: Query string, WordPress cookies
- **Stale**: Serve cache cũ khi upstream lỗi

### Nội dung static (CSS/JS/fonts)

- **Cache time**: 90 ngày
- **Cache key**: `$scheme$host$request_uri`
- **Bypass**: Query string
- **Types**: `.css`, `.js`, `.woff`, `.woff2`, `.ttf`, `.eot`, `.otf`

## Cache bypass

Cache tự động bypass khi:

1. **Có query string** - `?param=value`
2. **Có WordPress cookies** - `wordpress_logged_in_*`, `wp-settings-*`, `woocommerce_*`, v.v.
3. **Tham số `nocache`** - `?nocache=1`

## Cache purge

### Purge một URL

```
GET https://example.com/purge/path/to/page
```

Response:
```
Purged: /path/to/page
```

Nếu không tìm thấy trong cache:
```
Not found in cache: /path/to/page
```

### Purge toàn bộ cache

```
GET https://example.com/purge-all
```

Response:
```
Cache flushed: Done
```

### Cache status header

Mỗi response có header `X-Cache-Status`:

| Status | Mô tả |
|--------|-------|
| `MISS` | Request không tìm thấy trong cache |
| `HIT` | Request được phục vụ từ cache |
| `EXPIRED` | Cache đã hết hạn |
| `STALE` | Đang dùng cache cũ do upstream lỗi |
| `BYPASS` | Cache bị bỏ qua |

## Kiểm tra cache

```bash
# Check cache status
curl -sI https://example.com/ | grep X-Cache-Status

# Force bypass
curl -sI https://example.com/?nocache=1

# Purge homepage
curl https://example.com/purge/

# Purge toàn bộ
curl https://example.com/purge-all
```

## Cấu trúc cache trên disk

```
/var/server/cache/
├── 0/
├── 1/
├── ...
├── a/
├── b/
├── ...
└── f/
```

Cache file path được tính bằng MD5 của cache key:
- Cache key: `https://example.com/path/to/page`
- MD5 hash: `abc123...`
- Path: `/var/server/cache/{last_char}/{2_chars_before_last}/{full_hash}`
