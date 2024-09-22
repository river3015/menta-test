#!/bin/bash

BACKUP_DIR="/var/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/$DATE.sql"

mysqldump --defaults-extra-file=/home/menta/.mysql_backup.cnf --all-databases --single-transaction --quick --default-character-set=utf8mb4 > $BACKUP_FILE

find $BACKUP_DIR -type f -name "*.sql" -mtime +5 -exec rm {} \;

