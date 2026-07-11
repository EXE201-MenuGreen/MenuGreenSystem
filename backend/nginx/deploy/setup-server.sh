#!/bin/bash
# =============================================================
# Setup nginx trên server (chạy 1 LẦN DUY NHẤT)
# Sau khi chạy xong, không cần chạy lại - dùng deploy-nginx.sh
# =============================================================

set -e

NGINX_SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=========================================="
echo "Setup nginx for MenuGreen"
echo "=========================================="
echo "Source: $NGINX_SOURCE_DIR"
echo ""

# 1. Backup config hiện tại của nginx (nếu có)
echo "📦 [1/5] Backing up existing nginx config..."
if [ -f /etc/nginx/nginx.conf ] && [ ! -f /etc/nginx/nginx.conf.original.backup ]; then
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original.backup
    echo "  ✓ Backup saved to /etc/nginx/nginx.conf.original.backup"
else
    echo "  ⊘ No existing nginx.conf or already backed up, skipping"
fi

# 2. Copy main config
echo ""
echo "📋 [2/5] Installing main nginx config..."
sudo cp "$NGINX_SOURCE_DIR/nginx.conf" /etc/nginx/nginx.conf
echo "  ✓ Installed nginx.conf"

# 3. Setup conf.d folder + copy cors-map
echo ""
echo "📋 [3/5] Setting up conf.d/..."
sudo mkdir -p /etc/nginx/conf.d
sudo cp "$NGINX_SOURCE_DIR/conf.d/cors-map.conf" /etc/nginx/conf.d/cors-map.conf
echo "  ✓ Installed cors-map.conf"

# 4. Setup snippets folder
echo ""
echo "📋 [4/5] Setting up snippets/ (empty for now)..."
sudo mkdir -p /etc/nginx/snippets
echo "  ✓ Snippets folder ready"

# 5. Test config + enable nginx
echo ""
echo "🧪 [5/5] Testing config..."
sudo nginx -t

echo ""
echo "🚀 Enabling and starting nginx..."
sudo systemctl enable nginx
sudo systemctl restart nginx

echo ""
echo "=========================================="
echo "✅ Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Setup SSL (Let's Encrypt):"
echo "     sudo apt install -y certbot python3-certbot-nginx"
echo "     sudo certbot --nginx -d api.menugreen.food"
echo ""
echo "  2. Verify nginx is running:"
echo "     sudo systemctl status nginx"
echo ""
echo "  3. Test:"
echo "     curl http://api.menugreen.food/health/live"
echo ""
