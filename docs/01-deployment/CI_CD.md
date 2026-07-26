# CI/CD Pipeline Guide — MenuGreen System

> **Last updated:** 2026-07-12 — Phản ánh workflow hiện tại (`backend-ci.yml` + `backend-cd.yml`).
>
> **Đã sửa:** Bỏ mô tả "13 bước deploy + push previous + base64 compose". Thêm mô tả 3-tier local rollback và EXIT trap fail-safe.
>
> **Kiến trúc tổng quan + GitHub Secrets + Server Info:** xem [ARCHITECTURE.md](./ARCHITECTURE.md).

---

## Pipeline Flow

```
┌──────────────────────┐
│  Developer           │
│  git push origin main│
└──────────┬───────────┘
           │
           ▼
┌──────────────────────────────────────────┐
│  backend-ci.yml (Build & Push)           │
│  ┌────────────────────────────────────┐  │
│  │ 1. Checkout                        │  │
│  │ 2. Setup .NET 9.0.x                │  │
│  │ 3. Restore + Build                 │  │
│  │ 4. (Optional) Run tests            │  │
│  │ 5. Docker login (Docker Hub)       │  │
│  │ 6. Build image                     │  │
│  │ 7. Tag :main + :sha + :latest      │  │
│  │ 8. Push to Docker Hub              │  │
│  └────────────────────────────────────┘  │
└──────────┬───────────────────────────────┘
           │ workflow_run completed (success only)
           ▼
┌──────────────────────────────────────────┐
│  backend-cd.yml (Deploy)                 │
│  ┌────────────────────────────────────┐  │
│  │ 1. Checkout + export SHA           │  │
│  │ 2. Check disk space                │  │
│  │ 3. SCP files lên /tmp/nginx-deploy/│  │
│  │    ├─ docker-compose.prod.yml      │  │
│  │    ├─ backend/nginx/nginx.conf     │  │
│  │    └─ backend/nginx/conf.d/cors... │  │
│  │ 4. SSH → Lightsail                 │  │
│  │ 5. Apply nginx config (FIRST!)     │  │
│  │    ├─ Backup → Copy → nginx -t     │  │
│  │    ├─ PASS: reload nginx           │  │
│  │    └─ FAIL: restore + abort        │  │
│  │ 6. Cleanup disk                    │  │
│  │ 7. Install Doppler CLI (if needed) │  │
│  │ 8. Doppler secrets → .env          │  │
│  │ 9. Backup RDS (pg_dump)            │  │
│  │    └─ FAIL = ABORT DEPLOY          │  │
│  │10. >>> DEPLOY PHASE STARTED <<<    │  │
│  │11. Tag menugreen_api               │  │
│  │    → rollback-local-<timestamp>    │  │
│  │12. Pull :main + tag menugreen_api  │  │
│  │13. Stop + remove old container     │  │
│  │14. docker compose up -d            │  │
│  │    (|| UP_FAILED=1, KHÔNG exit)    │  │
│  │15. Wait + health check             │  │
│  │    /health/ready × 30 attempts     │  │
│  │    ├─ PASS → done                  │  │
│  │    └─ FAIL → perform_rollback()    │  │
│  │16. Prune old images                │  │
│  │                                     │  │
│  │ EXIT TRAP (any non-zero exit):     │  │
│  │    if DEPLOY_PHASE_STARTED=1:      │  │
│  │      perform_rollback()            │  │
│  │    exit with ORIGINAL code         │  │
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
- `push` to `main`, `develop`
- `pull_request` to `main`, `develop`

**Jobs:**

1. **Checkout code**
2. **Setup .NET 9.0.x**
3. **Restore dependencies**
4. **Build** (Release config)
5. **Run tests** (nếu có)
6. **(NEW) Generate & Validate Migration**
   - Install dotnet-ef tool
   - Check for pending entity changes
   - Generate migration with timestamp if needed
   - Test migration on clean PostgreSQL database
   - Upload migration artifact for PR review
7. **Docker login** với Docker Hub credentials
8. **Build & tag**:
   - `:main` (latest trên main branch)
   - `:${{ github.sha }}` (commit SHA cụ thể)
   - `:latest`
9. **Push** to Docker Hub

**Outputs:**
- Image available at: `docker.io/anhtuan21112004/menugreensystem:main`
- Migration artifact (if generated)

---

### `.github/workflows/backend-cd.yml`

**Triggers:**
- `workflow_run` từ `backend-ci.yml` với conclusion = `success` (chỉ trên nhánh `main`, không phải PR)
- Manual `workflow_dispatch` (option `production` hoặc `staging`)

**Skip deploy** nếu:
- CI failed/cancelled
- Commit message chứa `#skipdeploy`
- Trigger là `pull_request`

**Lý do tách script deploy thành file riêng:**

CD workflow upload `deploy-server.sh` (~500 lines) qua SCP rồi gọi qua SSH, thay vì inline vào workflow. Lý do: GitHub Actions cap mỗi `${{ }}` expression ở 21,000 chars; logic đầy đủ (backup DB, nginx reload, Doppler download, health check, 3-tier rollback, EXIT trap) vượt quá giới hạn.

**Deploy steps (file `backend/scripts/deploy-server.sh`):**

#### Phase A — Pre-flight (fail = abort, container cũ vẫn live)

```bash
# 1. Đảm bảo self-signed cert tồn tại (cho catch-all HTTPS server)
[ -f /etc/ssl/certs/menugreen-catchall.pem ] || openssl req -x509 ...

# 2. Apply nginx config FIRST (zero downtime)
mkdir -p "$APP_DIR"
#   - Backup config hiện tại: cors-map.conf.bak.YYYYMMDD_HHMMSS, nginx.conf.bak.YYYYMMDD_HHMMSS
#   - Copy file mới từ /tmp/nginx-deploy/
#   - sudo nginx -t
#     - PASS: systemctl reload nginx
#     - FAIL: restore backup + exit 1 (container KHÔNG bị restart)

# 3. Cleanup disk
sudo docker system prune -af --volumes

# 4. Tạo docker-compose.prod.yml (đã SCP từ workflow)
# (KHÔNG còn base64-embed, file nằm trong repo)

# 5. Install Doppler CLI (nếu chưa có)

# 6. Download Doppler secrets → /tmp/doppler_raw.env
doppler secrets download --token "$DOPPLER_TOKEN" \
  --no-file --project menugreen --config prd --format env

# 7. Build .env từ Doppler secrets
# Format: Foo__Bar=value (giữ nguyên key có __, thay : → __ cho nested keys)
# Special handling: ConnectionStrings__DefaultConnection, JwtSettings__*, REDIS_URL
# Skip: LIGHTSAIL_SSH_KEY (tránh inject private key vào container)

# 8. Backup RDS (FAIL = ABORT DEPLOY)
PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "${DB_PORT:-5432}" \
  -U "$DB_USER" -d "$DB_NAME" -F p -f "/tmp/menugreen_backup_$(date +%Y%m%d_%H%M%S).sql"
# Giữ 5 file backup gần nhất
```

#### Phase B — Deploy (bắt đầu từ đây, fail = EXIT trap rollback)

```bash
# === DEPLOY PHASE STARTED ===
# Set flag DEPLOY_PHASE_STARTED=1 — bật EXIT trap từ đây

# 9. Tag snapshot image hiện tại để rollback local
if docker inspect menugreen_api > /dev/null 2>&1; then
  ROLLBACK_LOCAL_TAG="menugreen_api:rollback-local-$(date +%s)"
  sudo docker tag menugreen_api "$ROLLBACK_LOCAL_TAG"
fi

# 10. Pull image mới
sudo docker pull $IMAGE:main || { echo "Failed to pull"; exit 1; }

# 11. Tag :main → menugreen_api
sudo docker tag $IMAGE:main menugreen_api

# 12. Stop container cũ (atomic với up)
docker compose -f "$APP_DIR/docker-compose.prod.yml" down --remove-orphans || true

# 13. Up container mới — FAIL không exit ngay
docker compose -f "$APP_DIR/docker-compose.prod.yml" up -d || UP_FAILED=1
# ↑ nếu fail: tiếp tục tới health check → rollback tự nhiên

# 14. Wait + health check
for i in {1..30}; do
  curl -sf http://localhost:5000/health/ready && break
  sleep 2
done
# HEALTH_PASSED=false → gọi perform_rollback() → exit 1
# HEALTH_PASSED=true  → tiếp tục prune images
```

> **Server info (SSH, app dir, image, port, domain):** xem [ARCHITECTURE.md](./ARCHITECTURE.md#server-information).

---

## Rollback & Fail-safe

### Layer 1: Nginx fail → restore + abort

Nếu `nginx -t` fail (Phase A):
- Restore `cors-map.conf.bak.YYYYMMDD_HHMMSS` và `nginx.conf.bak.YYYYMMDD_HHMMSS`
- `exit 1`
- **Container cũ không bị restart**, **nginx vẫn chạy config cũ**
- Zero downtime cho user

### Layer 2: Health check fail → `perform_rollback()`

Nếu `curl /health/ready` fail 30 lần (60s) sau `docker compose up`:

1. `docker compose logs --tail=50` (ghi log container lỗi)
2. `docker compose down`
3. **Chọn rollback image theo 3-tier priority:**

| Tier | Source                                | Khi nào dùng                                  |
|------|---------------------------------------|-----------------------------------------------|
| 1    | Local `menugreen_api:rollback-local-*`| Mặc định — nhanh nhất, không cần Docker Hub   |
| 2    | Hub `$IMAGE:previous`                  | Local tag bị mất (vd sau nhiều lần prune)     |
| 3    | Hub `$IMAGE:main-<oldsha>`            | Local + previous đều mất                      |

4. Re-fetch Doppler secrets (đảm bảo `.env` đúng format)
5. `sudo docker tag <chosen> menugreen_api`
6. `docker compose up -d`
7. Verify `/health/live` × 15 lần
8. `exit 1` để workflow fail, operator nhận alert

### Layer 3: EXIT trap fail-safe (mới thêm 2026-07-12)

Bash `EXIT trap` được set ngay sau khi `DEPLOY_PHASE_STARTED=1`:

```bash
deploy_rollback_trap() {
  local exit_code=$?
  if [ "$exit_code" -eq 0 ] || [ "${DEPLOY_PHASE_STARTED:-0}" -ne 1 ]; then
    return
  fi
  if [ "${ROLLBACK_DONE:-0}" -eq 1 ]; then
    return
  fi
  echo ">>> FAIL-SAFE TRAP: deploy phase exited with code $exit_code"
  perform_rollback || true
  exit $exit_code  # giữ exit code gốc để GH Action vẫn hiển thị failed
}
trap deploy_rollback_trap EXIT
```

**Khi nào trigger:** Bất kỳ lệnh nào trong Phase B exit non-zero. Ví dụ:
- `docker compose up` crash giữa chừng → `set -e` exit → trap fires
- `pg_dump` đã fail ở Phase A nhưng `DEPLOY_PHASE_STARTED` chưa set → trap KHÔNG fire (đúng — backup fail không cần rollback)
- `wait` loop kết thúc với health fail → `HEALTH_PASSED=false` → gọi `perform_rollback()` thủ công

**Hai đường rollback (health path và trap) đều được guard bởi `ROLLBACK_DONE=1`** để tránh chạy hai lần.

### Manual rollback

Nếu auto rollback fail (cả 3-tier đều hết image):

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

## Database Migration

### CI/CD-Generated Migration Workflow (2026-07-26)

**Nguyên tắc:** Migration files không được lưu trong git. CI tự động generate và validate migrations khi có thay đổi entity.

```
Developer thay đổi Entity/DbContext
            │
            ▼
    git push origin main
            │
            ▼
    ┌───────────────────────────────┐
    │  backend-ci.yml              │
    │  ├─ build-and-test           │
    │  └─ generate-migration       │◄─── PostgreSQL service
    │       ├─ Check pending       │
    │       ├─ Generate migration  │
    │       └─ Test on clean DB   │
    └───────────────────────────────┘
            │
            ▼
    ┌───────────────────────────────┐
    │  backend-cd.yml              │
    │  ├─ Backup DB (pg_dump)     │
    │  ├─ Pull Docker image       │
    │  ├─ Generate migration      │◄─── On server
    │  ├─ Apply migration         │
    │  └─ Health check            │
    └───────────────────────────────┘
            │
            ▼
    Production updated!
```

#### Workflow chi tiết

**1. Developer thay đổi Entity:**
```csharp
// Entity mới hoặc thay đổi field
public class MealPlanItem
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public string? Origin { get; set; }  // ← Thêm trường mới
}
```

**2. Push lên git (KHÔNG commit migration files):**
```bash
git add backend/MenuGreen.DataAccessLayer/Entities/MealPlanItem.cs
git commit -m "feat: add Origin field to MealPlanItem"
git push
```

**3. CI Pipeline tự động:**
- `generate-migration` job chạy
- Check xem có thay đổi entity không
- Generate migration với timestamp: `Auto_20260726120000_SchemaUpdate`
- Test migration trên clean PostgreSQL database
- Upload migration artifact (để review)

**4. CD Pipeline deploy:**
- Backup database (pg_dump)
- Pull Docker image
- Generate migration trên server
- Apply migration (EF Core tự apply khi container start)
- Health check

#### Gitignore cho Migrations

```gitignore
# EF Core Migrations - Generated by CI/CD
backend/MenuGreen.DataAccessLayer/Migrations/*.cs
backend/MenuGreen.DataAccessLayer/Migrations/*.Designer.cs
backend/MenuGreen.DataAccessLayer/Migrations/ApplicationDbContextModelSnapshot.cs
# Keep the folder but ignore all files inside
backend/MenuGreen.DataAccessLayer/Migrations/
# Exception: keep .gitkeep to maintain folder structure
!backend/MenuGreen.DataAccessLayer/Migrations/.gitkeep
```

#### Helper Scripts

| Script | Purpose |
|--------|---------|
| `scripts/ci-generate-migration.sh` | CI chạy để generate migration |
| `scripts/local-migration-helper.sh` | Developer dùng để preview/test migration local |

**Local helper usage:**
```bash
# Preview pending migrations
./scripts/local-migration-helper.sh status

# Generate migration local (để review trước khi push)
./scripts/local-migration-helper.sh generate

# Generate SQL script để review
./scripts/local-migration-helper.sh script

# Apply migrations to local DB
./scripts/local-migration-helper.sh apply
```

#### Lợi ích

- Không còn conflict migrations giữa các developers
- Git history sạch, chỉ có business code
- Migration được validate trong CI trước khi deploy
- Developer không cần quan tâm đến migration

#### Hạn chế và cách xử lý

| Hạn chế | Cách xử lý |
|----------|-------------|
| Không review migration trước trên PR | CI post comment với migration artifact |
| Complex migrations (data transform) | Vẫn có thể tạo manual migration |
| Không thấy migration files trong git | Artifact được lưu 30 ngày trong CI |

#### Rollback

Nếu migration fail trên production:
1. CD workflow tự động rollback (restore previous image)
2. Database được restore từ pg_dump backup
3. Developer cần fix code và push lại

---

### Automatic (trên app startup)

App tự chạy EF Core migration khi khởi động (xem `Program.cs` / `DbContext`). Không cần efbundle hay chạy `dotnet ef` trong container.

Migration files ở `MenuGreen.DataAccessLayer/Migrations/`. Khi push migration mới → CI/CD build image mới → container mới tự apply lúc startup.

### Manual trigger (Admin endpoint)

Có sẵn endpoint admin để chạy migration thủ công:

```
POST /api/AdminMigration/migrate
```

Xem chi tiết tại `backend/MenuGreen.API/Controllers/AdminMigrationController.cs`. **Chỉ dùng khi auto-migration fail.**

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

| Endpoint             | Description                | Check trong CD |
|----------------------|----------------------------|----------------|
| `GET /health`        | Full health (DB + Redis)   |                |
| `GET /health/ready`  | Readiness (DB + Redis)     | ✅ (30 lần × 2s = 60s) |
| `GET /health/live`   | Liveness (always OK)       | ✅ (trong Docker healthcheck + rollback verify) |

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
  ├─ SCP file nginx + docker-compose.prod.yml → /tmp/nginx-deploy/
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
| [`../GITHUB_SECRETS_SETUP.md`](../GITHUB_SECRETS_SETUP.md) | Setup GitHub Secrets         |

---

*Last updated: 2026-07-12*
