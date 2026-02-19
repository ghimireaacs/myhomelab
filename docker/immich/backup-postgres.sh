#!/bin/bash

BACKUP_DIR="/home/ghost/ghostsilo/90_Backups/Immich/Database"
CONTAINER="immich_postgres"
DB_NAME="immich"
USER="postgres"

mkdir -p "$BACKUP_DIR"

DATE=$(date +"%Y-%m-%d_%H-%M")

echo "[$(date)] Starting Immich DB backup..."

docker exec $CONTAINER pg_dump -U $USER $DB_NAME \
  | gzip > "$BACKUP_DIR/immich_db_$DATE.sql.gz"

if [ $? -eq 0 ]; then
  echo "Backup successful: immich_db_$DATE.sql.gz"
else
  echo "Backup FAILED" >&2
  exit 1
fi

# Keep 21 days
find "$BACKUP_DIR" -type f -mtime +21 -delete
