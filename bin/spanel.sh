#!/bin/bash

echo "Spanel CLI"
echo "1. Tạo user"
echo "2. Tạo website"
echo "3. Tạo SQL"
echo "4. Tạo FTP"
read -p "Chọn chức năng (1-4): " choice

case "$choice" in
    1)
        echo "Tạo user..."
        # TODO: Triển khai logic tạo user
        echo "Tạo user hoàn tất!"
        ;;
    2)
        echo "Tạo website..."
        ./bin/create_web.sh
        ;;
    3)
        echo "Tạo SQL..."
        ./bin/create_sql.sh
        ;;
    4)
        echo "Tạo FTP..."
        ./bin/create_ftp.sh
        ;;
    *)
        echo "Lựa chọn không hợp lệ."
        ;;
esac
