#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

STATUS=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Check API via Nginx HTTPS endpoint
if curl -kfsS --max-time 4 https://localhost/health > /dev/null 2>&1; then
    API_STATE="UP"
else
    API_STATE="DOWN"
    STATUS=1
fi

# 2. Check PostgreSQL readiness
if docker compose ps --status running --services | grep -qx db \
    && docker compose exec -T db sh -c 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' > /dev/null 2>&1; then
    DB_STATE="READY"
else
    DB_STATE="DOWN"
    STATUS=1
fi

# 3. Check Docker daemon
if docker info > /dev/null 2>&1; then
    DOCKER_STATE="RUNNING"
else
    DOCKER_STATE="STOPPED"
    STATUS=1
fi

# 4. Check Nginx container
if docker compose ps --status running --services | grep -qx nginx; then
    NGINX_STATE="UP"
else
    NGINX_STATE="DOWN"
    STATUS=1
fi

# 5. Server metrics (CPU via /proc/stat, Memory, Root Disk)
read -r _ u1 n1 s1 i1 w1 irq1 sirq1 st1 _ < /proc/stat
idle1=$((i1 + w1))
total1=$((u1 + n1 + s1 + i1 + w1 + irq1 + sirq1 + st1))
sleep 0.2
read -r _ u2 n2 s2 i2 w2 irq2 sirq2 st2 _ < /proc/stat
idle2=$((i2 + w2))
total2=$((u2 + n2 + s2 + i2 + w2 + irq2 + sirq2 + st2))
diff_total=$((total2 - total1))
diff_idle=$((idle2 - idle1))
if [[ "$diff_total" -gt 0 ]]; then
    CPU_USAGE="$(( (100 * (diff_total - diff_idle)) / diff_total ))%"
else
    CPU_USAGE="N/A"
fi

MEM_USAGE="$(free | awk '/Mem:/ {printf "%.0f%%", ($3 / $2) * 100}')"
DISK_USAGE="$(df -h / | awk 'NR==2 {print $5}')"

if [[ "$STATUS" -eq 0 ]]; then
    FINAL_STATUS="${GREEN}HEALTHY${NC}"
else
    FINAL_STATUS="${RED}UNHEALTHY${NC}"
fi

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

if [[ "$STATUS" -ne 0 ]]; then
    exit 1
fi
