#!/bin/bash
# =============================================================================
# MenuGreen System - Health Check Script
# =============================================================================
# Usage: ./health-check.sh
# Cron: */5 * * * * /home/ubuntu/apps/MenuGreenSystem/monitoring/scripts/health-check.sh >> /home/ubuntu/logs/health-check.log 2>&1
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

readonly API_URL="${API_URL:-http://localhost:5000}"
readonly API_URL_HTTPS="${API_URL_HTTPS:-https://localhost}"
readonly REDIS_HOST="${REDIS_HOST:-localhost}"
readonly REDIS_PORT="${REDIS_PORT:-6379}"
readonly REDIS_PASSWORD="${REDIS_PASSWORD:-}"
readonly LOG_DIR="${LOG_DIR:-/home/ubuntu/logs}"
readonly LOG_FILE="$LOG_DIR/health-check.log"

# Alert settings
readonly ALERT_EMAIL="${ALERT_EMAIL:-}"
readonly SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
readonly PAGERDUTY_KEY="${PAGERDUTY_KEY:-}"

# Thresholds
readonly CPU_THRESHOLD=80
readonly MEMORY_THRESHOLD=85
readonly DISK_THRESHOLD=85

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Counters
FAILED_CHECKS=0
TOTAL_CHECKS=0

# =============================================================================
# Logging Functions
# =============================================================================

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$1"
}

log_warn() {
    log "${YELLOW}WARN${NC}" "$1"
}

log_error() {
    log "${RED}ERROR${NC}" "$1"
}

log_success() {
    log "${GREEN}OK${NC}" "$1"
}

# =============================================================================
# Alert Functions
# =============================================================================

send_alert() {
    local subject="$1"
    local message="$2"
    local severity="${3:-warning}"

    log_warn "Sending alert: $subject"

    # Slack notification
    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        local color
        case "$severity" in
            critical) color="#FF0000" ;;
            warning) color="#FFA500" ;;
            info) color="#36A64F" ;;
            *) color="#36A64F" ;;
        esac

        curl -s -X POST "$SLACK_WEBHOOK_URL" \
            -H 'Content-Type: application/json' \
            -d "{
                \"attachments\": [{
                    \"color\": \"$color\",
                    \"title\": \"$subject\",
                    \"text\": \"$message\",
                    \"footer\": \"MenuGreen Health Check\",
                    \"ts\": $(date +%s)
                }]
            }" 2>/dev/null || true
    fi

    # Email notification
    if [[ -n "$ALERT_EMAIL" ]]; then
        echo -e "Subject: $subject\n\n$message" | sendmail "$ALERT_EMAIL" 2>/dev/null || true
    fi

    # PagerDuty
    if [[ -n "$PAGERDUTY_KEY" ]]; then
        curl -s -X POST "https://events.pagerduty.com/v2/enqueue" \
            -H 'Content-Type: application/json' \
            -d "{
                \"routing_key\": \"$PAGERDUTY_KEY\",
                \"event_action\": \"trigger\",
                \"dedup_key\": \"menugreen-$(date +%s)\",
                \"payload\": {
                    \"summary\": \"$subject\",
                    \"source\": \"menugreen-health-check\",
                    \"severity\": \"$severity\"
                }
            }" 2>/dev/null || true
    fi
}

# =============================================================================
# Check Functions
# =============================================================================

check_api_http() {
    local url="$1"
    local name="$2"
    local expected_status="${3:-200}"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")

    if [[ "$response" == "$expected_status" ]]; then
        log_success "$name: HTTP $response"
        return 0
    else
        log_error "$name: Expected $expected_status, got $response"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_api_json() {
    local url="$1"
    local name="$2"
    local expected_key="${3:-status}"
    local expected_value="${4:-ok}"

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local response
    response=$(curl -s --max-time 10 "$url" 2>/dev/null || echo "{}")

    local actual_value
    actual_value=$(echo "$response" | grep -o "\"$expected_key\":\"[^\"]*\"" | cut -d'"' -f4 || echo "")

    if [[ "$actual_value" == "$expected_value" ]]; then
        log_success "$name: $expected_key=$actual_value"
        return 0
    else
        log_error "$name: Expected $expected_key=$expected_value, got $actual_value"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_redis() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local redis_cmd="PING"
    if [[ -n "$REDIS_PASSWORD" ]]; then
        redis_cmd="AUTH $REDIS_PASSWORD PING"
    fi

    local response
    response=$(echo "$redis_cmd" | timeout 5 nc -q 2 "$REDIS_HOST" "$REDIS_PORT" 2>/dev/null | tr -d '\r\n' || echo "")

    if [[ "$response" == "PONG" ]]; then
        log_success "Redis: PONG"
        return 0
    else
        log_error "Redis: Connection failed or unexpected response"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_disk_space() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local disk_usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

    if [[ "$disk_usage" -lt "$DISK_THRESHOLD" ]]; then
        log_success "Disk: ${disk_usage}% used"
        return 0
    else
        log_error "Disk: ${disk_usage}% used (threshold: $DISK_THRESHOLD%)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        send_alert "Disk Space Warning" "Disk usage is at ${disk_usage}%" "warning"
        return 1
    fi
}

check_memory() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local mem_usage
    mem_usage=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')

    if [[ "$mem_usage" -lt "$MEMORY_THRESHOLD" ]]; then
        log_success "Memory: ${mem_usage}% used"
        return 0
    else
        log_error "Memory: ${mem_usage}% used (threshold: $MEMORY_THRESHOLD%)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        send_alert "Memory Warning" "Memory usage is at ${mem_usage}%" "warning"
        return 1
    fi
}

check_cpu() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0")

    if [[ "$cpu_usage" -lt "$CPU_THRESHOLD" ]]; then
        log_success "CPU: ${cpu_usage}% used"
        return 0
    else
        log_error "CPU: ${cpu_usage}% used (threshold: $CPU_THRESHOLD%)"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        send_alert "CPU Warning" "CPU usage is at ${cpu_usage}%" "warning"
        return 1
    fi
}

check_docker_containers() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    local running_containers
    running_containers=$(docker ps --format "{{.Names}}" 2>/dev/null | wc -l)

    if [[ "$running_containers" -gt 0 ]]; then
        log_success "Docker: $running_containers containers running"
        return 0
    else
        log_error "Docker: No containers running"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_database() {
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Check if we can connect to the database
    local pgpassword="${DB_PASSWORD:-}"
    local response
    response=$(PGPASSWORD="$pgpassword" psql -h "${DB_HOST:-localhost}" -p "${DB_PORT:-5432}" -U "${DB_USER:-postgres}" -d "${DB_NAME:-postgres}" -t -c "SELECT 1;" 2>/dev/null | tr -d ' \n')

    if [[ "$response" == "1" ]]; then
        log_success "Database: Connection successful"
        return 0
    else
        log_error "Database: Connection failed"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Create log directory
    mkdir -p "$LOG_DIR"

    log_info "========================================"
    log_info "MenuGreen Health Check - $(date)"
    log_info "========================================"

    # Run checks
    log_info "Running health checks..."

    # API checks
    check_api_http "$API_URL/health" "API Health"
    check_api_http "$API_URL/swagger/index.html" "API Swagger"

    # Docker checks
    check_docker_containers

    # System resource checks
    check_disk_space
    check_memory
    check_cpu

    # External service checks
    check_redis
    check_database

    # =============================================================================
    # Summary
    # =============================================================================

    log_info "========================================"
    log_info "Summary: $TOTAL_CHECKS checks, $FAILED_CHECKS failures"
    log_info "========================================"

    # Send critical alert if too many failures
    if [[ "$FAILED_CHECKS" -gt 3 ]]; then
        send_alert "Critical: Multiple Health Check Failures" \
            "$FAILED_CHECKS out of $TOTAL_CHECKS health checks failed" \
            "critical"
    fi

    # Exit with appropriate code
    if [[ "$FAILED_CHECKS" -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
