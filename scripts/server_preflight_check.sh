#!/bin/bash
set -euo pipefail

log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $*"; }

APP_DIR="/home/ubuntu/apps/MenuGreenSystem"

log_info "Starting server preflight check..."

# 1. OS check
if [ -f /etc/os-release ]; then
  . /etc/os-release
  log_info "OS: $NAME $VERSION"
  if [[ "$ID" != "ubuntu" ]]; then
    log_warning "This script assumes Ubuntu. Current OS: $ID"
  fi
else
  log_warning "Cannot detect OS. /etc/os-release not found."
fi

# 2. CPU/RAM/Disk
log_info "CPU cores: $(nproc)"
log_info "RAM: $(free -h | awk '/^Mem:/ {print $2}')"
log_info "Disk: $(df -h / | awk 'NR==2 {print $4}') available"

# 3. Docker
if command -v docker &> /dev/null; then
  log_info "Docker: $(docker --version)"
else
  log_error "Docker is not installed"
fi

# 4. Docker Compose plugin
if docker compose version &> /dev/null; then
  log_info "Docker Compose: $(docker compose version --short)"
else
  log_error "Docker Compose plugin is not installed"
fi

# 5. Docker daemon
if docker info &> /dev/null; then
  log_info "Docker daemon is running"
else
  log_error "Docker daemon is not running or user lacks permission"
fi

# 6. User in docker group
if groups | grep -q docker; then
  log_info "User '$(whoami)' is in 'docker' group"
else
  log_warning "User '$(whoami)' is NOT in 'docker' group. You may need sudo for docker commands."
fi

# 7. Docker network
if docker network inspect menugreen-net &> /dev/null; then
  log_info "Docker network 'menugreen-net' exists"
else
  log_warning "Docker network 'menugreen-net' does not exist. Create it with: docker network create menugreen-net"
fi

# 8. App directory, .env, git repo
if [ -d "$APP_DIR" ]; then
  log_info "App directory exists: $APP_DIR"
  if [ -f "$APP_DIR/.env" ]; then
    log_info ".env file exists"
  else
    log_warning ".env file not found at $APP_DIR/.env"
  fi
  if [ -d "$APP_DIR/.git" ]; then
    log_info "Git repo exists in $APP_DIR"
  else
    log_warning "No git repo found at $APP_DIR"
  fi
else
  log_warning "App directory does not exist: $APP_DIR"
fi

# 9. Outbound to RDS
RDS_HOST="${RDS_HOST:-}"
if [ -n "$RDS_HOST" ]; then
  log_info "Testing outbound TCP to RDS host: $RDS_HOST:5432"
  if command -v nc &> /dev/null; then
    if nc -zv -w 3 "$RDS_HOST" 5432 &> /dev/null; then
      log_info "Outbound TCP to RDS is reachable"
    else
      log_error "Outbound TCP to RDS is NOT reachable"
    fi
  else
    log_warning "nc not installed; cannot test TCP connectivity"
  fi
else
  log_warning "RDS_HOST is not set; skipping TCP test"
fi

# 10. SSH authorized_keys for GitHub Actions
if [ -d "$HOME/.ssh" ]; then
  if [ -f "$HOME/.ssh/authorized_keys" ]; then
    KEY_COUNT=$(grep -c . "$HOME/.ssh/authorized_keys" || true)
    log_info "authorized_keys exists with $KEY_COUNT entries"
  else
    log_warning "authorized_keys not found. Add GitHub Actions public key for CI deploy."
  fi
else
  log_warning ".ssh directory not found. Create it with: mkdir -p ~/.ssh && chmod 700 ~/.ssh"
fi

log_info "Preflight check complete."
