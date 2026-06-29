#!/usr/bin/env bash
# =============================================================================
# MenuGreen System - Redis Backup Script
# Chạy backup Redis hàng ngày qua cron
# =============================================================================

set -euo pipefail

# === Config ===
CONTAINER_NAME="menugreen_redis"
BACKUP_DIR="/home/ubuntu/backups/redis"
LOG_FILE="/home/ubuntu/logs/redis-backup.log"
REDIS_PASSWORD="${REDIS_PASSWORD:-}"

# === Log function ===
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# === Check prerequisites ===
if [ -z "$REDIS_PASSWORD" ]; then
    log "ERROR: REDIS_PASSWORD not set"
    exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    log "ERROR: Container $CONTAINER_NAME is not running"
    exit 1
fi

# === Ensure backup directory exists ===
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# === Backup ===
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/dump_${DATE}.rdb"

log "Starting Redis backup..."

# Trigger background save và đợi hoàn tất
docker exec "$CONTAINER_NAME" redis-cli -a "$REDIS_PASSWORD" BGSAVE > /dev/null 2>&1

# Đợi file dump được tạo (tối đa 30 giây)
for i in {1..30}; do
    if docker exec "$CONTAINER_NAME" test -f /data/dump.rdb; then
        break
    fi
    sleep 1
done

# Copy file dump
if docker cp "$CONTAINER_NAME":/data/dump.rdb "$BACKUP_FILE"; then
    # Set permissions
    chmod 600 "$BACKUP_FILE"
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log "OK: Redis backup saved to $BACKUP_FILE (size: $SIZE)"
else
    log "ERROR: Failed to copy Redis dump file"
    exit 1
fi

# === Cleanup old backups (giữ lại 7 ngày) ===
DELETED_COUNT=0
while IFS= read -r file; do
    if rm -f "$file"; then
        DELETED_COUNT=$((DELETED_COUNT + 1))
    fi
done < <(find "$BACKUP_DIR" -name "dump_*.rdb" -mtime +7 -type f 2>/dev/null)

if [ "$DELETED_COUNT" -gt 0 ]; then
    log "OK: Deleted $DELETED_COUNT old backup(s) (older than 7 days)"
fi

# === Summary ===
TOTAL_BACKUPS=$(find "$BACKUP_DIR" -name "dump_*.rdb" | wc -l)
log "OK: Total Redis backups: $TOTAL_BACKUPS"

exit 0
