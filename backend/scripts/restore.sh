#!/bin/sh
# DailySave Automated PostgreSQL Database Restore Script
# Usage: ./restore.sh /path/to/backup_file.sql.gz

set -e

BACKUP_FILE="$1"

if [ -z "${BACKUP_FILE}" ] || [ ! -f "${BACKUP_FILE}" ]; then
  echo "Error: Please provide a valid backup file (.sql.gz) to restore."
  echo "Usage: ./restore.sh /path/to/backup.sql.gz"
  exit 1
fi

echo "[DailySave Restore]: WARNING - This will restore into database '${DB_NAME:-dailysave_db}'."
echo "[DailySave Restore]: Restoring from ${BACKUP_FILE}..."

gunzip -c "${BACKUP_FILE}" | PGPASSWORD="${DB_PASSWORD}" psql \
  -h "${DB_HOST:-localhost}" \
  -p "${DB_PORT:-5432}" \
  -U "${DB_USER:-postgres}" \
  -d "${DB_NAME:-dailysave_db}"

echo "[DailySave Restore]: Restoration completed successfully at $(date)."
