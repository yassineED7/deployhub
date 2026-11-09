#!/usr/bin/env bash
set -euo pipefail

# Terminal colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[1/5] Pulling latest images from Docker Hub...${NC}"
docker compose pull

echo -e "${YELLOW}[2/5] Stopping old containers...${NC}"
docker compose down --remove-orphans

echo -e "${YELLOW}[3/5] Starting new containers...${NC}"
docker compose up -d

echo -e "${YELLOW}[4/5] Checking container status...${NC}"
sleep 5
docker compose ps

echo -e "${YELLOW}[5/5] Running health check...${NC}"
if curl -f -s http://localhost/health > /dev/null; then
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN} SUCCESS: Deployment completed successfully!${NC}"
    echo -e "${GREEN}=========================================${NC}"
else
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED} ERROR: Health check failed! Check logs.${NC}"
    echo -e "${RED}=========================================${NC}"
    exit 1
fi