#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

if [[ $# -lt 1 || -z "${1:-}" ]]; then
    echo "Error: No version tag provided!"
    echo "Usage: ./scripts/rollback.sh <version_tag>"
    echo "Example: ./scripts/rollback.sh previous"
    exit 1
fi

TARGET_TAG="$1"
REPO_NAME="yassineed/deployhub-api"
TARGET_IMAGE="${REPO_NAME}:${TARGET_TAG}"
HEALTH_URL="${HEALTH_URL:-https://localhost/health}"
MAX_RETRIES=15
RETRY_INTERVAL=2

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== DeployHub Rollback to ${TARGET_TAG} ===${NC}"

echo -e "${YELLOW}[1/4] Verifying target image (${TARGET_IMAGE})...${NC}"
if ! docker image inspect "$TARGET_IMAGE" > /dev/null 2>&1; then
    echo "Target image not found locally; attempting pull..."
    if ! docker pull "$TARGET_IMAGE"; then
        echo -e "${RED}[ERROR] Image ${TARGET_IMAGE} is not available locally or remotely.${NC}"
        exit 1
    fi
fi

# Keep local :latest aligned with rolled-back tag if needed
docker tag "$TARGET_IMAGE" "${REPO_NAME}:latest"

echo -e "${YELLOW}[2/4] Restarting API service with ${TARGET_IMAGE}...${NC}"
export API_IMAGE_TAG="$TARGET_TAG"
docker compose up -d --no-deps --remove-orphans api

echo -e "${YELLOW}[3/4] Waiting for health check (${HEALTH_URL})...${NC}"
HEALTHY=false
for ((i=1; i<=MAX_RETRIES; i++)); do
    if curl -kfsS --max-time 3 "$HEALTH_URL" > /dev/null 2>&1; then
        HEALTHY=true
        break
    fi
    echo "Attempt ${i}/${MAX_RETRIES}: waiting for service..."
    sleep "$RETRY_INTERVAL"
done

if [[ "$HEALTHY" != true ]]; then
    echo -e "${RED}[ERROR] Rollback health check failed! Inspect logs immediately.${NC}"
    docker compose ps
    docker compose logs --tail=30 api
    exit 1
fi

echo -e "${YELLOW}[4/4] Running post-rollback health check...${NC}"
if [[ -x "$PROJECT_DIR/scripts/health-check.sh" ]]; then
    "$PROJECT_DIR/scripts/health-check.sh"
fi

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN} SUCCESS: Rolled back to ${TARGET_TAG}!   ${NC}"
echo -e "${GREEN}=========================================${NC}"
