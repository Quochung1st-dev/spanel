#!/bin/bash

echo "Tạo website..."
read -p "Nhập tên miền (ví dụ: example.com): " domain
# Tạo thư mục web root
web_root="/d/xampp/htdocs/spanel/users/$USER/website/$domain"
mkdir -p "$web_root"

# Tạo tệp cấu hình Nginx
cat > /etc/nginx/conf.d/"$domain".conf <<EOF
server {
    listen 80;
    server_name $domain www.$domain;
    root $web_root;

    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Khởi động lại Nginx
systemctl restart nginx

echo "Website $domain đã được tạo thành công!"
