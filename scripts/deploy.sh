#!/usr/bin/env bash
set -euo pipefail

# =====================================================
# MenuGreen System - Production Deploy Script
# Target: AWS Lightsail Ubuntu 22.04
# =====================================================

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
echo "[1/6] Checking prerequisites..."

command -v docker >/dev/null 2>&1 || { echo "ERROR: Docker is not installed"; exit 1; }

# -----------------------------------------------------
# 2. Pull latest code
# -----------------------------------------------------
echo ""
echo "[2/6] Pulling latest code..."

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
echo "[3/6] Checking .env file..."

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: .env file not found at $ENV_FILE"
    echo "Please copy .env.production.example to .env and configure it first:"
    echo "  cp $APP_DIR/.env.production.example $ENV_FILE"
    echo "  nano $ENV_FILE"
    exit 1
fi

echo "OK: .env found"

# -----------------------------------------------------
# 4. Create Docker network (idempotent)
# -----------------------------------------------------
echo ""
echo "[4/6] Setting up Docker network..."

docker network create menugreen-net 2>/dev/null || echo "OK: Network already exists"

# -----------------------------------------------------
# 5. Build and start services
# -----------------------------------------------------
echo ""
echo "[5/6] Building and starting services..."

$DOCKER_COMPOSE build --no-cache

# Start DB and Redis first
$DOCKER_COMPOSE up -d db redis

# Wait for DB to be ready
echo "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if $DOCKER_COMPOSE exec -T db pg_isready -U "${POSTGRES_USER:-postgres}" >/dev/null 2>&1; then
        echo "OK: PostgreSQL is ready"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "ERROR: PostgreSQL did not become ready in time"
        exit 1
    fi
    sleep 2
done

# Run database migrations
echo "Running database migrations..."
$DOCKER_COMPOSE exec -T api dotnet ef database update --no-build || \
$DOCKER_COMPOSE exec -T api dotnet ef database update || \
echo "WARNING: EF migration failed. You may need to run migrations manually."

# Start API
$DOCKER_COMPOSE up -d api

# -----------------------------------------------------
# 6. Health check
# -----------------------------------------------------
echo ""
echo "[6/6] Running health check..."

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
    echo "WARNING: API health check did not pass within timeout"
    echo "Check logs: $DOCKER_COMPOSE logs api"
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
echo "  API:      http://$(curl -s ifconfig.me):5000/"
echo "  Health:   http://$(curl -s ifconfig.me):5000/health"
echo ""
echo "Logs: $DOCKER_COMPOSE logs -f"
echo "Stop: $DOCKER_COMPOSE down"
