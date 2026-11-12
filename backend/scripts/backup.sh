#!/bin/sh
# DailySave Automated PostgreSQL Database Backup Script
# Usage: ./backup.sh

set -e

BACKUP_DIR="${BACKUP_DIR:-/var/backups/dailysave}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="${BACKUP_DIR}/dailysave_db_${TIMESTAMP}.sql.gz"

mkdir -p "${BACKUP_DIR}"

echo "[DailySave Backup]: Starting backup at $(date)..."

# Dump and gzip compress
PGPASSWORD="${DB_PASSWORD}" pg_dump \
  -h "${DB_HOST:-localhost}" \
  -p "${DB_PORT:-5432}" \
  -U "${DB_USER:-postgres}" \
  -d "${DB_NAME:-dailysave_db}" \
  --format=plain \
  --no-owner \
  --no-privileges | gzip > "${FILENAME}"

echo "[DailySave Backup]: Backup saved successfully to ${FILENAME}"
echo "[DailySave Backup]: Size: $(du -h "${FILENAME}" | cut -f1)"

# Retain last 14 daily backups
find "${BACKUP_DIR}" -type f -name "dailysave_db_*.sql.gz" -mtime +14 -exec rm {} \;
echo "[DailySave Backup]: Old backups cleaned up (14-day retention)."
