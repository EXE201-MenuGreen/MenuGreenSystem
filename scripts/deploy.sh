#!/bin/bash
# =============================================================================
# MenuGreen System - Deployment Script
# =============================================================================
# Usage: ./deploy.sh [environment]
# Environments: staging, production
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Default values
ENVIRONMENT="${1:-production}"
APP_DIR="/home/ubuntu/apps/MenuGreenSystem"
LOG_DIR="/home/ubuntu/logs"
BACKUP_DIR="/home/ubuntu/backups"

# =============================================================================
# Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# Pre-deployment checks
# =============================================================================

log_info "Starting deployment to ${ENVIRONMENT}..."

# Check if running as ubuntu user
if [[ "$USER" != "ubuntu" ]]; then
    log_warning "Running as $USER, but recommended to run as ubuntu user"
fi

# Create directories
mkdir -p "$APP_DIR" "$LOG_DIR" "$BACKUP_DIR"

# =============================================================================
# Load environment variables
# =============================================================================

ENV_FILE="$APP_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    log_error "Environment file not found: $ENV_FILE"
    log_info "Please create .env file with required variables"
    exit 1
fi

# Export variables from .env file
set -a
source "$ENV_FILE"
set +a

# =============================================================================
# Database backup (production only)
# =============================================================================

if [[ "$ENVIRONMENT" == "production" ]]; then
    log_info "Creating database backup..."
    BACKUP_FILE="$BACKUP_DIR/menugreen_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    PGPASSWORD="$DB_PASSWORD" pg_dump \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        --no-acl \
        --no-owner \
        -F p \
        -f "$BACKUP_FILE" \
        || log_warning "Database backup failed, continuing anyway..."
    
    if [[ -f "$BACKUP_FILE" ]]; then
        log_success "Database backup created: $BACKUP_FILE"
        
        # Keep only last 7 backups
        ls -t "$BACKUP_DIR"/menugreen_backup_*.sql | tail -n +8 | xargs rm -f 2>/dev/null || true
    fi
fi

# =============================================================================
# Git pull latest code
# =============================================================================

log_info "Pulling latest code..."
cd "$APP_DIR"
git fetch origin
git pull origin main || git pull origin Tuan

# =============================================================================
# Login to GHCR
# =============================================================================

log_info "Logging in to GHCR..."
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin

# =============================================================================
# Pull latest Docker image
# =============================================================================

IMAGE_NAME="ghcr.io/${GITHUB_REPOSITORY,,}/menugreen-api"

log_info "Pulling latest image: $IMAGE_NAME"
docker pull "$IMAGE_NAME:latest" || log_warning "Could not pull image, building locally..."

# =============================================================================
# Stop existing container
# =============================================================================

log_info "Stopping existing containers..."

# Stop main API
docker stop menugreen-api 2>/dev/null || true
docker rm menugreen-api 2>/dev/null || true

# Stop monitoring stack
docker compose -f "$APP_DIR/docker-compose.monitoring.yml" down 2>/dev/null || true

# =============================================================================
# Run database migration
# =============================================================================

log_info "Running database migrations..."

docker run --rm \
    --env-file "$ENV_FILE" \
    -w /src \
    "$IMAGE_NAME:latest" \
    dotnet ef database update \
    --project backend/MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj \
    --startup-project backend/MenuGreen.API/MenuGreen.API.csproj \
    --no-build \
    || log_warning "Migration may have already been applied"

# =============================================================================
# Start main application
# =============================================================================

log_info "Starting MenuGreen API..."

docker run -d \
    --name menugreen-api \
    --restart unless-stopped \
    --env-file "$ENV_FILE" \
    -p 5000:5000 \
    -v "$APP_DIR/logs:/app/logs" \
    "$IMAGE_NAME:latest"

# =============================================================================
# Wait for API to be healthy
# =============================================================================

log_info "Waiting for API to be healthy..."
API_HEALTHY=false

for i in {1..30}; do
    if curl -sf "http://localhost:5000/health" > /dev/null 2>&1; then
        API_HEALTHY=true
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

if [[ "$API_HEALTHY" == "true" ]]; then
    log_success "API is healthy!"
else
    log_error "API health check failed!"
    log_info "Checking container logs..."
    docker logs menugreen-api --tail 50
    exit 1
fi

# =============================================================================
# Start monitoring stack
# =============================================================================

log_info "Starting monitoring stack..."

if [[ -f "$APP_DIR/docker-compose.monitoring.yml" ]]; then
    docker compose -f "$APP_DIR/docker-compose.monitoring.yml" up -d
    log_success "Monitoring stack started!"
else
    log_warning "Monitoring compose file not found, skipping..."
fi

# =============================================================================
# Cleanup
# =============================================================================

log_info "Cleaning up unused Docker resources..."
docker system prune -f --filter "until=24h" 2>/dev/null || true

# =============================================================================
# Final status
# =============================================================================

log_success "=============================================="
log_success "Deployment completed successfully!"
log_success "=============================================="
echo ""
echo "  API:          http://localhost:5000"
echo "  Swagger:      http://localhost:5000/swagger"
echo "  Grafana:     http://localhost:3000"
echo "  Prometheus:  http://localhost:9090"
echo "  cAdvisor:    http://localhost:8080"
echo ""

# Show container status
docker ps --filter "name=menugreen" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
