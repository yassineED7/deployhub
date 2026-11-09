#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Error: No version tag provided!"
    echo "Usage: ./scripts/rollback.sh <version_tag>"
    echo "Example: ./scripts/rollback.sh v1.1.0"
    exit 1
fi

TARGET_VERSION="$1"

echo "========================================"
echo "Rolling back DeployHub to version: $TARGET_VERSION"
echo "========================================"

export API_IMAGE_TAG="$TARGET_VERSION"

echo "Re-deploying containers with tag $TARGET_VERSION..."
docker compose down
API_IMAGE_TAG="$TARGET_VERSION" docker compose up -d --remove-orphans

echo "========================================"
echo "Rollback completed successfully to $TARGET_VERSION!"
echo "========================================"

if [ -f "./scripts/health-check.sh" ]; then
    echo "Running post-rollback health check..."
    ./scripts/health-check.sh
fi
