# MenuGreen System - Architecture Overview

> **Last updated:** 2026-07-11 — Phản ánh đúng trạng thái hiện tại của hệ thống.

---

## Mục tiêu

- Deploy backend .NET API lên **AWS Lightsail Ubuntu** sử dụng **GitHub Actions CI/CD**.
- **PostgreSQL** chạy trên **AWS RDS** (bên ngoài server).
- **Redis** chạy trên **AWS** (ElastiCache hoặc managed) — không phải Docker container local.
- API chạy trong **Docker container** duy nhất (`menugreen_api`).
- Nginx chạy **trong Docker** local (`docker-compose.yml`) cho dev — production dùng **Nginx trên host** (đã cài ở `/etc/nginx/`) và được **deploy tự động qua CI/CD** từ source trong git.
- **Tự động hóa hoàn toàn**: push code lên `main` → CI/CD tự deploy (cả API + Nginx config).

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
│  └──────────────┘  │ (API + Nginx)  │   │
│                    └────────────────┘   │
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

| Service       | Location              | Port | Notes                                                          |
|---------------|-----------------------|------|----------------------------------------------------------------|
| **API**       | Docker container      | 5000 | `menugreen_api`, image từ Docker Hub                           |
| **Nginx**     | Host (Ubuntu)         | 80, 443 | Reverse proxy + SSL termination + CORS. Config trong `/etc/nginx/` |
| **PostgreSQL** | AWS RDS             | 5432 | Bên ngoài, security group allow IP Lightsail                  |
| **Redis**     | Managed (AWS/Doppler) | 6379 | Connection string từ `REDIS_URL` env, không phải Docker local |

---

## App directory trên server

```
/home/ubuntu/apps/menugreen/
├── .env                              # Tạo tự động bởi CI/CD từ Doppler
├── docker-compose.prod.yml           # Base64 embedded trong workflow (NO REDIS)
└── (không cần clone repo trên server — CD tự quản lý image)

/etc/nginx/                          # Nginx trên host (KHÔNG trong Docker)
├── nginx.conf                        # Source: backend/nginx/nginx.conf (apply qua CI/CD)
├── conf.d/
│   ├── cors-map.conf                 # Source: backend/nginx/conf.d/cors-map.conf
│   └── *.bak.YYYYMMDD_HHMMSS        # Auto backup mỗi lần apply
└── ssl/                              # SSL certs (Let's Encrypt)
```

> **Lưu ý:** Server **KHÔNG cần clone repo**. Image pull thẳng từ Docker Hub. CD workflow tự tạo `.env` từ Doppler VÀ tự apply nginx config từ source trong git.

---

## CI/CD Workflows

| File                        | Mục đích                                     | Trigger                  |
|-----------------------------|----------------------------------------------|--------------------------|
| `backend-ci.yml`            | Build + Test + Push Docker image             | Push/PR vào `main`       |
| `backend-cd.yml`            | Deploy lên AWS Lightsail (API + Nginx)       | Sau khi CI pass + manual |

Chi tiết pipeline: xem [CI_CD.md](./CI_CD.md).

### Trigger deploy

- **Tự động:** CI pass trên nhánh `main` → CD trigger
- **Manual:** Workflow Dispatch với 2 option `production` / `staging`
- **Skip:** Commit message chứa `#skipdeploy`

---

## GitHub Secrets (bắt buộc)

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

Chi tiết xem: [SECRETS_MANAGEMENT.md](./SECRETS_MANAGEMENT.md)

---

## Server Information

| Property           | Value                                                       |
|--------------------|-------------------------------------------------------------|
| **Provider**       | AWS Lightsail                                               |
| **Plan**           | Small ($10/mo) - 2GB RAM                                    |
| **Public IP**      | `52.77.218.100`                                             |
| **OS**             | Ubuntu 22.04 LTS                                            |
| **Domain**         | `https://api.menugreen.food`                                |
| **App directory**  | `/home/ubuntu/apps/menugreen`                               |
| **Container**      | `menugreen_api` (port 5000)                                 |
| **Docker Image**   | `docker.io/anhtuan21112004/menugreensystem:main`            |
| **API Port**       | 5000 (chỉ internal)                                         |
| **Database**       | AWS RDS PostgreSQL                                          |
| **Redis**          | Managed (kết nối qua REDIS_URL)                             |
| **Nginx**          | Trên host (`/etc/nginx/`)                                   |
| **SSL**            | Let's Encrypt (auto-renew)                                  |

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
- **Nginx KHÔNG nằm trong Docker Image** — nó chạy trên host, source config trong `backend/nginx/`. Khi sửa nginx chỉ cần `git push` → CI/CD tự SCP + apply (5-8 phút, không cần build lại Docker image).
- **Server KHÔNG cần clone repo** — GitHub Actions runner (cloud) làm trung gian.
- **CI/CD tự động deploy khi push lên `main`**. Nhánh `Tuan` đã bỏ.
- **`docker-compose.prod.yml` được nhúng base64 trong workflow**, không cần file riêng trong repo.
- **App tự chạy migration khi startup** (không cần efbundle bên ngoài).
- **Auto-rollback** nếu health check fail 30 lần (~60s).

---

## Tài liệu liên quan

- [CI_CD.md](./CI_CD.md) — Chi tiết về CI/CD pipeline (13 bước deploy)
- [NGINX_AND_CORS.md](./NGINX_AND_CORS.md) — CORS & Nginx config
- [SECRETS_MANAGEMENT.md](./SECRETS_MANAGEMENT.md) — Quản lý secrets qua Doppler
- [SERVER_SETUP.md](./SERVER_SETUP.md) — Hướng dẫn setup server từ đầu