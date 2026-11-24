#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

BACKUP_DIR="$PROJECT_DIR/backups"
RETENTION_DAYS=7
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== DeployHub Safe Cleanup ===${NC}"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}[MODE] Dry-run (no files or Docker resources will be removed)${NC}"
fi

echo -e "${YELLOW}[1/3] Cleaning dangling Docker images (<none>)...${NC}"
if [[ "$DRY_RUN" == true ]]; then
    docker image ls --filter "dangling=true"
else
    docker image prune -f
fi

echo -e "${YELLOW}[2/3] Cleaning Docker build cache older than 7 days...${NC}"
if [[ "$DRY_RUN" == true ]]; then
    docker system df || true
else
    docker builder prune --filter "until=168h" -f
fi

echo -e "${YELLOW}[3/3] Cleaning backup files older than ${RETENTION_DAYS} days...${NC}"
if [[ -d "$BACKUP_DIR" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        find "$BACKUP_DIR" -type f \( -name "*.sql" -o -name "*.dump" \) -mtime "+${RETENTION_DAYS}" -print
    else
        find "$BACKUP_DIR" -type f \( -name "*.sql" -o -name "*.dump" \) -mtime "+${RETENTION_DAYS}" -delete
    fi
else
    echo "No backups directory found at $BACKUP_DIR."
fi

echo -e "${GREEN}[OK] Cleanup completed successfully.${NC}"
