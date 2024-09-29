#!/bin/sh
set -eu

PROCESS_COUNTS=$(pgrep -a nginx | wc -l)

if [ ${PROCESS_COUNTS} = 0 ]; then
        echo nginx process ${PROCESS_COUNTS}
        echo nginx is not running
        sudo systemctl start nginx

        # nginxが起動するまで待機
        sleep 5
	echo nginx is running
else
        echo nginx process ${PROCESS_COUNTS}
        echo nginx is running
fi
