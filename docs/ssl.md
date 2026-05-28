# SSL Certificates

SPanel hỗ trợ SSL qua Let's Encrypt và self-signed certificates.

## Thêm SSL cho domain

### Let's Encrypt (khuyến nghị)

```bash
bash bin/v-add-ssl example.com letssl
```

Yêu cầu:
- Domain trỏ về server
- Port 80 mở
- DNS đã được cấu hình

### Self-signed Certificate

```bash
bash bin/v-add-ssl example.com ssl
```

Tự động tạo certificate 365 ngày.

## Xóa SSL

```bash
bash bin/v-delete-ssl example.com
```

Xóa SSL và chuyển domain về HTTP.

## Cấu hình SSL

File `.env`:

```bash
SSL_CERT_DIR="/var/server/ssl"
SSL_PROTOCOL="TLSv1.2 TLSv1.3"
```

Protocol mặc định: TLSv1.2 và TLSv1.3 (an toàn).

## Cấu trúc thư mục SSL

```
/var/server/ssl/{domain}/
├── fullchain.pem        # Certificate + intermediates
├── privkey.pem         # Private key
└── chain.pem           # Intermediate certificates
```

## Kiểm tra SSL

```bash
# Check certificate info
openssl s_client -connect example.com:443 -servername example.com </dev/null | openssl x509 -noout -dates -subject

# Check SSL grade
curl -sI https://example.com/ | head -20
```

## SSL Headers

Khi SSL được bật, các headers được tự động thêm:

```nginx
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

## Mua SSL thương mại

Nếu mua SSL từ provider khác:

1. Upload certificate vào:
   ```
   /var/server/ssl/{domain}/fullchain.pem
   /var/server/ssl/{domain}/privkey.pem
   ```

2. Reload nginx:
   ```bash
   bash bin/v-restart reload-only
   ```

3. Kiểm tra:
   ```bash
   curl -sI https://example.com/ | grep -i "strict-transport"
   ```