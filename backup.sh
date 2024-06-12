#!/bin/bash

# user=$(whoami)
# input=/root

# seteaza password mysql root 
# sudo mysql
# ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'epDEGu9mbjEmb';
# exit

PWD="/var/www/www-root"
DEST="GDriveEasy4live:Backup/easy4live.com/$(date +%Y-%m-%d)"
LOG_FILE=${PWD}/backup.log
RCLONE_CONFIG=/root/.config/rclone/rclone.conf

OUTPUT=${PWD}/backup_$(date +%Y-%m-%d_%H%M%S).zip

OUTPUT_DATA=${PWD}/backup_data_$(date +%Y-%m-%d_%H%M%S).tar.gz
INPUT_DATA=${PWD}/data

OUTPUT_DB=${PWD}/backup_db_$(date +%Y-%m-%d_%H%M%S).tar.gz
INPUT_DB=${PWD}/mysqldump

DB_PATH=${PWD}/mysqldump/

# ruleaza acesta comanda pentru a seta parola mysql root
# mysqladmin -u root password
DB_PASSWORD=d

if pidof -o %PPID -x `basename "$0"` > /dev/null; then
    echo "$(date "+%d.%m.%Y %T") EXIT: The script is already running." | tee -a "$LOG_FILE"
    exit 1
fi

echo "$(date "+%d.%m.%Y %T") INFO: Start" | tee -a "$LOG_FILE"

mkdir $DB_PATH

for DB in $(mysql -p$DB_PASSWORD -e 'show databases' -s --skip-column-names); do
    mysqldump -u root -p$DB_PASSWORD $DB > "$DB_PATH$DB.sql"
done

# BackUp pentru fisiere
tar -czf $OUTPUT_DATA $INPUT_DATA --checkpoint=.100

# BackUp pentru baza de date
tar -czf $OUTPUT_DB $INPUT_DB --checkpoint=.100

# Creaza o arhiva zip cu parola
# 7z a $OUTPUT $OUTPUT_DATA $OUTPUT_DB -p'Frumos$1906'

# rm $OUTPUT_DATA
# rm $OUTPUT_DB

# muta in cloud
rclone move $OUTPUT_DB $DEST \
    --config=$RCLONE_CONFIG \
    --log-file=$LOG_FILE

rclone move $OUTPUT_DATA $DEST \
    --config=$RCLONE_CONFIG \
    --log-file=$LOG_FILE

rm $DB_PATH -fr

echo "$(date "+%d.%m.%Y %T") INFO: End" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

error="$(grep -rnw $LOG_FILE -e 'ERROR')"
if [ -n "$error" ]; then
    text="Exista%20eroare%20la%20incarcarea%20unui%20backup%20pe%20serverul%20easy4live.com%20Verifica:$LOG_FILE"
    curl 'https://api.telegram.org/bot281876584:AAG-s8Mhz2QK94Sd1xFwvbphKdq1UTCbP84/sendMessage?chat_id=263477274&text='$text
fi
