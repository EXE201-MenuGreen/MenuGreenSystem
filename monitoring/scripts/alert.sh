#!/bin/bash
#===============================================================================
# MenuGreen Alert Script - Check System Resources
# 
# Usage: ./alert.sh
# Cron example (every 5 minutes):
# */5 * * * * /opt/menugreen/scripts/alert.sh >> /var/log/menugreen-alert.log 2>&1
#===============================================================================

# Configuration
ALERT_EMAIL="your-email@example.com"
SLACK_WEBHOOK=""  # Optional: Set Slack webhook URL
PUSHBULLET_TOKEN=""  # Optional: Set Pushbullet API token
API_URL="http://localhost:5000/health"
PROMETHEUS_URL="http://localhost:9090"

# Thresholds
CPU_WARNING=70
CPU_CRITICAL=85
MEMORY_WARNING=80
MEMORY_CRITICAL=90
DISK_WARNING=85
DISK_CRITICAL=95

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Send alert via email
send_email_alert() {
    local subject="$1"
    local body="$2"
    
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$body" | mail -s "[MenuGreen] $subject" "$ALERT_EMAIL" 2>/dev/null
        log "Email alert sent to $ALERT_EMAIL"
    fi
}

# Send alert via Slack
send_slack_alert() {
    local title="$1"
    local message="$2"
    local color="$3"
    
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -s -X POST "$SLACK_WEBHOOK" \
            -H 'Content-Type: application/json' \
            -d "{
                \"attachments\": [{
                    \"color\": \"$color\",
                    \"title\": \"$title\",
                    \"text\": \"$message\",
                    \"footer\": \"MenuGreen Alert\",
                    \"ts\": $(date +%s)
                }]
            }" > /dev/null 2>&1
        log "Slack alert sent"
    fi
}

# Send alert via Pushbullet
send_pushbullet_alert() {
    local title="$1"
    local body="$2"
    
    if [ -n "$PUSHBULLET_TOKEN" ]; then
        curl -s -u "$PUSHBULLET_TOKEN:" \
            -d title="$title" \
            -d body="$body" \
            -d type="note" \
            "https://api.pushbullet.com/v2/pushes" > /dev/null 2>&1
        log "Pushbullet alert sent"
    fi
}

# Check if service is running
check_service() {
    local service=$1
    if docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
        return 0
    else
        return 1
    fi
}

# Get CPU usage
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "0"
}

# Get Memory usage
get_memory_usage() {
    free | grep Mem | awk '{printf("%.0f"), ($3/$2) * 100}' 2>/dev/null || echo "0"
}

# Get Disk usage
get_disk_usage() {
    df -h / | awk 'NR==2 {print $5}' | sed 's/%//' 2>/dev/null || echo "0"
}

# Check API health
check_api_health() {
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL" 2>/dev/null)
    echo "$http_code"
}

# Check Prometheus metrics
check_prometheus_metric() {
    local metric="$1"
    local value=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=$metric" 2>/dev/null | \
                  grep -o '"value":\[[0-9]*,[^]]*\]' | \
                  grep -o '[0-9.]*$' | head -1)
    echo "${value:-0}"
}

# Alert functions
alert_warning() {
    local title="$1"
    local message="$2"
    log "${YELLOW}WARNING: $title - $message${NC}"
    send_slack_alert "$title" "$message" "warning"
    send_email_alert "WARNING: $title" "$message"
    send_pushbullet_alert "[WARNING] $title" "$message"
}

alert_critical() {
    local title="$1"
    local message="$2"
    log "${RED}CRITICAL: $title - $message${NC}"
    send_slack_alert "$title" "$message" "danger"
    send_email_alert "CRITICAL: $title" "$message"
    send_pushbullet_alert "[CRITICAL] $title" "$message"
}

alert_recovery() {
    local title="$1"
    local message="$2"
    log "${GREEN}RECOVERED: $title - $message${NC}"
    send_slack_alert "$title" "$message" "good"
    send_pushbullet_alert "[RECOVERED] $title" "$message"
}

#===============================================================================
# MAIN CHECKS
#===============================================================================

log "Starting MenuGreen system check..."

# Track state (create state file if not exists)
STATE_FILE="/tmp/menugreen_alert_state"
touch "$STATE_FILE"

# Initialize state variables
PREV_CPU_STATE=$(grep "cpu_state" "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo "ok")
PREV_MEMORY_STATE=$(grep "memory_state" "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo "ok")
PREV_API_STATE=$(grep "api_state" "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo "ok")
PREV_DISK_STATE=$(grep "disk_state" "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo "ok")

# --- CPU Check ---
CPU_USAGE=$(get_cpu_usage)
log "CPU usage: ${CPU_USAGE}%"

if (( $(echo "$CPU_USAGE > $CPU_CRITICAL" | bc -l) )); then
    if [ "$PREV_CPU_STATE" != "critical" ]; then
        alert_critical "High CPU Usage" "CPU usage is at ${CPU_USAGE}% (threshold: ${CPU_CRITICAL}%)"
        sed -i "s/cpu_state=.*/cpu_state=critical/" "$STATE_FILE"
    fi
elif (( $(echo "$CPU_USAGE > $CPU_WARNING" | bc -l) )); then
    if [ "$PREV_CPU_STATE" = "ok" ]; then
        alert_warning "Elevated CPU Usage" "CPU usage is at ${CPU_USAGE}% (threshold: ${CPU_WARNING}%)"
        sed -i "s/cpu_state=.*/cpu_state=warning/" "$STATE_FILE"
    fi
else
    if [ "$PREV_CPU_STATE" != "ok" ]; then
        alert_recovery "CPU Usage Normal" "CPU usage has returned to ${CPU_USAGE}%"
        sed -i "s/cpu_state=.*/cpu_state=ok/" "$STATE_FILE"
    fi
fi

# --- Memory Check ---
MEMORY_USAGE=$(get_memory_usage)
log "Memory usage: ${MEMORY_USAGE}%"

if [ "$MEMORY_USAGE" -gt "$MEMORY_CRITICAL" ]; then
    if [ "$PREV_MEMORY_STATE" != "critical" ]; then
        alert_critical "High Memory Usage" "Memory usage is at ${MEMORY_USAGE}% (threshold: ${MEMORY_CRITICAL}%)"
        sed -i "s/memory_state=.*/memory_state=critical/" "$STATE_FILE"
    fi
elif [ "$MEMORY_USAGE" -gt "$MEMORY_WARNING" ]; then
    if [ "$PREV_MEMORY_STATE" = "ok" ]; then
        alert_warning "Elevated Memory Usage" "Memory usage is at ${MEMORY_USAGE}% (threshold: ${MEMORY_WARNING}%)"
        sed -i "s/memory_state=.*/memory_state=warning/" "$STATE_FILE"
    fi
else
    if [ "$PREV_MEMORY_STATE" != "ok" ]; then
        alert_recovery "Memory Usage Normal" "Memory usage has returned to ${MEMORY_USAGE}%"
        sed -i "s/memory_state=.*/memory_state=ok/" "$STATE_FILE"
    fi
fi

# --- Disk Check ---
DISK_USAGE=$(get_disk_usage)
log "Disk usage: ${DISK_USAGE}%"

if [ "$DISK_USAGE" -gt "$DISK_CRITICAL" ]; then
    if [ "$PREV_DISK_STATE" != "critical" ]; then
        alert_critical "Low Disk Space" "Disk usage is at ${DISK_USAGE}% (threshold: ${DISK_CRITICAL}%)"
        sed -i "s/disk_state=.*/disk_state=critical/" "$STATE_FILE"
    fi
elif [ "$DISK_USAGE" -gt "$DISK_WARNING" ]; then
    if [ "$PREV_DISK_STATE" = "ok" ]; then
        alert_warning "Elevated Disk Usage" "Disk usage is at ${DISK_USAGE}% (threshold: ${DISK_WARNING}%)"
        sed -i "s/disk_state=.*/disk_state=warning/" "$STATE_FILE"
    fi
else
    if [ "$PREV_DISK_STATE" != "ok" ]; then
        alert_recovery "Disk Space Normal" "Disk usage has returned to ${DISK_USAGE}%"
        sed -i "s/disk_state=.*/disk_state=ok/" "$STATE_FILE"
    fi
fi

# --- API Health Check ---
HTTP_CODE=$(check_api_health)
log "API health check: HTTP $HTTP_CODE"

if [ "$HTTP_CODE" != "200" ]; then
    if [ "$PREV_API_STATE" != "down" ]; then
        alert_critical "API Unavailable" "API returned HTTP $HTTP_CODE (expected: 200)"
        sed -i "s/api_state=.*/api_state=down/" "$STATE_FILE"
    fi
else
    if [ "$PREV_API_STATE" != "ok" ]; then
        alert_recovery "API Available" "API is responding normally"
        sed -i "s/api_state=.*/api_state=ok/" "$STATE_FILE"
    fi
fi

# --- Docker Container Checks ---
for container in menugreen_api menugreen_db menugreen_redis; do
    if ! check_service "$container"; then
        log "${RED}WARNING: Container $container is not running!${NC}"
        alert_critical "Container Down" "Container $container is not running"
    fi
done

# --- Summary ---
log "System check completed."

# Print summary
echo ""
echo "=============================================="
echo "  MenuGreen System Status - $(date '+%Y-%m-%d %H:%M:%S')"
echo "=============================================="
echo "  CPU:     ${CPU_USAGE}%"
echo "  Memory:  ${MEMORY_USAGE}%"
echo "  Disk:    ${DISK_USAGE}%"
echo "  API:     HTTP $HTTP_CODE"
echo "=============================================="
echo ""
