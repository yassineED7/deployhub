#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status (-e),
# treat unset variables as an error (-u), and ensure pipeline failures are caught (-o pipefail).
set -euo pipefail

# Global status tracker (0 = healthy, 1 = unhealthy)
STATUS=0

echo "=== DeployHub Health Check ==="

# 1. Verify if the API service is reachable and responding with HTTP 200 OK
echo -n "Checking API (/health)... "
if curl -f -s http://localhost:3000/health > /dev/null; then
    echo "[OK]"
else
    echo "[FAILED]"
    STATUS=1
fi

# 2. Check if the PostgreSQL Docker container is running and healthy
echo -n "Checking Postgres Container... "
if docker compose ps postgres | grep -q "Up\|healthy"; then
    echo "[OK]"
else
    echo "[FAILED]"
    STATUS=1
fi

# 3. Monitor disk space usage on root (trigger warning if usage exceeds 85%)
echo -n "Checking Disk Usage... "
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
if [ "$DISK_USAGE" -lt 85 ]; then
    echo "[OK] (${DISK_USAGE}%)"
else
    echo "[WARNING] Disk usage high: ${DISK_USAGE}%"
    STATUS=1
fi

# 4. Monitor RAM consumption (trigger warning if usage exceeds 90%)
echo -n "Checking Memory Usage... "
MEM_USAGE=$(free | awk '/Mem:/ {printf("%.0f"), $3/$2 * 100}')
if [ "$MEM_USAGE" -lt 90 ]; then
    echo "[OK] (${MEM_USAGE}%)"
else
    echo "[WARNING] Memory usage high: ${MEM_USAGE}%"
    STATUS=1
fi

# Summary evaluation and exit status
echo "=============================="
if [ $STATUS -eq 0 ]; then
    echo -e "\033[0;32mSTATUS: HEALTHY\033[0m"
else
    echo -e "\033[0;31mSTATUS: UNHEALTHY\033[0m"
    exit 1
fi
