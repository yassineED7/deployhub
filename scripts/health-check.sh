#!/usr/bin/env bash
set -euo pipefail

# Global status tracker (0 = healthy, 1 = unhealthy)
STATUS=0

# Terminal Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Check API via Nginx
if curl -f -s http://localhost/health > /dev/null; then
    API_STATE="UP"
else
    API_STATE="DOWN"
    STATUS=1
fi

# 2. Check Postgres container
if docker compose ps db | grep -q "Up\|healthy"; then
    DB_STATE="UP"
else
    DB_STATE="DOWN"
    STATUS=1
fi

# 3. Check Docker daemon / engine
if docker info > /dev/null 2>&1; then
    DOCKER_STATE="RUNNING"
else
    DOCKER_STATE="STOPPED"
    STATUS=1
fi

# 4. Check Nginx container
if docker compose ps nginx | grep -q "Up"; then
    NGINX_STATE="UP"
else
    NGINX_STATE="DOWN"
    STATUS=1
fi

# Metrics Calculation
# Corrected CPU Calculation: 100% - idle%
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}' 2>/dev/null || echo "N/A")
MEM_USAGE=$(free | awk '/Mem:/ {printf("%.0f%%"), $3/$2 * 100}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')

# Final Status evaluation
if [ $STATUS -eq 0 ]; then
    FINAL_STATUS="${GREEN}HEALTHY${NC}"
else
    FINAL_STATUS="${RED}UNHEALTHY${NC}"
fi

# Print the final formatted Dashboard
echo "==============================="
echo "       DEPLOYHUB STATUS        "
echo "==============================="
echo "API        : $API_STATE"
echo "DATABASE   : $DB_STATE"
echo "DOCKER     : $DOCKER_STATE"
echo "NGINX      : $NGINX_STATE"
echo ""
echo "CPU        : $CPU_USAGE"
echo "MEMORY     : $MEM_USAGE"
echo "DISK       : $DISK_USAGE"
echo ""
echo -e "STATUS     : $FINAL_STATUS"
echo "==============================="

if [ $STATUS -ne 0 ]; then
    exit 1
fi