#!/bin/bash

echo "Cài đặt Spanel..."

# Cập nhật hệ thống
apt-get update -y

# Cài đặt Nginx
echo "Cài đặt Nginx..."
./install/nginx/nginx.sh

# Cài đặt MariaDB
echo "Cài đặt MariaDB..."
./install/mariasql/mariasql.sh

# Cài đặt PHP-FPM và các module cần thiết
echo "Cài đặt PHP-FPM..."
./install/php/php.sh

# Cài đặt FTP
echo "Cài đặt FTP..."
./install/ftp/ftp.sh

# Cài đặt phpMyAdmin
echo "Cài đặt phpMyAdmin..."
./install/phpmyadmin/phpmyadmin.sh

# Cài đặt Redis
echo "Cài đặt Redis..."
./install/redis/redis.sh

# Tạo thư mục log cho Nginx và PHP-FPM
mkdir -p /var/log/nginx
mkdir -p /var/log/php-fpm

echo "Spanel đã được cài đặt thành công!"
