#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status (-e),
# treat unset variables as an error (-u), and ensure pipeline failures are caught (-o pipefail).
set -euo pipefail

# Define backup directory and generate a timestamped filename
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/deployhub_backup_${TIMESTAMP}.sql"

# Create the backup directory if it does not already exist
mkdir -p "$BACKUP_DIR"

echo "=== DeployHub Database Backup ==="
echo "1. Creating PostgreSQL backup..."

# Dump the database from inside the running PostgreSQL container
docker compose exec -T postgres pg_dump -U postgres deployhub > "$BACKUP_FILE"

# Verify that the backup file exists and is not empty
if [ -s "$BACKUP_FILE" ]; then
    echo -e "\033[0;32m[OK] Backup created successfully: ${BACKUP_FILE}\033[0m"
else
    echo -e "\033[0;31m[FAILED] Backup failed or file is empty!\033[0m"
    rm -f "$BACKUP_FILE"
    exit 1
fi

echo "2. Testing backup restoration on temporary database..."

# Create a temporary database to validate the backup file
docker compose exec -T postgres psql -U postgres -c "CREATE DATABASE restore_test;" > /dev/null

# Restore the backup file into the temporary test database
docker compose exec -T postgres psql -U postgres -d restore_test < "$BACKUP_FILE" > /dev/null

# Clean up by dropping the temporary test database after successful validation
docker compose exec -T postgres psql -U postgres -c "DROP DATABASE restore_test;" > /dev/null

echo -e "\033[0;32m[OK] Backup restore test passed successfully!\033[0m"
