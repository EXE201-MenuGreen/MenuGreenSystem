#!/bin/bash
# =============================================================
# Apply nginx config mới từ git lên server
# Chạy mỗi khi sửa file trong backend/nginx/
#
# Usage:
#   sudo ./deploy-nginx.sh
#
# Workflow (phải làm trước khi chạy script này):
#   1. Sửa file trong backend/nginx/ trên local
#   2. git add . && git commit -m "..." && git push
#   3. Trên server: cd ~/apps/MenuGreenSystem && git pull
#   4. sudo ./backend/nginx/deploy/deploy-nginx.sh
# =============================================================

set -euo pipefail

NGINX_SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Màu sắc cho dễ đọc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $*"; }
log_error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $*"; }

# Check quyền root
if [ "$EUID" -ne 0 ]; then
    log_error "Script cần chạy với sudo!"
    echo "Usage: sudo $0"
    exit 1
fi

log_info "=========================================="
log_info "MenuGreen Nginx Deploy"
log_info "=========================================="
log_info "Source: $NGINX_SOURCE_DIR"
log_info "Timestamp: $TIMESTAMP"
echo ""

# =====================================================
# BƯỚC 1: Verify file nguồn tồn tại
# =====================================================
log_info "[1/5] Verifying source files..."

REQUIRED_FILES=(
    "$NGINX_SOURCE_DIR/nginx.conf"
    "$NGINX_SOURCE_DIR/conf.d/cors-map.conf"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        log_error "Source file không tồn tại: $file"
        exit 1
    fi
    log_info "  ✓ Found: $(basename "$file")"
done

# =====================================================
# BƯỚC 2: Backup config hiện tại
# =====================================================
log_info ""
log_info "[2/5] Backing up current config..."

if [ -f /etc/nginx/conf.d/cors-map.conf ]; then
    sudo cp /etc/nginx/conf.d/cors-map.conf \
            /etc/nginx/conf.d/cors-map.conf.bak.$TIMESTAMP
    log_info "  ✓ Backed up cors-map.conf → .bak.$TIMESTAMP"
fi

if [ -f /etc/nginx/nginx.conf ]; then
    # Backup main config (nếu chưa backup lần đầu)
    if [ ! -f /etc/nginx/nginx.conf.original.backup ]; then
        sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original.backup
        log_info "  ✓ Saved original nginx.conf backup (first time)"
    fi
    sudo cp /etc/nginx/nginx.conf \
            /etc/nginx/nginx.conf.bak.$TIMESTAMP
    log_info "  ✓ Backed up nginx.conf → .bak.$TIMESTAMP"
fi

# =====================================================
# BƯỚC 3: Copy file mới vào /etc/nginx/
# =====================================================
log_info ""
log_info "[3/5] Copying new config..."

sudo cp "$NGINX_SOURCE_DIR/nginx.conf" /etc/nginx/nginx.conf
log_info "  ✓ Copied nginx.conf"

sudo cp "$NGINX_SOURCE_DIR/conf.d/cors-map.conf" /etc/nginx/conf.d/cors-map.conf
log_info "  ✓ Copied cors-map.conf"

# =====================================================
# BƯỚC 4: Test config (QUAN TRỌNG - phải pass trước khi reload)
# =====================================================
log_info ""
log_info "[4/5] Testing config syntax..."

if sudo nginx -t 2>&1 | tee /tmp/nginx-test.log; then
    log_info "  ✓ Config syntax OK"
else
    log_error "Config syntax FAILED - rolling back!"
    log_error ""
    log_error "Test output:"
    cat /tmp/nginx-test.log | sed 's/^/    /'
    log_error ""
    log_warn "Restoring from backup..."

    if [ -f /etc/nginx/conf.d/cors-map.conf.bak.$TIMESTAMP ]; then
        sudo cp /etc/nginx/conf.d/cors-map.conf.bak.$TIMESTAMP \
                /etc/nginx/conf.d/cors-map.conf
    fi

    if [ -f /etc/nginx/nginx.conf.bak.$TIMESTAMP ]; then
        sudo cp /etc/nginx/nginx.conf.bak.$TIMESTAMP \
                /etc/nginx/nginx.conf
    fi

    log_warn "Rolled back. Nginx config unchanged."
    exit 1
fi

# =====================================================
# BƯỚC 5: Reload nginx (zero-downtime)
# =====================================================
log_info ""
log_info "[5/5] Reloading nginx..."

if sudo systemctl reload nginx; then
    log_info "  ✓ Nginx reloaded successfully"
else
    log_error "Failed to reload nginx!"
    exit 1
fi

# =====================================================
# Verify sau khi reload
# =====================================================
sleep 2

# Check nginx đang chạy
if systemctl is-active --quiet nginx; then
    log_info "  ✓ Nginx is running"
else
    log_error "Nginx is not running!"
    exit 1
fi

# Check ports
if ss -tlnp | grep -q ':80 '; then
    log_info "  ✓ Listening on port 80"
else
    log_warn "Not listening on port 80"
fi

# =====================================================
# Cleanup old backups (giữ lại 10 file mới nhất)
# =====================================================
log_info ""
log_info "🧹 Cleaning up old backups (keeping 10 most recent)..."

# Cleanup cors-map backups
ls -t /etc/nginx/conf.d/cors-map.conf.bak.* 2>/dev/null | tail -n +11 | xargs -r rm -f

# Cleanup nginx.conf backups (giữ original.backup)
ls -t /etc/nginx/nginx.conf.bak.* 2>/dev/null | tail -n +11 | xargs -r rm -f

log_info "  ✓ Old backups removed"

# =====================================================
# Done
# =====================================================
echo ""
log_info "=========================================="
log_info "✅ Deploy complete!"
log_info "=========================================="
echo ""
echo "📊 Quick verify:"
echo "   curl -I https://api.menugreen.food/health/live"
echo ""
echo "📜 Backup location:"
echo "   /etc/nginx/conf.d/cors-map.conf.bak.$TIMESTAMP"
echo "   /etc/nginx/nginx.conf.bak.$TIMESTAMP"
echo ""
