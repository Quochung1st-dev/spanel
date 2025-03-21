#!/bin/bash

# Tùy chọn phiên bản Nginx
# Lấy các phiên bản Nginx
nginx_versions=$(curl -s https://nginx.org/en/download.html | grep -oP 'nginx-\K[0-9]+\.[0-9]+\.[0-9]+' | sed 's/nginx-//g' | sort -r | uniq)

echo "Chọn phiên bản Nginx:"
versions=($nginx_versions)
for i in "${!versions[@]}"; do
  echo "$((i+1)). Phiên bản ${versions[$i]}"
done
read -p "Nhập lựa chọn (1-${#versions[@]}): " nginx_version_choice

if [[ "$nginx_version_choice" -ge 1 && "$nginx_version_choice" -le "${#versions[@]}" ]]; then
  nginx_version="${versions[$((nginx_version_choice-1))]}"
else
  echo "Lựa chọn không hợp lệ. Mặc định sử dụng phiên bản đầu tiên."
  nginx_version="${versions[0]}"
fi

# Cài đặt Nginx
echo "Cài đặt Nginx phiên bản $nginx_version..."
apt-get install nginx=$nginx_version* -y

# Cài đặt các module
echo "Cài đặt các module Nginx..."
apt-get install nginx-module-http-ssl nginx-module-http-geoip nginx-module-image-filter -y

echo "Cài đặt Nginx hoàn tất!"
