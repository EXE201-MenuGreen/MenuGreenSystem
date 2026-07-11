# CI/CD Pipeline Guide - MenuGreen System

> **Last updated:** 2026-07-11 — Phản ánh workflow hiện tại (backend-ci.yml + backend-cd.yml).
>
> **Kiến trúc tổng quan + GitHub Secrets + Server Info + docker-compose.prod.yml:** xem [ARCHITECTURE.md](./ARCHITECTURE.md).

---

## Pipeline Flow (hiện tại)

```
┌──────────────────────┐
│  Developer           │
│  git push origin main│
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────────────────────┐
│  backend-ci.yml (Build & Push)          │
│  ┌────────────────────────────────────┐  │
│  │ 1. Checkout                        │  │
│  │ 2. Setup .NET 9.0                  │  │
│  │ 3. Restore + Build                 │  │
│  │ 4. (Optional) Run tests            │  │
│  │ 5. Docker login (Docker Hub)       │  │
│  │ 6. Build image → push :main + :sha │  │
│  └────────────────────────────────────┘  │
└──────────┬───────────────────────────────┘
           │ workflow_run completed
           ▼
┌──────────────────────────────────────────┐
│  backend-cd.yml (Deploy)                 │
│  ┌────────────────────────────────────┐  │
│  │ 1. Checkout                        │  │
│  │ 2. Check disk space                │  │
│  │ 3. SCP nginx files → server       │  │
│  │    (nginx.conf + cors-map.conf)    │  │
│  │ 4. SSH → Lightsail                 │  │
│  │ 5. Apply nginx config (FIRST!)     │  │
│  │    ├─ Backup → Copy → nginx -t     │  │
│  │    ├─ PASS: reload nginx           │  │
│  │    └─ FAIL: restore + abort        │  │
│  │ 6. Cleanup old Docker resources    │  │
│  │ 7. Decode docker-compose.prod.yml  │  │ ← base64 embedded
│  │ 8. Install Doppler CLI (if needed) │  │
│  │ 9. Doppler secrets → .env          │  │
│  │10. Backup RDS (pg_dump)            │  │
│  │11. Tag :main → :previous           │  │
│  │12. Pull :main                      │  │
│  │13. Stop old container              │  │
│  │14. Up new container                │  │
│  │15. Verify tables exist in DB       │  │
│  │16. Health check /health/ready      │  │
│  │    └─ FAIL → Auto rollback         │  │
│  │17. Prune old Docker images         │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
           │
           ▼
    API live at:
    https://api.menugreen.food
```

> **Lưu ý quan trọng:** Nginx được apply **TRƯỚC** khi restart container. Nếu nginx syntax fail → restore backup + abort toàn bộ deploy → container KHÔNG bị restart → zero downtime.

---

## GitHub Secrets (bắt buộc)

| Secret                | Description                                | Example                         |
|-----------------------|--------------------------------------------|---------------------------------|
| `DOPPLER_TOKEN`       | Doppler service token (config `prd`)       | `dp.prd.xxx...`                 |
| `LIGHTSAIL_HOST`      | Server IP                                  | `52.77.218.100`                 |
| `LIGHTSAIL_USER`      | SSH username                               | `ubuntu`                        |
| `LIGHTSAIL_SSH_KEY`   | SSH private key (.pem full content)        | `-----BEGIN...`                 |
| `DOCKERHUB_USERNAME`  | Docker Hub account                         | `anhtuan21112004`               |
| `DOCKERHUB_TOKEN`     | Docker Hub access token (Read+Write)       | `dckr_pat_xxx...`               |

Vào **GitHub** → Repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

> **Chi tiết secrets (kèm Doppler config `prd`):** xem [ARCHITECTURE.md](./ARCHITECTURE.md#github-secrets-bắt-buộc).

---

## Workflow files chi tiết

### `.github/workflows/backend-ci.yml`

**Triggers:**
- `push` to `main`
- `pull_request` to `main`
- Manual `workflow_dispatch`

**Jobs:**

1. **Checkout code**
2. **Setup .NET 9.0.x**
3. **Restore dependencies**
4. **Build** (Release config)
5. **Run tests** (nếu có)
6. **Docker login** với Docker Hub credentials
7. **Build & tag**:
   - `:main` (latest trên main branch)
   - `:${{ github.sha }}` (commit SHA cụ thể)
   - `:latest`
8. **Push** to Docker Hub

**Outputs:**
- Image available at: `docker.io/anhtuan21112004/menugreensystem:main`

---

### `.github/workflows/backend-cd.yml`

**Triggers:**
- `workflow_run` từ `backend-ci.yml` với conclusion = `success` (chỉ trên nhánh `main`, không phải PR)
- Manual `workflow_dispatch` (option `production` hoặc `staging`)

**Skip deploy** nếu:
- CI failed/cancelled
- Commit message chứa `#skipdeploy`
- Trigger là `pull_request`

**Steps (deploy via SCP + SSH):**

```bash
# === Pre-SSH: SCP nginx files ===
# GitHub Actions dùng appleboy/scp-action copy file từ repo lên server
scp backend/nginx/nginx.conf ubuntu@server:/tmp/nginx-deploy/
scp backend/nginx/conf.d/cors-map.conf ubuntu@server:/tmp/nginx-deploy/

# === SSH vào server ===

# 1. Apply nginx config (FIRST - trước khi restart container)
#    Nếu fail → restore backup + abort toàn bộ deploy (zero downtime)
NGINX_TS=$(date +"%Y%m%d_%H%M%S")
sudo cp /etc/nginx/conf.d/cors-map.conf \
        /etc/nginx/conf.d/cors-map.conf.bak.$NGINX_TS
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak.$NGINX_TS
sudo cp /tmp/nginx-deploy/nginx.conf /etc/nginx/nginx.conf
sudo cp /tmp/nginx-deploy/conf.d/cors-map.conf /etc/nginx/conf.d/cors-map.conf
if sudo nginx -t 2>&1; then
  sudo systemctl reload nginx
else
  sudo cp /etc/nginx/conf.d/cors-map.conf.bak.$NGINX_TS \
          /etc/nginx/conf.d/cors-map.conf
  sudo cp /etc/nginx/nginx.conf.bak.$NGINX_TS /etc/nginx/nginx.conf
  exit 1
fi
rm -rf /tmp/nginx-deploy

# 2. Cleanup disk
sudo docker system prune -af --volumes

# 3. Decode embedded docker-compose.prod.yml
echo "$COMPOSE_B64" | base64 -d > "$APP_DIR/docker-compose.prod.yml"

# 4. Install Doppler CLI (if missing)
curl -fsSL https://github.com/DopplerHQ/cli/releases/...

# 5. Download Doppler secrets
doppler secrets download --token $DOPPLER_TOKEN \
  --no-file --project menugreen --config prd --format env \
  > /tmp/doppler_raw.env

# 6. Build .env from secrets
# Format: Foo__Bar=value (convert : to __ for nested keys)
# Special handling for: ConnectionStrings__DefaultConnection, JwtSettings__*, REDIS_URL

# 7. Backup RDS (FAIL = ABORT DEPLOY)
PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -U $DB_USER \
  -d $DB_NAME -F p -f /tmp/menugreen_backup_*.sql

# 8. Tag previous image
docker tag $IMAGE:main $IMAGE:previous
docker push $IMAGE:previous

# 9. Pull latest
docker pull $IMAGE:main

# 10. Stop + remove old container
docker compose -f $APP_DIR/docker-compose.prod.yml down --remove-orphans

# 11. Start new container
docker compose -f $APP_DIR/docker-compose.prod.yml up -d

# 12. Wait + health check
for i in {1..30}; do
  curl -sf http://localhost:5000/health/ready && break
  sleep 2
done

# 13. Auto-rollback if health check fails
# - Logs failed container
# - Down compose
# - Pull $IMAGE:previous
# - Re-fetch Doppler secrets
# - Up with previous image
```

> **Server info (SSH, app dir, image, port, domain):** xem [ARCHITECTURE.md](./ARCHITECTURE.md#server-information).

---

## Database Migration

### Automatic (trên app startup)

App tự chạy EF Core migration khi khởi động (xem `Program.cs` / `DbContext`). Không cần efbundle hay chạy `dotnet ef` trong container.

### Backup trước khi deploy

CD workflow tự động `pg_dump` trước khi deploy:

```bash
BACKUP_FILE="/tmp/menugreen_backup_$(date +%Y%m%d_%H%M%S).sql"
PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" \
  -U "$DB_USER" -d "$DB_NAME" -F p -f "$BACKUP_FILE"

# Backup fail → ABORT deployment
```

Backup giữ lại 5 file gần nhất ở `/tmp/`.

---

## Health Check

| Endpoint             | Description                | Check trong CI |
|----------------------|----------------------------|----------------|
| `GET /health`        | Full health (DB + Redis)   |                |
| `GET /health/ready`  | Readiness (DB + Redis)     | ✅ (30 lần, 2s/lần) |
| `GET /health/live`   | Liveness (always OK)       | (trong Docker healthcheck) |

### Test thủ công

```bash
# Qua Nginx (public)
curl -I https://api.menugreen.food/health/live

# Trực tiếp API (trên server)
curl -I http://localhost:5000/health/ready

# Trên server từ máy local
ssh -i LightsailDefaultKeyPair.pem ubuntu@52.77.218.100 \
  "curl http://localhost:5000/health/ready"
```

---

## Rollback Plan

### Auto rollback (CD workflow tự làm)

Nếu health check fail 30 lần (60s) sau khi deploy:

1. Log container lỗi
2. Stop container hiện tại
3. Pull image `anhtuan21112004/menugreensystem:previous`
4. Re-fetch Doppler secrets (đảm bảo `.env` đúng format)
5. Tag previous image
6. `docker compose up -d` với image cũ
7. `exit 1` để workflow fail

### Manual rollback

```bash
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100

cd /home/ubuntu/apps/menugreen

# Stop current
docker compose -f docker-compose.prod.yml down

# Pull previous image
sudo docker pull anhtuan21112004/menugreensystem:previous

# Tag cho compose
sudo docker tag anhtuan21112004/menugreensystem:previous menugreen_api

# Start
docker compose -f docker-compose.prod.yml up -d

# Verify
docker logs menugreen_api --tail 50
curl http://localhost:5000/health/ready
```

### Rollback DB từ backup

```bash
ls -t /tmp/menugreen_backup_*.sql | head -1

# Restore
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST \
  -U $DB_USER -d $DB_NAME < /tmp/menugreen_backup_20260711_143000.sql
```

---

## Nginx Configuration (auto-deploy qua CI/CD)

Cấu hình chi tiết: xem [NGINX_AND_CORS.md](./NGINX_AND_CORS.md) và `backend/nginx/`.

### Tóm tắt

- Nginx chạy **trên host** (không trong Docker)
- Config trong `/etc/nginx/nginx.conf` + `/etc/nginx/conf.d/cors-map.conf`
- Source config trong git: `backend/nginx/`
- **Deploy tự động qua CI/CD**: sửa file → commit → push → GitHub Actions tự SCP + apply
- Proxy: `https://api.menugreen.food` → `http://localhost:5000`
- CORS dùng **map** trong `cors-map.conf` (whitelist origins)
- SSL Let's Encrypt auto-renew

### Workflow apply Nginx

```
Developer sửa backend/nginx/conf.d/cors-map.conf
       ↓
git push origin main
       ↓
backend-ci.yml — build Docker image (3-5 phút)
       ↓
backend-cd.yml:
  ├─ SCP file nginx lên /tmp/nginx-deploy/
  └─ SSH apply:
     ├─ Backup config (.bak.YYYYMMDD_HHMMSS)
     ├─ Copy file mới → /etc/nginx/
     ├─ nginx -t → PASS → systemctl reload nginx
     └─ nginx -t → FAIL → restore backup + abort
```

### Zero downtime guarantee

Khi nginx apply fail:
- ✅ Container KHÔNG bị restart (vẫn chạy image cũ)
- ✅ Nginx vẫn chạy với config cũ
- ✅ Không có downtime cho user
- ❌ Workflow fail → Dev nhận alert qua GitHub Actions

---

## Monitoring (hiện tại)

- Health check `curl /health/ready` trong CD workflow
- Application logs: `docker logs menugreen_api -f`
- Nginx access logs: `/var/log/nginx/access.log`
- Nginx error logs: `/var/log/nginx/error.log`

Có thể tích hợp thêm:
- UptimeRobot: ping `/health/live` mỗi 5 phút
- CloudWatch: collect Docker metrics
- Prometheus + Grafana: (chưa setup, có thể thêm sau)

---

## Troubleshooting

### Build failures

```bash
# Check network
curl -s https://api.nuget.org/v3/index.json | head

# Clear NuGet cache
dotnet nuget locals all --clear
```

### Deployment failures

```bash
# Container logs
docker logs menugreen_api --tail 100

# Environment variables trong container
docker exec menugreen_api env | sort

# Port availability
sudo netstat -tlnp | grep 5000

# Container status
docker ps -a | grep menugreen
```

### Doppler issues

```bash
# Test download thủ công
DOPPLER_TOKEN=dp.prd.xxx doppler secrets download \
  --no-file --project menugreen --config prd --format env
```

### Health check fails

```bash
# Trên server
curl -v http://localhost:5000/health/ready
docker logs menugreen_api --tail 50

# Qua Nginx
curl -v https://api.menugreen.food/health/ready
sudo nginx -t
sudo tail -20 /var/log/nginx/error.log
```

---

## Related Documents

| Document                                    | Description                          |
|---------------------------------------------|--------------------------------------|
| [ARCHITECTURE.md](./ARCHITECTURE.md)        | Kiến trúc tổng quan + GitHub Secrets + Server Info |
| [NGINX_AND_CORS.md](./NGINX_AND_CORS.md)    | CORS & Nginx configuration           |
| [SECRETS_MANAGEMENT.md](./SECRETS_MANAGEMENT.md) | Quản lý secrets qua Doppler    |
| [SERVER_SETUP.md](./SERVER_SETUP.md)        | Setup server từ đầu                  |
| [archive/](./archive/)                      | Lịch sử fix + review (đã xong)       |
| [GITHUB_SECRETS_SETUP.md](../GITHUB_SECRETS_SETUP.md) | Setup GitHub Secrets         |

---

*Last updated: 2026-07-11*
