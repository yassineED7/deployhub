#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

IMAGE_NAME="yassineed/deployhub-api:latest"
PREVIOUS_TAG="yassineed/deployhub-api:previous"
HEALTH_URL="${HEALTH_URL:-https://localhost/health}"
MAX_RETRIES=15
RETRY_INTERVAL=2

echo -e "${YELLOW}=== DeployHub Zero-Downtime Rollout ===${NC}"

echo -e "${YELLOW}[1/5] Tagging current image for rollback safety...${NC}"
if docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    docker tag "$IMAGE_NAME" "$PREVIOUS_TAG"
    echo "Saved rollback image: $PREVIOUS_TAG"
else
    echo "No existing local image found to tag; skipping."
fi

echo -e "${YELLOW}[2/5] Pulling latest images...${NC}"
docker compose pull

echo -e "${YELLOW}[3/5] Applying container updates (no full down)...${NC}"
docker compose up -d --remove-orphans

echo -e "${YELLOW}[4/5] Waiting for application health check (${HEALTH_URL})...${NC}"
HEALTHY=false
for ((i=1; i<=MAX_RETRIES; i++)); do
    if curl -kfsS --max-time 3 "$HEALTH_URL" > /dev/null 2>&1; then
        HEALTHY=true
        break
    fi
    echo "Attempt ${i}/${MAX_RETRIES}: service not ready yet, retrying in ${RETRY_INTERVAL}s..."
    sleep "$RETRY_INTERVAL"
done

if [[ "$HEALTHY" != true ]]; then
    echo -e "${RED}[ERROR] Deployment health check failed after $((MAX_RETRIES * RETRY_INTERVAL))s!${NC}"
    docker compose ps
    docker compose logs --tail=30 api
    exit 1
fi

echo -e "${YELLOW}[5/5] Verifying full stack status...${NC}"
if [[ -x "$PROJECT_DIR/scripts/health-check.sh" ]]; then
    "$PROJECT_DIR/scripts/health-check.sh" || true
else
    docker compose ps
fi

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN} SUCCESS: Deployment completed cleanly!  ${NC}"
echo -e "${GREEN}=========================================${NC}"
