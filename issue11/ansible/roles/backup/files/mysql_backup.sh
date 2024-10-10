#!/bin/bash

set -eu

BACKUP_DIR="/var/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/$DATE.sql"

mysqldump --user ${ANSIBLE_MYSQL_BACKUP_USER} --password ${ANSIBLE_MYSQL_BACKUP_PASSWORD} --all-databases --single-transaction --skip-lock-tables --quick --default-character-set=utf8mb4 > $BACKUP_FILE

OLDDATE=$(date --date "5 days ago" +%Y%m%d)
rm -f $BACKUP_DIR/${OLDDATE}_*.sql
