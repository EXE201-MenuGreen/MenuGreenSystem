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

# -----------------------------------------------------
# 1. Check prerequisites
# -----------------------------------------------------
echo ""
echo "[1/6] Checking prerequisites..."

command -v docker >/dev/null 2>&1 || { echo "ERROR: Docker is not installed"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "ERROR: Docker Compose is not installed"; exit 1; }

# -----------------------------------------------------
# 2. Verify .env exists
# -----------------------------------------------------
echo ""
echo "[2/6] Checking .env file..."

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: .env file not found at $ENV_FILE"
    echo "Please copy .env.example to .env and configure it first:"
    echo "  cp $APP_DIR/.env.example $ENV_FILE"
    echo "  nano $ENV_FILE"
    exit 1
fi

echo "OK: .env found"

# -----------------------------------------------------
# 3. Create Docker network (idempotent)
# -----------------------------------------------------
echo ""
echo "[3/6] Setting up Docker network..."

docker network create menugreen-net 2>/dev/null || echo "OK: Network already exists"

# -----------------------------------------------------
# 4. Pull and build images
# -----------------------------------------------------
echo ""
echo "[4/6] Building Docker images..."

cd "$APP_DIR"

docker-compose build --no-cache

# -----------------------------------------------------
# 5. Start services (with database migration)
# -----------------------------------------------------
echo ""
echo "[5/6] Starting services..."

# Start DB and Redis first
docker-compose up -d db redis

# Wait for DB to be ready
echo "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker-compose exec -T db pg_isready -U "${POSTGRES_USER:-postgres}" >/dev/null 2>&1; then
        echo "OK: PostgreSQL is ready"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "ERROR: PostgreSQL did not become ready in time"
        exit 1
    fi
    sleep 2
done

# Run database migrations if dotnet-ef is available
echo "Running database migrations..."
if command -v dotnet >/dev/null 2>&1; then
    cd "$APP_DIR/backend/MenuGreen.API"
    dotnet ef database update --no-build 2>/dev/null || \
    dotnet ef database update 2>/dev/null || \
    echo "WARNING: EF migration failed or not configured. Manual migration may be needed."
    cd "$APP_DIR"
else
    echo "WARNING: dotnet CLI not found. Skipping EF migration."
    echo "Please run migrations manually before deploying, or install dotnet SDK on server."
fi

# Start API and monitoring
docker-compose up -d

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
    if curl -sf http://localhost/health >/dev/null 2>&1; then
        API_HEALTHY=true
        echo "OK: API health check passed"
        break
    fi
    echo "Waiting for API... ($i/$MAX_RETRIES)"
    sleep "$RETRY_INTERVAL"
done

if [ "$API_HEALTHY" = false ]; then
    echo "WARNING: API health check did not pass within timeout"
    echo "Check logs: docker-compose logs api"
fi

# -----------------------------------------------------
# Summary
# -----------------------------------------------------
echo ""
echo "=========================================="
echo "  Deploy Status"
echo "=========================================="
docker-compose ps
echo ""
echo "Access points:"
echo "  API:      http://$(curl -s ifconfig.me)/"
echo "  Health:   http://$(curl -s ifconfig.me)/health"
echo ""
echo "Logs: docker-compose logs -f"
echo "Stop: docker-compose down"
