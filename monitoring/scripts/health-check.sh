#!/bin/bash
# =====================================================
# MenuGreen System - Health Check Script
# =====================================================
# Usage: ./health-check.sh
# Cron: */5 * * * * /home/ubuntu/apps/MenuGreenSystem/monitoring/scripts/health-check.sh >> /home/ubuntu/logs/health-check.log 2>&1
# =====================================================

set -euo pipefail

# Configuration
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

# =====================================================
# Logging Functions
# =====================================================

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

# =====================================================
# Alert Functions
# =====================================================

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
            warning)  color="#FFA500" ;;
            *)        color="#36A64F" ;;
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
            }" || log_error "Failed to send Slack alert"
    fi

    # Email notification
    if [[ -n "$ALERT_EMAIL" ]]; then
        echo -e "$message" | mail -s "[$severity] $subject" "$ALERT_EMAIL" 2>/dev/null || \
            log_error "Failed to send email alert"
    fi
}

# =====================================================
# Health Check Functions
# =====================================================

check_api_health() {
    ((TOTAL_CHECKS++))
    log_info "Checking API health..."

    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$API_URL/health" 2>/dev/null || echo "000")

    if [[ "$http_code" == "200" ]]; then
        log_success "API is healthy (HTTP $http_code)"
        return 0
    else
        log_error "API is unhealthy (HTTP $http_code)"
        ((FAILED_CHECKS++))
        send_alert "API Down" "API health check failed with HTTP code: $http_code" "critical"
        return 1
    fi
}

check_redis() {
    ((TOTAL_CHECKS++))
    log_info "Checking Redis..."

    # Method 1: Use netcat/nc if available
    if command -v nc &> /dev/null; then
        local response
        response=$(echo "PING" | nc -w 5 "$REDIS_HOST" "$REDIS_PORT" 2>/dev/null || echo "")
        if [[ "$response" == "+PONG" ]]; then
            log_success "Redis is healthy (PONG)"
            return 0
        fi
    fi

    # Method 2: Use docker exec with redis-cli
    if command -v docker &> /dev/null; then
        local redis_cmd="redis-cli -h $REDIS_HOST -p $REDIS_PORT"
        if [[ -n "$REDIS_PASSWORD" ]]; then
            redis_cmd="$redis_cmd -a $REDIS_PASSWORD"
        fi
        
        if docker exec menugreen_redis sh -c "$redis_cmd ping 2>/dev/null" 2>/dev/null | grep -q PONG; then
            log_success "Redis is healthy (PONG)"
            return 0
        fi
    fi

    # Method 3: Test TCP connection
    if command -v nc &> /dev/null; then
        if nc -z -w 5 "$REDIS_HOST" "$REDIS_PORT" 2>/dev/null; then
            log_success "Redis port is open"
            return 0
        fi
    fi

    log_error "Redis is unhealthy"
    ((FAILED_CHECKS++))
    send_alert "Redis Down" "Redis health check failed on $REDIS_HOST:$REDIS_PORT" "critical"
    return 1
}

check_docker_containers() {
    ((TOTAL_CHECKS++))
    log_info "Checking Docker containers..."

    local running_containers
    running_containers=$(docker ps --filter "name=menugreen" --format "{{.Names}}" 2>/dev/null || echo "")

    if [[ -z "$running_containers" ]]; then
        log_error "No MenuGreen containers are running"
        ((FAILED_CHECKS++))
        send_alert "No Containers Running" "All MenuGreen containers have stopped" "critical"
        return 1
    fi

    # Check for unhealthy containers
    local unhealthy
    unhealthy=$(docker ps --filter "health=unhealthy" --format "{{.Names}}" 2>/dev/null | grep menugreen || echo "")

    if [[ -n "$unhealthy" ]]; then
        log_error "Unhealthy containers: $unhealthy"
        ((FAILED_CHECKS++))
        send_alert "Unhealthy Containers" "Containers in unhealthy state: $unhealthy" "warning"
        return 1
    fi

    log_success "All containers are healthy: $running_containers"
    return 0
}

check_disk_space() {
    ((TOTAL_CHECKS++))
    log_info "Checking disk space..."

    local usage
    usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')

    if [[ "$usage" -lt "$DISK_THRESHOLD" ]]; then
        log_success "Disk usage: ${usage}% (OK)"
        return 0
    else
        log_error "Disk usage is high: ${usage}% (threshold: ${DISK_THRESHOLD}%)"
        ((FAILED_CHECKS++))
        send_alert "Low Disk Space" "Disk usage is at ${usage}% (threshold: ${DISK_THRESHOLD}%)" "warning"
        return 1
    fi
}

check_memory() {
    ((TOTAL_CHECKS++))
    log_info "Checking memory..."

    local total used available percentage
    read -r total used available <<< $(free -m | grep Mem | awk '{print $2, $3, $7}')
    
    if [[ -z "$total" ]]; then
        log_error "Failed to read memory info"
        return 1
    fi

    percentage=$((used * 100 / total))

    if [[ "$percentage" -lt "$MEMORY_THRESHOLD" ]]; then
        log_success "Memory usage: ${percentage}% (${used}/${total} MB) (OK)"
        return 0
    else
        log_warn "Memory usage is high: ${percentage}% (${used}/${total} MB) (threshold: ${MEMORY_THRESHOLD}%)"
        ((FAILED_CHECKS++))
        send_alert "High Memory Usage" "Memory usage is at ${percentage}% (threshold: ${MEMORY_THRESHOLD}%)" "warning"
        return 1
    fi
}

check_cpu() {
    ((TOTAL_CHECKS++))
    log_info "Checking CPU..."

    # Get CPU usage over 1 second
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    if [[ -z "$cpu_usage" ]]; then
        log_error "Failed to read CPU info"
        return 1
    fi

    cpu_usage=${cpu_usage%.*}

    if [[ "$cpu_usage" -lt "$CPU_THRESHOLD" ]]; then
        log_success "CPU usage: ${cpu_usage}% (OK)"
        return 0
    else
        log_warn "CPU usage is high: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
        ((FAILED_CHECKS++))
        send_alert "High CPU Usage" "CPU usage is at ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)" "warning"
        return 1
    fi
}

check_database() {
    ((TOTAL_CHECKS++))
    log_info "Checking database connection..."

    # Check if PostgreSQL port is accessible
    if command -v nc &> /dev/null; then
        if nc -z -w 5 "${DB_HOST:-localhost}" "${DB_PORT:-5432}" 2>/dev/null; then
            log_success "Database port is accessible"
            return 0
        fi
    fi

    log_error "Cannot connect to database"
    ((FAILED_CHECKS++))
    send_alert "Database Connection Failed" "Cannot connect to PostgreSQL at ${DB_HOST:-localhost}:${DB_PORT:-5432}" "warning"
    return 1
}

check_network() {
    ((TOTAL_CHECKS++))
    log_info "Checking network connectivity..."

    if curl -s --max-time 5 https://www.google.com > /dev/null 2>&1; then
        log_success "Network connectivity OK"
        return 0
    else
        log_warn "Limited network connectivity"
        return 0  # Not critical, don't fail
    fi
}

check_uptime() {
    log_info "System uptime: $(uptime -p 2>/dev/null || uptime)"
}

# =====================================================
# Summary
# =====================================================

print_summary() {
    echo ""
    echo "=========================================="
    echo "         HEALTH CHECK SUMMARY"
    echo "=========================================="
    echo " Total checks: $TOTAL_CHECKS"
    echo " Failed:       $FAILED_CHECKS"
    echo " Time:         $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
    
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        log_error "Health check completed with $FAILED_CHECKS failure(s)"
        return 1
    else
        log_success "All checks passed"
        return 0
    fi
}

# =====================================================
# Main
# =====================================================

main() {
    # Ensure log directory exists
    mkdir -p "$LOG_DIR"
    
    # Ensure log file exists
    touch "$LOG_FILE"

    echo ""
    log "${BLUE}==========================================${NC}"
    log "${BLUE}    MenuGreen Health Check$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    log "${BLUE}==========================================${NC}"
    echo ""

    # Run checks
    check_uptime
    check_api_health || true
    check_docker_containers || true
    check_redis || true
    check_database || true
    check_cpu || true
    check_memory || true
    check_disk_space || true
    check_network || true

    # Print summary
    print_summary
    exit_code=$?

    echo ""
    return $exit_code
}

# Run main
main "$@"
