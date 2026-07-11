# CI/CD Pipeline Guide - MenuGreen System

> **Last updated:** 2026-07-11 — Phản ánh workflow hiện tại (backend-ci.yml + backend-cd.yml).

---

## Overview

MenuGreen sử dụng **2 GitHub Actions workflows** riêng biệt:

| File                        | Mục đích                                     | Trigger                |
|-----------------------------|----------------------------------------------|------------------------|
| `backend-ci.yml`            | Build + Test + Push Docker image             | Push/PR vào `main`     |
| `backend-cd.yml`            | Deploy lên AWS Lightsail                     | Sau khi CI pass + manual |

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
│  │ 1. SSH → Lightsail                 │  │
│  │ 2. Cleanup old Docker resources    │  │
│  │ 3. Decode docker-compose.prod.yml  │  │ ← base64 embedded
│  │ 4. Install Doppler CLI (if needed) │  │
│  │ 5. Doppler secrets → .env          │  │
│  │ 6. Backup RDS (pg_dump)            │  │
│  │ 7. Tag :main → :previous           │  │
│  │ 8. Pull :main                      │  │
│  │ 9. Stop old container              │  │
│  │10. Up new container                │  │
│  │11. Verify tables exist in DB       │  │
│  │12. Health check /health/ready      │  │
│  │    └─ FAIL → Auto rollback         │  │
│  │13. Prune old Docker images         │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
           │
           ▼
    API live at:
    https://api.menugreen.food
```

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

Chi tiết setup xem: [GITHUB_SECRETS_SETUP.md](../GITHUB_SECRETS_SETUP.md)

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

**Steps (deploy via SSH):**

```bash
# 1. Cleanup disk
sudo docker system prune -af --volumes

# 2. Decode embedded docker-compose.prod.yml
echo "$COMPOSE_B64" | base64 -d > "$APP_DIR/docker-compose.prod.yml"

# 3. Install Doppler CLI (if missing)
curl -fsSL https://github.com/DopplerHQ/cli/releases/...

# 4. Download Doppler secrets
doppler secrets download --token $DOPPLER_TOKEN \
  --no-file --project menugreen --config prd --format env \
  > /tmp/doppler_raw.env

# 5. Build .env from secrets
# Format: Foo__Bar=value (convert : to __ for nested keys)
# Special handling for: ConnectionStrings__DefaultConnection, JwtSettings__*, REDIS_URL

# 6. Backup RDS (FAIL = ABORT DEPLOY)
PGPASSWORD=$DB_PASSWORD pg_dump -h $DB_HOST -U $DB_USER \
  -d $DB_NAME -F p -f /tmp/menugreen_backup_*.sql

# 7. Tag previous image
docker tag $IMAGE:main $IMAGE:previous
docker push $IMAGE:previous

# 8. Pull latest
docker pull $IMAGE:main

# 9. Stop + remove old container
docker compose -f $APP_DIR/docker-compose.prod.yml down --remove-orphans

# 10. Start new container
docker compose -f $APP_DIR/docker-compose.prod.yml up -d

# 11. Wait + health check
for i in {1..30}; do
  curl -sf http://localhost:5000/health/ready && break
  sleep 2
done

# 12. Auto-rollback if health check fails
# - Logs failed container
# - Down compose
# - Pull $IMAGE:previous
# - Re-fetch Doppler secrets
# - Up with previous image
```

---

## Server Information

| Property         | Value                                                          |
|------------------|----------------------------------------------------------------|
| **SSH**          | `ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100`    |
| **App directory** | `/home/ubuntu/apps/menugreen`                                  |
| **Docker Image** | `docker.io/anhtuan21112004/menugreensystem:main`                |
| **API Port**     | 5000 (chỉ internal)                                            |
| **Domain**       | `https://api.menugreen.food`                                   |
| **OS**           | Ubuntu 22.04 LTS                                                |

---

## Docker Compose Production (embedded base64)

`docker-compose.prod.yml` được **embedded base64 trong workflow**, không nằm trong repo. Decode ra:

```yaml
services:
  api:
    image: docker.io/anhtuan21112004/menugreensystem:latest
    container_name: menugreen_api
    pull_policy: always
    env_file:
      - .env
    environment:
      - ASPNETCORE_ENVIRONMENT=${ASPNETCORE_ENVIRONMENT}
      - ASPNETCORE_URLS=http://+:5000
    ports:
      - "5000:5000"
    networks:
      - menugreen-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health/live"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          memory: 800M
          cpus: '1.0'
    volumes: []

networks:
  menugreen-net:
    external: true
```

> **Lưu ý:** Compose này **CHỈ** có service `api` — không có Redis (Redis là managed service, connection string từ `REDIS_URL` env).

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

## Nginx Configuration (trên host)

Cấu hình chi tiết: xem [cors-config.md](./cors-config.md) và `MenuGreenSystem/backend/nginx/deploy/README.md`.

Tóm tắt:

- Nginx chạy **trên host** (không trong Docker)
- Config trong `/etc/nginx/nginx.conf` + `/etc/nginx/conf.d/cors-map.conf`
- Proxy: `https://api.menugreen.food` → `http://localhost:5000`
- CORS dùng **map** trong `cors-map.conf` (whitelist origins)
- SSL Let's Encrypt auto-renew

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
| [DEPLOY.md](./DEPLOY.md)                    | Tổng quan deployment plan            |
| [lightsail-setup.md](./lightsail-setup.md)  | Setup server từ đầu                  |
| [DOPPLER_SETUP.md](./DOPPLER_SETUP.md)      | Quản lý secrets qua Doppler          |
| [cors-config.md](./cors-config.md)          | CORS & Nginx                         |
| [DEPLOY_FIX_PLAN.md](./DEPLOY_FIX_PLAN.md)  | Lịch sử fix deploy (đã xong)         |
| [DEPLOY_REVIEW.md](./DEPLOY_REVIEW.md)      | Lịch sử review gap (đã xong)         |
| [GITHUB_SECRETS_SETUP.md](../GITHUB_SECRETS_SETUP.md) | Setup GitHub Secrets         |

---

*Last updated: 2026-07-11*
