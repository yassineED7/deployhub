
#!/usr/bin/env bash
set -Eeuo pipefail

# Always run from the project root
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

BACKUP_DIR="$PROJECT_DIR/backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/deployhub_${TIMESTAMP}.dump"
TEMP_FILE="${BACKUP_FILE}.tmp"

cleanup() {
    rm -f "$TEMP_FILE"
}
trap cleanup EXIT

echo "=== DeployHub PostgreSQL Backup ==="

# Check database container
if ! docker compose ps --status running --services | grep -qx db; then
    echo "[ERROR] Database container is not running."
    exit 1
fi

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

echo "[1/3] Creating database backup..."

if ! docker compose exec -T db sh -c \
    'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' \
    > "$TEMP_FILE"; then
    echo "[ERROR] Database backup failed."
    exit 1
fi

if [[ ! -s "$TEMP_FILE" ]]; then
    echo "[ERROR] Backup file is empty."
    exit 1
fi

echo "[2/3] Validating backup archive..."

if ! docker compose exec -T db pg_restore --list < "$TEMP_FILE" > /dev/null; then
    echo "[ERROR] Backup archive validation failed."
    exit 1
fi

chmod 600 "$TEMP_FILE"
mv "$TEMP_FILE" "$BACKUP_FILE"

echo "[3/3] Backup completed successfully."

echo "Backup: $BACKUP_FILE"
echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)"
echo "Status: SUCCESS"

