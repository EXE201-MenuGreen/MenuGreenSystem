# MenuGreen Nginx - Deployment Scripts

Nginx chạy trực tiếp trên host (không Docker) để tiết kiệm RAM trên server 2GB.

> **Last updated:** 2026-07-11 — Workflow hiện tại đã tự động hóa hoàn toàn qua CI/CD. Các script trong folder này chỉ dùng cho **manual fallback** khi cần debug.

---

## Tại sao nginx không chạy trong Docker?

- Server chỉ có 2GB RAM
- API container: ~800MB | Redis: ~256MB | OS: ~700MB
- Còn ~240MB, đủ cho nginx trên host

---

## Cấu trúc folder

```
backend/nginx/
├── nginx.conf                     # Main config (include các file dưới)
├── conf.d/
│   └── cors-map.conf              # Whitelist CORS origins
└── deploy/                        # Folder này (scripts + docs)
    ├── setup-server.sh            # Cài nginx lần đầu (chạy 1 lần)
    ├── deploy-nginx.sh            # Apply config mới từ git (manual)
    ├── INTEGRATION.md             # Tài liệu tích hợp với CI/CD
    └── README.md                  # File này
```

---

## Workflow hiện tại (2026-07-11) — TỰ ĐỘNG qua CI/CD

### Khi sửa `cors-map.conf` hoặc `nginx.conf`:

```bash
# 1. Sửa file trên local
code backend/nginx/conf.d/cors-map.conf

# 2. Commit + push
git add backend/nginx/
git commit -m "feat(nginx): add staging domain to CORS"
git push origin main
```

**CI/CD sẽ TỰ ĐỘNG:**
1. SCP file nginx lên server
2. Backup config hiện tại (timestamped)
3. Apply config mới
4. Test syntax (`nginx -t`) → rollback nếu fail
5. Reload nginx (zero downtime)

**Không cần SSH lên server.** Không cần chạy script thủ công.

Chi tiết workflow: xem [`INTEGRATION.md`](./INTEGRATION.md) và [`../../docs/01-deployment/CI_CD.md`](../../docs/01-deployment/CI_CD.md).

---

## Manual fallback (chỉ dùng khi cần debug)

### Setup nginx lần đầu (chạy 1 lần duy nhất trên server mới)

```bash
ssh ubuntu@52.77.218.100

# Cài nginx + certbot
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
sudo mkdir -p /etc/nginx/snippets

# Apply config lần đầu
cd ~/apps/MenuGreenSystem
sudo ./backend/nginx/deploy/setup-server.sh
```

### Apply config mới (manual, không qua CI/CD)

Dùng khi:
- CD workflow fail
- Cần test nhanh không muốn đợi CI/CD
- Debug trên server trực tiếp

```bash
ssh ubuntu@52.77.218.100
cd ~/apps/MenuGreenSystem
git pull origin main
sudo ./backend/nginx/deploy/deploy-nginx.sh
```

Script sẽ tự động:
1. Backup config hiện tại (timestamped)
2. Copy file mới vào `/etc/nginx/`
3. Test syntax (`nginx -t`) → rollback nếu fail
4. Reload nginx (zero downtime)
5. Cleanup backup cũ (giữ 10 file mới nhất)

### Rollback khi lỗi

**Cách 1: Restore từ backup có sẵn**

```bash
ssh ubuntu@52.77.218.100
ls -la /etc/nginx/conf.d/cors-map.conf.bak.*
# Chọn backup muốn restore, ví dụ:
sudo cp /etc/nginx/conf.d/cors-map.conf.bak.20260711_143000 \
        /etc/nginx/conf.d/cors-map.conf
sudo nginx -t && sudo systemctl reload nginx
```

**Cách 2: Rollback về version cũ trong git**

```bash
ssh ubuntu@52.77.218.100
cd ~/apps/MenuGreenSystem
git log --oneline backend/nginx/
git checkout <commit-hash-cũ> -- backend/nginx/
sudo ./backend/nginx/deploy/deploy-nginx.sh
```

---

## Verify sau khi deploy

```bash
# Test CORS preflight
curl -I -X OPTIONS https://api.menugreen.food/api/Auth/login \
  -H "Origin: https://www.menugreen.food" \
  -H "Access-Control-Request-Method: POST"

# Test health check
curl https://api.menugreen.food/health/live

# Xem logs nginx (real-time)
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## Các lệnh hay dùng

```bash
sudo nginx -t                 # Test config không reload
sudo systemctl reload nginx  # Reload nginx (zero downtime)
sudo systemctl restart nginx # Restart nginx (downtime ngắn)
sudo systemctl status nginx  # Xem status
sudo cat /etc/nginx/conf.d/cors-map.conf  # Xem config hiện tại
```

---

## Related docs

- [`INTEGRATION.md`](./INTEGRATION.md) — Cách CI/CD workflow apply Nginx tự động
- [`../../docs/01-deployment/CI_CD.md`](../../docs/01-deployment/CI_CD.md) — CI/CD pipeline chi tiết
- [`../../docs/01-deployment/NGINX_AND_CORS.md`](../../docs/01-deployment/NGINX_AND_CORS.md) — CORS config + Nginx architecture