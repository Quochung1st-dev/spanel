#!/bin/bash

echo "Cài đặt PHP-FPM và các module cần thiết..."
apt-get install php8.1-fpm php8.1-mysql php8.1-curl php8.1-gd php8.1-mbstring php8.1-xml -y
echo "Cài đặt PHP-FPM hoàn tất!"
