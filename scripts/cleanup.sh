#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status (-e),
# treat unset variables as an error (-u), and ensure pipeline failures are caught (-o pipefail).
set -euo pipefail

# ANSI color codes for formatted output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== DeployHub System Cleanup ===${NC}"

# 1. Safely remove unused Docker resources (stopped containers, dangling images, and build cache)
echo -e "${YELLOW}1. Cleaning unused Docker resources (stopped containers, unused images, build cache)...${NC}"
docker system prune -f

# 2. Delete database backup files (.sql) older than 7 days
echo -e "${YELLOW}2. Cleaning backups older than 7 days...${NC}"
find ./backups -type f -name "*.sql" -mtime +7 -delete 2>/dev/null || true

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}[OK] Cleanup completed successfully!${NC}"
echo -e "${GREEN}=========================================${NC}"
