# MenuGreen System - Production Deployment Plan

> **Last updated:** 2026-07-11 — Phản ánh đúng trạng thái hiện tại của hệ thống.

---

## Mục tiêu

- Deploy backend .NET API lên **AWS Lightsail Ubuntu** sử dụng **GitHub Actions CI/CD**.
- **PostgreSQL** chạy trên **AWS RDS** (bên ngoài server).
- **Redis** chạy trên **AWS** (ElastiCache hoặc managed) — không phải Docker container local.
- API chạy trong **Docker container** duy nhất (`menugreen_api`).
- Nginx chạy **trong Docker** local (`docker-compose.yml`) cho dev — production dùng **Nginx trên host** (đã cài ở `/etc/nginx/`).
- **Tự động hóa hoàn toàn**: push code lên `main` → CI/CD tự deploy.

---

## Kiến trúc Production (hiện tại)

```
GitHub Repository (main branch)
       │
       ▼
┌─────────────────────────────────────────┐
│       GitHub Actions CI/CD              │
│  ┌──────────────┐  ┌────────────────┐   │
│  │ backend-ci   │→ │ backend-cd     │   │
│  │ Build + Push │  │ Deploy to      │   │
│  │ Docker image │  │ Lightsail      │   │
│  └──────────────┘  └────────────────┘   │
└─────────────────────────────────────────┘
       │                       │
       │ Docker Hub            │ SSH (appleboy/ssh-action)
       ▼                       ▼
Docker Hub:                AWS Lightsail (Ubuntu 22.04)
anhtuan21112004/           52.77.218.100
menugreensystem:main       /home/ubuntu/apps/menugreen
                           │
                           ├─ Docker container: menugreen_api (port 5000)
                           ├─ Nginx (host, port 80/443) → proxy → 5000
                           │
                           ▼
                   AWS RDS PostgreSQL
                   menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com:5432
                   Database: menugreendb
                           │
                           ▼
                   Redis (managed)
                   REDIS_URL từ Doppler secrets
```

---

## Services (hiện tại)

| Service      | Location                | Port | Notes                                                          |
|--------------|-------------------------|------|----------------------------------------------------------------|
| **API**      | Docker container        | 5000 | `menugreen_api`, image từ Docker Hub                           |
| **Nginx**    | Host (Ubuntu)           | 80, 443 | Reverse proxy + SSL termination + CORS. Config trong `/etc/nginx/` |
| **PostgreSQL** | AWS RDS              | 5432 | Bên ngoài, security group allow IP Lightsail                  |
| **Redis**    | Managed (AWS/Doppler)   | 6379 | Connection string từ `REDIS_URL` env, không phải Docker local |

---

## CI/CD Pipeline (hiện tại)

### Workflow files

- **`.github/workflows/backend-ci.yml`** — Build & push Docker image lên Docker Hub
- **`.github/workflows/backend-cd.yml`** — Deploy lên Lightsail (chạy sau khi CI pass)

### Deploy Flow (`backend-cd.yml`)

```
GitHub Actions runner
       │
       ▼
SSH vào Lightsail (appleboy/ssh-action)
       │
       ├─ 1. Cleanup Docker (prune images/containers cũ)
       ├─ 2. Decode docker-compose.prod.yml (base64 embedded) → /home/ubuntu/apps/menugreen/
       ├─ 3. Cài Doppler CLI (nếu chưa có)
       ├─ 4. Download secrets từ Doppler project `menugreen` config `prd`
       ├─ 5. Build file .env từ Doppler secrets
       │      └─ ConnectionStrings__DefaultConnection
       │      └─ JwtSettings__SecretKey / Issuer / Audience
       │      └─ REDIS_URL (cho Program.cs đọc)
       │      └─ Tất cả các secret dạng `Foo__Bar=value`
       ├─ 6. Backup RDS bằng pg_dump → /tmp/menugreen_backup_*.sql
       │      └─ Nếu backup FAIL → ABORT deployment
       ├─ 7. Pull image `anhtuan21112004/menugreensystem:main`
       ├─ 8. Tag `menugreensystem:main` → `menugreensystem:previous` (rollback)
       ├─ 9. Stop + remove old container
       ├─ 10. Tag image cho compose: `menugreensystem:main` → `menugreen_api`
       ├─ 11. `docker compose -f docker-compose.prod.yml up -d`
       ├─ 12. Verify tables tồn tại trong DB
       ├─ 13. Health check `/health/ready` (max 30 lần, mỗi 2s)
       │      └─ Nếu FAIL → tự động rollback về `:previous`
       └─ 14. Prune old images (chỉ giữ `:main`, `:previous`, `:sha`)
```

### Trigger

- **Tự động:** CI pass trên nhánh `main` → CD trigger
- **Manual:** Workflow Dispatch với 2 option `production` / `staging`
- **Skip:** Commit message chứa `#skipdeploy`

---

## PHASE 1: Chuẩn bị GitHub Secrets

### Secrets bắt buộc

| Secret Name            | Giá trị                                          | Ghi chú                                  |
|------------------------|--------------------------------------------------|------------------------------------------|
| `DOPPLER_TOKEN`        | `dp.prd.xxx...`                                  | Service token Doppler config `prd`       |
| `LIGHTSAIL_HOST`       | `52.77.218.100`                                  | IP server                                |
| `LIGHTSAIL_USER`       | `ubuntu`                                         | SSH username                             |
| `LIGHTSAIL_SSH_KEY`    | (paste nội dung file `.pem`)                     | Toàn bộ file, bao gồm `BEGIN`/`END`      |
| `DOCKERHUB_USERNAME`   | `anhtuan21112004`                                | Docker Hub account                       |
| `DOCKERHUB_TOKEN`      | (Docker Hub access token)                        | Read + Write để push image               |

Vào **GitHub** → Repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

### Doppler secrets (config `prd`)

App đọc các biến từ Doppler (đã chuẩn hóa dạng `Foo__Bar=value` cho .NET):

| Secret                                              | Mục đích                                  |
|-----------------------------------------------------|-------------------------------------------|
| `CONNECTIONSTRINGS__DEFAULTCONNECTION`              | Full connection string PostgreSQL         |
| `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`        | Redis connection (sẽ ghép thành REDIS_URL)|
| `JWT_SECRET`, `JWT_ISSUER`, `JWT_AUDIENCE`          | JWT config                                |
| `JWTSETTINGS__SECRETKEY` (alternative)              | Alternative JWT secret key                |
| `ALLOWEDORIGINS`                                    | Domain CORS cho phép                      |
| `RESEND__APIKEY`, `RESEND__FROMEMAIL`, `RESEND__FROMNAME` | Email service                        |
| `SEPAY__*`                                          | Payment gateway (SePay VN)                |
| `FIREBASE__CREDENTIALPATH`                          | Firebase FCM credential                   |
| `CVSERVICE__BASEURL`, `CVSERVICE__APISECRETKEY`     | Computer Vision microservice              |
| `NUTRITIONASSISTANT__WORKERURL`                     | Nutrition AI worker                       |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_SSL_MODE` | RDS info (cho backup script) |

Chi tiết xem: [DOPPLER_SETUP.md](./DOPPLER_SETUP.md)

---

## PHASE 2: Server Preparation

### Yêu cầu server

- Lightsail **$10/tháng Small** (2GB RAM, 1 vCPU, 60GB SSD) — đang dùng
- Ubuntu 22.04 LTS
- Docker + Docker Compose đã cài
- Network: outbound tới Docker Hub, Doppler API, RDS, Redis managed

### App directory trên server

```
/home/ubuntu/apps/menugreen/
├── .env                              # Tạo tự động bởi CI/CD từ Doppler
├── docker-compose.prod.yml           # Base64 embedded trong workflow (NO REDIS)
└── (không cần clone repo trên server — CD tự quản lý image)
```

> **Lưu ý:** Server **KHÔNG cần clone repo**. Image pull thẳng từ Docker Hub. CD workflow tự tạo `.env` từ Doppler.

### Firewall Lightsail

Mở qua console Lightsail:

| Protocol | Port | Source       | Mục đích                  |
|----------|------|--------------|---------------------------|
| SSH      | 22   | My IP / 0/0  | SSH để deploy             |
| HTTP     | 80   | Anywhere     | Nginx                     |
| HTTPS    | 443  | Anywhere     | Nginx SSL                 |

RDS Security Group: allow `52.77.218.100/32` port 5432.

---

## PHASE 3: Deploy tự động

### Cách deploy

**Chỉ cần push code lên nhánh `main`:**

```bash
git add .
git commit -m "feat: mô tả thay đổi"
git push origin main
```

GitHub Actions sẽ tự động:
1. Chạy unit tests (nếu có)
2. Build Docker image
3. Push lên Docker Hub (`anhtuan21112004/menugreensystem:main`)
4. Trigger CD workflow
5. SSH vào Lightsail
6. Pull Doppler secrets → tạo `.env`
7. Backup RDS (fail → abort)
8. Pull image mới
9. Stop container cũ → start container mới
10. Auto-migration (app tự chạy khi startup)
11. Verify tables + health check
12. Auto-rollback nếu fail

### Theo dõi

Vào **GitHub** → Repository → **Actions** → chọn workflow `Backend CD - Deploy`.

---

## PHASE 4: Verify sau deploy

### Checklist

- [ ] Workflow `Backend CD` status: ✅ green
- [ ] Container `menugreen_api` đang chạy
- [ ] Health check: `curl http://52.77.218.100:5000/health/ready` → 200
- [ ] Swagger UI: `http://52.77.218.100:5000/swagger/index.html`
- [ ] Nginx proxy: `curl https://api.menugreen.food/health/live` → 200
- [ ] CORS preflight: `curl -I -X OPTIONS https://api.menugreen.food/api/Auth/login -H "Origin: https://www.menugreen.food" -H "Access-Control-Request-Method: POST"`

### Lệnh kiểm tra trên server

```bash
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100

# Container status
docker ps | grep menugreen_api

# Xem logs
docker logs menugreen_api --tail 50

# Health check
curl http://localhost:5000/health/ready

# Env trong container
docker exec menugreen_api env | grep -E 'ConnectionStrings|JwtSettings|REDIS'

# Nginx status
sudo systemctl status nginx
sudo nginx -t
sudo tail -20 /var/log/nginx/error.log
```

---

## Xử lý lỗi thường gặp

| Triệu chứng                                    | Nguyên nhân                                      | Cách fix                                                                       |
|------------------------------------------------|--------------------------------------------------|--------------------------------------------------------------------------------|
| SSH connection failed                          | `LIGHTSAIL_SSH_KEY` sai format                  | Đảm bảo paste đủ cả `-----BEGIN RSA PRIVATE KEY-----` và `-----END...-----`   |
| Doppler download fail                          | `DOPPLER_TOKEN` sai/expired                      | Tạo lại Service Token Doppler                                                 |
| `docker pull` fail                              | Image chưa được push lên Docker Hub              | Xem logs CI, đảm bảo backend-ci pass                                          |
| Backup abort deployment                         | RDS security group chặn IP, hoặc password sai    | Test: `PGPASSWORD=xxx psql -h <RDS_ENDPOINT> -U postgres -d menugreendb`      |
| Health check fail sau 30 lần → auto rollback   | App crash khi startup, missing env, bad migration| `docker logs menugreen_api --tail 100` xem lý do cụ thể                        |
| Redis không connect                             | `REDIS_URL` sai hoặc Redis chưa whitelist IP    | Test từ server: `redis-cli -u $REDIS_URL ping`                                 |
| CORS error                                      | Domain chưa có trong nginx config                | Sửa `/etc/nginx/conf.d/cors-map.conf` (xem [cors-config.md](./cors-config.md))|

### Re-run deployment

Vào **Actions** → `Backend CD - Deploy` → click workflow failed → **Re-run all jobs**.

### Rollback thủ công (nếu auto-rollback không hoạt động)

```bash
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100

# Stop current
docker stop menugreen_api && docker rm menugreen_api

# Pull previous image
sudo docker pull anhtuan21112004/menugreensystem:previous
sudo docker tag anhtuan21112004/menugreensystem:previous menugreen_api

# Start
cd /home/ubuntu/apps/menugreen
docker compose -f docker-compose.prod.yml up -d

# Verify
docker logs menugreen_api --tail 50
curl http://localhost:5000/health/ready
```

---

## Redis Configuration

- **Loại:** Managed (AWS ElastiCache hoặc Upstash), connection string dạng `host:port,password=xxx`
- **Config:** Truyền qua env `REDIS_URL` (CI/CD build từ Doppler `REDIS_HOST` + `REDIS_PORT` + `REDIS_PASSWORD`)
- **Trong code:** `Program.cs` đọc `Redis:ConnectionString` → fallback `REDIS_URL` env

---

## Local Development (docker-compose.yml)

Cho dev local, dùng file `MenuGreenSystem/backend/docker-compose.yml`:

- **postgres**: PostgreSQL 16-alpine, port 5432, seed data từ `database/`
- **api**: .NET API, port 5000, depends_on postgres
- **nginx**: Reverse proxy, ports 80/443, depends_on api

```bash
cd MenuGreenSystem/backend
docker compose up -d

# Verify
curl http://localhost/health/live
curl http://localhost/api/...
```

---

## Lưu ý quan trọng

- **Không commit** `.env` vào git (đã có `.gitignore`).
- **PostgreSQL KHÔNG chạy trong Docker production** (dùng RDS).
- **Redis KHÔNG chạy trong Docker production** (managed).
- **CI/CD tự động deploy khi push lên `main`**. Nhánh `Tuan` đã bỏ.
- **`docker-compose.prod.yml` được nhúng base64 trong workflow**, không cần file riêng trong repo.
- **App tự chạy migration khi startup** (không cần efbundle bên ngoài).
- **Auto-rollback** nếu health check fail 30 lần (~60s).

---

## Liên hệ / Tài liệu liên quan

- [lightsail-setup.md](./lightsail-setup.md) — Hướng dẫn setup server từ đầu
- [CI_CD.md](./CI_CD.md) — Chi tiết về CI/CD pipeline
- [cors-config.md](./cors-config.md) — CORS & nginx config
- [DOPPLER_SETUP.md](./DOPPLER_SETUP.md) — Quản lý secrets qua Doppler
- [DEPLOY_FIX_PLAN.md](./DEPLOY_FIX_PLAN.md) — Lịch sử fix deploy (đã xong)
- [DEPLOY_REVIEW.md](./DEPLOY_REVIEW.md) — Lịch sử review gap (đã xong)
