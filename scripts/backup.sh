#!/bin/bash

SOURCE_DIR="$HOME/linux-backup-suite/app-data"
BACKUP_DIR="$HOME/linux-backup-suite/backups"
LOG_FILE="$HOME/linux-backup-suite/logs/backup.log"

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/backup_$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date)] Backup started" >> "$LOG_FILE"

tar -czf "$BACKUP_FILE" "$SOURCE_DIR" 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    echo "[$(date)] Backup successful: $BACKUP_FILE" >> "$LOG_FILE"
else
    echo "[$(date)] Backup FAILED" >> "$LOG_FILE"
    exit 1
fi

echo "[$(date)] Backup completed" >> "$LOG_FILE"
