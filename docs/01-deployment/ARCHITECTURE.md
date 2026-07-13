# MenuGreen System — Architecture Overview

> **Last updated:** 2026-07-12 — Phản ánh đúng trạng thái hiện tại của hệ thống.
>
> **Đã sửa:** Bỏ tuyên bố "docker-compose.prod.yml được base64-embed" (file thực tế nằm trong repo), bổ sung mô tả 3-tier rollback, exit trap fail-safe.

---

## Mục tiêu

- Deploy backend .NET API lên **AWS Lightsail Ubuntu** thông qua **GitHub Actions CI/CD**.
- **PostgreSQL** chạy trên **AWS RDS** (bên ngoài server).
- **Redis** chạy trên **AWS managed** (ElastiCache hoặc tương đương) — không phải Docker container local.
- API chạy trong **một Docker container duy nhất** (`menugreen_api`).
- **Nginx chạy trên host** (`/etc/nginx/`) — KHÔNG nằm trong Docker image. Config Nginx được source trong git (`backend/nginx/`) và được apply tự động qua CI/CD.
- **Tự động hoàn toàn**: `git push origin main` → CI/CD tự deploy (cả API image lẫn Nginx config).
- **Auto-rollback fail-safe**: nếu bất kỳ bước nào trong deploy phase fail (kể cả những lỗi không lường trước), một bash `EXIT trap` sẽ tự động khôi phục image trước đó để service không bị chết.

---

## Kiến trúc Production

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
│  │  → :main     │  │ (API + Nginx)  │   │
│  │  → :sha      │  │                │   │
│  └──────────────┘  └────────────────┘   │
└─────────────────────────────────────────┘
       │                       │
       │ Docker Hub            │ SSH (appleboy/scp-action + ssh-action)
       ▼                       ▼
Docker Hub:                AWS Lightsail (Ubuntu 22.04)
anhtuan21112004/           52.77.218.100
menugreensystem:main       /home/ubuntu/apps/menugreen
                           │
                           ├─ Docker container: menugreen_api (port 5000)
                           ├─ Nginx (host, port 80/443) → proxy → 5000
                           │   └─ Source từ backend/nginx/ (deploy tự động)
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

## Services

| Service        | Location              | Port    | Notes                                                                              |
|----------------|-----------------------|---------|------------------------------------------------------------------------------------|
| **API**        | Docker container      | 5000    | `menugreen_api`, image từ Docker Hub `:main`                                       |
| **Nginx**      | Host (Ubuntu)         | 80, 443 | Reverse proxy + SSL + CORS. Config trong `/etc/nginx/`, deploy tự động qua CI/CD   |
| **PostgreSQL** | AWS RDS               | 5432    | Bên ngoài Lightsail, security group allow IP Lightsail                             |
| **Redis**      | Managed (AWS)         | 6379    | Connection string ghép từ `REDIS_HOST`+`REDIS_PORT`+`REDIS_PASSWORD` trong Doppler  |

---

## App directory trên server

```
/home/ubuntu/apps/menugreen/
├── .env                              # Tạo tự động bởi CD từ Doppler secrets
├── docker-compose.prod.yml           # Copy từ repo bởi CD workflow
└── (không cần clone repo trên server — CD tự quản lý image)

/etc/nginx/                          # Nginx trên host (KHÔNG trong Docker)
├── nginx.conf                        # Source: backend/nginx/nginx.conf (apply qua CI/CD)
├── conf.d/
│   ├── cors-map.conf                 # Source: backend/nginx/conf.d/cors-map.conf
│   └── *.bak.YYYYMMDD_HHMMSS        # Auto backup mỗi lần apply
└── ssl/                              # SSL certs (Let's Encrypt)
```

> **Lưu ý:** Server **KHÔNG cần clone repo**. CD workflow SCP `docker-compose.prod.yml` + nginx files rồi SSH vào apply.

---

## CI/CD Workflows

| File             | Mục đích                              | Trigger                  |
|------------------|---------------------------------------|--------------------------|
| `backend-ci.yml` | Build + Test + Push Docker image      | Push/PR vào `main`       |
| `backend-cd.yml` | Deploy lên Lightsail (API + Nginx)    | Sau CI pass + manual     |

### Trigger deploy

- **Tự động:** CI pass trên nhánh `main` → CD trigger qua `workflow_run`.
- **Manual:** Workflow Dispatch với option `production` / `staging`.
- **Skip:** Commit message chứa `#skipdeploy`.

Chi tiết pipeline: xem [CI_CD.md](./CI_CD.md).

---

## GitHub Secrets (bắt buộc)

| Secret                | Giá trị                              | Ghi chú                                  |
|-----------------------|--------------------------------------|------------------------------------------|
| `DOPPLER_TOKEN`       | `dp.prd.xxx...`                      | Service token Doppler config `prd`       |
| `LIGHTSAIL_HOST`      | `52.77.218.100`                      | IP server                                |
| `LIGHTSAIL_USER`      | `ubuntu`                             | SSH username                             |
| `LIGHTSAIL_SSH_KEY`   | (paste nội dung file `.pem`)         | Toàn bộ file, bao gồm `BEGIN`/`END`      |
| `DOCKERHUB_USERNAME`  | `anhtuan21112004`                    | Docker Hub account                       |
| `DOCKERHUB_TOKEN`     | (Docker Hub access token)            | Read + Write để push image               |

Vào **GitHub** → Repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

> **Lưu ý:** `LIGHTSAIL_*` secrets **chỉ ở GitHub Secrets**, KHÔNG đặt trong Doppler — CD script skip key `LIGHTSAIL_SSH_KEY=` khi build `.env` để tránh inject private key vào container.

### Doppler secrets (config `prd`) — tổng quan

App đọc các biến từ Doppler, CD script build `.env` theo format .NET (`Foo__Bar=value`):

| Secret                                              | Mục đích                                  |
|-----------------------------------------------------|-------------------------------------------|
| `CONNECTIONSTRINGS__DEFAULTCONNECTION`              | Full connection string PostgreSQL         |
| `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`        | Redis → ghép thành `REDIS_URL`            |
| `JWT_SECRET`, `JWT_ISSUER`, `JWT_AUDIENCE`          | JWT config                                |
| `JWTSETTINGS__SECRETKEY` (alternative)              | Alternative JWT secret key                |
| `ALLOWEDORIGINS`                                    | Domain CORS cho .NET fallback             |
| `RESEND__*`                                         | Email service (Resend)                    |
| `SEPAY__*`                                          | Payment gateway (SePay VN)                |
| `FIREBASE__CREDENTIALPATH`                          | Firebase FCM credential path              |
| `CVSERVICE__*`                                      | Computer Vision microservice              |
| `NUTRITIONASSISTANT__WORKERURL`                     | Nutrition AI worker URL                   |
| `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_SSL_MODE` | RDS info (cho backup script) |

Chi tiết từng secret: xem [SECRETS_MANAGEMENT.md](./SECRETS_MANAGEMENT.md).

---

## Server Information

| Property           | Value                                                       |
|--------------------|-------------------------------------------------------------|
| **Provider**       | AWS Lightsail                                               |
| **Plan**           | Small ($10/mo) — 2GB RAM                                    |
| **Public IP**      | `52.77.218.100`                                             |
| **OS**             | Ubuntu 22.04 LTS                                            |
| **Domain**         | `https://api.menugreen.food`                                |
| **App directory**  | `/home/ubuntu/apps/menugreen`                               |
| **Container**      | `menugreen_api` (port 5000)                                 |
| **Docker Image**   | `docker.io/anhtuan21112004/menugreensystem:main`            |
| **API Port**       | 5000 (chỉ internal)                                         |
| **Database**       | AWS RDS PostgreSQL                                          |
| **Redis**          | Managed (kết nối qua `REDIS_URL`)                          |
| **Nginx**          | Trên host (`/etc/nginx/`)                                   |
| **SSL**            | Let's Encrypt (auto-renew)                                  |

---

## Docker Compose Production

`docker-compose.prod.yml` nằm **trong repo** (`MenuGreenSystem/docker-compose.prod.yml`) và được CD workflow SCP lên server mỗi lần deploy (cùng với nginx files). KHÔNG còn dùng base64-embed.

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
      - GIT_SHA=${GIT_SHA:-manual}   # injected by CD để log commit SHA đang chạy
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

> **Lưu ý:** Compose này **CHỈ** có service `api` — không có Redis (Redis là managed, connection string từ `REDIS_URL` env).

---

## Redis Configuration

- **Loại:** Managed (AWS ElastiCache hoặc Upstash), connection string dạng `host:port,password=xxx`
- **Config:** CD ghép `REDIS_HOST` + `REDIS_PORT` + `REDIS_PASSWORD` từ Doppler thành biến `REDIS_URL=...` trong `.env`.
- **Trong code:** `Program.cs` đọc `Redis:ConnectionString` → fallback `REDIS_URL` env.

---

## Rollback & Fail-safe (cập nhật 2026-07-12)

CD workflow có **3 lớp bảo vệ** để đảm bảo service không chết khi deploy fail:

### 1. Nginx fail → restore + abort (zero downtime)
Nếu `nginx -t` fail sau khi copy config mới → restore `.bak.YYYYMMDD_HHMMSS` → `exit 1`. Container cũ chưa bị restart.

### 2. Health check fail → auto rollback image cũ
Nếu `curl /health/ready` fail 30 lần (60s) sau khi `docker compose up`:
1. Stop container mới
2. Chọn rollback image theo thứ tự ưu tiên:
   - **Tier 1:** Local tag `menugreen_api:rollback-local-<timestamp>` (snapshot ngay trước deploy, **không cần Docker Hub**)
   - **Tier 2:** Hub tag `:previous` (legacy fallback)
   - **Tier 3:** Hub tag `:main-<oldsha>` (pull lại nếu cần)
3. Re-fetch Doppler secrets + rebuild `.env`
4. Tag + `docker compose up -d` lại với image cũ
5. Verify với `/health/live`
6. `exit 1` để workflow fail, operator nhận alert

### 3. EXIT trap fail-safe (mới thêm 2026-07-12)
Nếu **bất kỳ** lệnh nào fail trong deploy phase (kể cả lỗi không lường trước như `docker compose up` crash, `set -e` exit giữa chừng, v.v.) → bash `EXIT trap` tự gọi `perform_rollback()` với cùng logic 3-tier. Guard `DEPLOY_PHASE_STARTED=1` đảm bảo trap chỉ trigger SAU khi container cũ có khả năng đã bị stop (tránh rollback khi backup DB fail).

Chi tiết: xem [CI_CD.md](./CI_CD.md#rollback--fail-safe).

---

## Local Development

Cho dev local, dùng `MenuGreenSystem/backend/docker-compose.yml`:

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

Doppler CLI để inject secrets ở local: xem [SECRETS_MANAGEMENT.md](./SECRETS_MANAGEMENT.md#dùng-doppler-cho-local-development).

---

## Lưu ý quan trọng

- **Không commit** `.env` vào git (đã có `.gitignore`).
- **PostgreSQL KHÔNG chạy trong Docker production** (dùng RDS).
- **Redis KHÔNG chạy trong Docker production** (managed).
- **Nginx KHÔNG nằm trong Docker Image** — nó chạy trên host, source config trong `backend/nginx/`. Khi sửa nginx chỉ cần `git push` → CI/CD tự SCP + apply (5-8 phút, không cần build lại Docker image).
- **Server KHÔNG cần clone repo** — GitHub Actions runner (cloud) làm trung gian.
- **CI/CD tự động deploy khi push lên `main`**.
- **`docker-compose.prod.yml` là file trong repo**, được SCP lên server mỗi lần deploy (cùng với nginx files).
- **App tự chạy EF Core migration khi startup** (không cần efbundle bên ngoài container).
- **Auto-rollback** nếu health check fail 30 lần (~60s) + **EXIT trap fail-safe** cho mọi lỗi không lường trước.

---

## Tài liệu liên quan

- [CI_CD.md](./CI_CD.md) — Chi tiết về CI/CD pipeline + rollback flow
- [NGINX_AND_CORS.md](./NGINX_AND_CORS.md) — CORS & Nginx config
- [SECRETS_MANAGEMENT.md](./SECRETS_MANAGEMENT.md) — Quản lý secrets qua Doppler
- [SERVER_SETUP.md](./SERVER_SETUP.md) — Hướng dẫn setup server từ đầu
