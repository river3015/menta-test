#!/bin/sh

process_counts=$(pgrep -a nginx | wc -l)

if [ $process_counts -gt 1 ]; then
        echo 'nginx process 1'
        echo 'nginx is running'
else
        echo 'nginx process 0'
        echo 'nginx is not running'
        sudo systemctl start nginx

        # nginxが起動するまで待機
        sleep 5

        check=$(systemctl is-active nginx)

        # nginxが起動しているか確認
        if [ $check = 'active' ]; then
                echo "nginx is running"
        fi
fi
