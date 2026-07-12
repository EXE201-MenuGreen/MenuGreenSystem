# Nginx + CI/CD Integrated Workflow

> **Last updated:** 2026-07-11 — Workflow mới: Nginx config apply TỰ ĐỘNG qua CD workflow.

---

## Tổng quan

Trước đây: Sửa `backend/nginx/conf.d/cors-map.conf` → push git → **không có gì xảy ra** → phải SSH lên server chạy `deploy-nginx.sh` thủ công.

Bây giờ: Sửa file nginx → push git → **CI/CD tự động apply lên server** (cùng lúc deploy Docker image).

```
git push origin main
        ↓
┌──────────────────────────────────────────────────┐
│  GitHub Actions                                  │
│                                                  │
│  backend-ci.yml                                  │
│   └─ Build + Push Docker image                   │
│                                                  │
│  backend-cd.yml                                  │
│   ├─ 1. SCP file nginx lên server                │
│   ├─ 2. Apply nginx config (auto rollback)       │  ← MỚI
│   ├─ 3. Download Doppler secrets                 │
│   ├─ 4. Backup RDS                               │
│   ├─ 5. Pull + tag Docker image                  │
│   ├─ 6. Restart container                        │
│   ├─ 7. Health check (auto rollback nếu fail)    │
│   └─ 8. Cleanup                                  │
└──────────────────────────────────────────────────┘
```

---

## Những gì đã fix (để CI/CD + Nginx hoạt động cùng nhau)

### Fix 1: `nginx.conf` — Upstream trỏ vào host thay vì Docker DNS

**Trước (SAI):**
```nginx
upstream api_backend {
    server api:5000;    # Docker DNS - chỉ work trong docker network
    keepalive 32;
}
```

Nginx chạy trên HOST, không trong Docker → không resolve được `api`.

**Sau (ĐÚNG):**
```nginx
upstream api_backend {
    server 127.0.0.1:5000;    # API container publish port ra host
    keepalive 32;
}
```

File: `backend/nginx/nginx.conf` line 47-52.

### Fix 2: `backend-cd.yml` — Thêm 2 step mới

**Step mới 1:** SCP file nginx lên server
```yaml
- name: Upload nginx config to server
  uses: appleboy/scp-action@v0.1.7
  with:
    host: ${{ secrets.LIGHTSAIL_HOST }}
    username: ${{ secrets.LIGHTSAIL_USER }}
    key: ${{ secrets.LIGHTSAIL_SSH_KEY }}
    source: "backend/nginx/nginx.conf,backend/nginx/conf.d/cors-map.conf"
    target: "/tmp/nginx-deploy"
```

**Step mới 2:** Apply nginx (TRƯỚC khi restart container)
- Backup config hiện tại (`.bak.YYYYMMDD_HHMMSS`)
- Copy file mới vào `/etc/nginx/`
- Test syntax (`nginx -t`)
- Fail → auto rollback → abort deploy
- Pass → reload nginx (zero downtime)

---

## Deploy Flow chi tiết (sau khi tích hợp)

```bash
# Dev sửa CORS trên local
code backend/nginx/conf.d/cors-map.conf

# Commit + push
git add backend/nginx/
git commit -m "feat(nginx): add staging.menugreen.food to CORS"
git push origin main
```

**GitHub Actions tự động:**

```
backend-ci.yml
  └─ Build image → push Docker Hub (3-5 phút)

backend-cd.yml (trigger tự động)
  ├─ Checkout code
  ├─ Check disk space
  ├─ SCP file nginx → /tmp/nginx-deploy/    ← MỚI
  ├─ SSH vào server:
  │   ├─ [0/10] Apply nginx config          ← MỚI (auto rollback nếu fail)
  │   ├─ [1/10] Cleanup Docker
  │   ├─ [2/10] Decode docker-compose.prod.yml
  │   ├─ [3/10] Install Doppler CLI
  │   ├─ [4/10] Download Doppler secrets → build .env
  │   ├─ [5/10] Backup RDS (pg_dump)
  │   ├─ [6/10] Pull + tag image
  │   ├─ [7/10] Stop old container → start new
  │   ├─ [8/10] Verify DB tables
  │   ├─ [9/10] Health check /health/ready (30 retries)
  │   └─ [10/10] Prune old Docker images
  └─ Done (5-8 phút)
```

---

## Khi nào cần chạy `deploy-nginx.sh` thủ công?

Script `backend/nginx/deploy/deploy-nginx.sh` **vẫn còn trong repo** cho 2 trường hợp:

1. **Test nginx config trên server local** (không cần trigger CD workflow)
2. **Sửa nginx NHANH khi CI/CD đang fail** (emergency fix)

**Cách dùng:**
```bash
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100
cd ~/apps/MenuGreenSystem   # cần clone repo (CD workflow không clone)
sudo ./backend/nginx/deploy/deploy-nginx.sh
```

> **Lưu ý:** Server hiện tại **KHÔNG clone repo** vì CD workflow tự quản lý image. Nếu muốn dùng `deploy-nginx.sh`, phải clone repo trước (xem `lightsail-setup.md`).

---

## Rollback

### Auto rollback nginx (trong workflow)

Khi `nginx -t` fail → workflow tự restore `.bak.YYYYMMDD_HHMMSS` → abort deploy.

### Auto rollback container (trong workflow)

Khi health check fail 30 lần (60s) → workflow tự restore image `:previous`.

### Manual rollback (nếu cần)

```bash
ssh ubuntu@52.77.218.100

# Xem các backup
ls -t /etc/nginx/conf.d/cors-map.conf.bak.*

# Restore nginx config
sudo cp /etc/nginx/conf.d/cors-map.conf.bak.20260711_143000 \
        /etc/nginx/conf.d/cors-map.conf
sudo nginx -t && sudo systemctl reload nginx

# Restore Docker image (nếu cần)
sudo docker pull anhtuan21112004/menugreensystem:previous
sudo docker tag anhtuan21112004/menugreensystem:previous menugreen_api
cd /home/ubuntu/apps/menugreen
docker compose -f docker-compose.prod.yml up -d
```

---

## Verify sau deploy

```bash
# Test Nginx serve đúng config mới
curl -I -X OPTIONS https://api.menugreen.food/api/Auth/login \
  -H "Origin: https://staging.menugreen.food" \
  -H "Access-Control-Request-Method: POST"
# → access-control-allow-origin: https://staging.menugreen.food

# Test API vẫn hoạt động
curl https://api.menugreen.food/health/live

# Verify nginx config hiện tại trên server
ssh ubuntu@52.77.218.100 "sudo cat /etc/nginx/conf.d/cors-map.conf"
```

---

## Files liên quan

| File | Vai trò |
|---|---|
| `backend/nginx/nginx.conf` | Main nginx config (đã fix upstream → 127.0.0.1) |
| `backend/nginx/conf.d/cors-map.conf` | CORS whitelist |
| `.github/workflows/backend-cd.yml` | CD workflow (đã thêm 2 step nginx) |
| `backend/nginx/deploy/deploy-nginx.sh` | Manual deploy script (fallback) |
| `backend/nginx/deploy/setup-server.sh` | Setup ban đầu (chạy 1 lần) |

---

*Last updated: 2026-07-11 — CI/CD tự động apply nginx config*