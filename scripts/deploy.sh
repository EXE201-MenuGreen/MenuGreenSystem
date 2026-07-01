#!/usr/bin/env bash
# =============================================================================
# MenuGreen System - Production Deploy Script
# Target: AWS Lightsail Ubuntu 22.04
# Architecture: API + Redis (Docker), PostgreSQL (AWS RDS)
# =============================================================================

set -euo pipefail

echo "=========================================="
echo "  MenuGreen Production Deploy"
echo "=========================================="

# Check running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

APP_DIR="/home/ubuntu/apps/MenuGreenSystem"
ENV_FILE="$APP_DIR/.env"
COMPOSE_FILE="$APP_DIR/docker-compose.prod.yml"
BACKUP_DIR="/home/ubuntu/backups/redis"
LOG_DIR="/home/ubuntu/logs"

# Detect docker compose command (v2: 'docker compose', v1: 'docker-compose')
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose -f $COMPOSE_FILE"
elif command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose -f $COMPOSE_FILE"
else
    echo "ERROR: Docker Compose is not installed"
    exit 1
fi

# -----------------------------------------------------
# 1. Check prerequisites
# -----------------------------------------------------
echo ""
echo "[1/7] Checking prerequisites..."

command -v docker >/dev/null 2>&1 || { echo "ERROR: Docker is not installed"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is not installed"; exit 1; }

echo "OK: Prerequisites checked"

# -----------------------------------------------------
# 2. Pull latest code
# -----------------------------------------------------
echo ""
echo "[2/7] Pulling latest code..."

cd "$APP_DIR"

if [ -d ".git" ]; then
    git fetch origin
    git reset --hard origin/main
    echo "OK: Code updated to latest"
else
    echo "WARNING: Not a git repository. Skipping git pull."
fi

# -----------------------------------------------------
# 3. Verify .env exists
# -----------------------------------------------------
echo ""
echo "[3/7] Checking .env file..."

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: .env file not found at $ENV_FILE"
    echo "Please copy .env.production.example to .env and configure it first:"
    echo "  cp $APP_DIR/.env.production.example $ENV_FILE"
    echo "  nano $ENV_FILE"
    exit 1
fi

# Load .env to check for placeholders
set -a
source "$ENV_FILE"
set +a

# Validate critical env vars
if [ -z "${DB_HOST:-}" ] || [ -z "${DB_PASSWORD:-}" ]; then
    echo "ERROR: DB_HOST or DB_PASSWORD not set in .env"
    exit 1
fi

if [ -z "${REDIS_PASSWORD:-}" ]; then
    echo "ERROR: REDIS_PASSWORD not set in .env"
    exit 1
fi

if grep -q "CHANGE_THIS\|<password>" "$ENV_FILE" 2>/dev/null; then
    echo "ERROR: .env contains placeholder values. Please configure it properly."
    exit 1
fi

echo "OK: .env validated"

# -----------------------------------------------------
# 4. Setup directories
# -----------------------------------------------------
echo ""
echo "[4/7] Setting up directories..."

mkdir -p "$BACKUP_DIR"
mkdir -p "$LOG_DIR"
chown -R ubuntu:ubuntu "$BACKUP_DIR" "$LOG_DIR" 2>/dev/null || true

echo "OK: Directories ready"

# -----------------------------------------------------
# 5. Create Docker network (idempotent)
# -----------------------------------------------------
echo ""
echo "[5/7] Setting up Docker network..."

docker network create menugreen-net 2>/dev/null || echo "OK: Network already exists"

# -----------------------------------------------------
# 6. Build and start services
# -----------------------------------------------------
echo ""
echo "[6/7] Building and starting services..."

# Stop existing containers
$DOCKER_COMPOSE down 2>/dev/null || true

# Build API image
$DOCKER_COMPOSE build --no-cache

# Start Redis first
$DOCKER_COMPOSE up -d redis

# Wait for Redis to be healthy
echo "Waiting for Redis to be healthy..."
REDIS_HEALTHY=false
for i in {1..30}; do
    if $DOCKER_COMPOSE exec -T redis redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q "PONG"; then
        REDIS_HEALTHY=true
        echo "OK: Redis is ready"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "WARNING: Redis did not become healthy in time. Check logs."
    fi
    sleep 2
done

# Run database migrations (connecting to RDS)
echo "Running database migrations..."
MIGRATION_SUCCESS=false
if $DOCKER_COMPOSE run --rm api dotnet ef database update --no-build 2>&1 | tee -a "$LOG_DIR/migration.log"; then
    MIGRATION_SUCCESS=true
    echo "OK: Migrations completed"
elif $DOCKER_COMPOSE run --rm api dotnet ef database update 2>&1 | tee -a "$LOG_DIR/migration.log"; then
    MIGRATION_SUCCESS=true
    echo "OK: Migrations completed"
else
    echo "WARNING: EF migration failed. Check $LOG_DIR/migration.log"
fi

# Start API
$DOCKER_COMPOSE up -d api

# -----------------------------------------------------
# 7. Health check
# -----------------------------------------------------
echo ""
echo "[7/7] Running health check..."

sleep 10

MAX_RETRIES=12
RETRY_INTERVAL=5
API_HEALTHY=false

for i in $(seq 1 $MAX_RETRIES); do
    if curl -sf http://localhost:5000/health >/dev/null 2>&1; then
        API_HEALTHY=true
        echo "OK: API health check passed"
        break
    fi
    echo "Waiting for API... ($i/$MAX_RETRIES)"
    sleep "$RETRY_INTERVAL"
done

if [ "$API_HEALTHY" = false ]; then
    echo ""
    echo "WARNING: API health check did not pass within timeout"
    echo "Check logs: $DOCKER_COMPOSE logs api"
    echo ""
fi

# -----------------------------------------------------
# Summary
# -----------------------------------------------------
echo ""
echo "=========================================="
echo "  Deploy Status"
echo "=========================================="
$DOCKER_COMPOSE ps
echo ""
echo "Access points:"
echo "  API:      http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost'):5000/"
echo "  Health:   http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost'):5000/health"
echo ""
echo "View logs:"
echo "  API:   $DOCKER_COMPOSE logs -f api"
echo "  Redis: $DOCKER_COMPOSE logs -f redis"
echo ""
echo "Deploy complete!"
