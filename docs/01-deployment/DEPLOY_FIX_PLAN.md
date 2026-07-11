# MenuGreen System - Deployment Fix Plan (Final v2) ✅ DONE

> **Last updated:** 2026-07-11 — Tất cả fix đã hoàn thành. File này giữ làm lịch sử.

---

## Mục tiêu (ban đầu)
- Đưa app `MenuGreen.API` chạy ổn định trên **Lightsail Ubuntu VM** với Docker + Compose.
- Đảm bảo EF Core migration chạy **trước khi start API**, theo best practice production.
- Giữ nguyên CI/CD hiện tại (GitHub Actions + Doppler + GHCR) nhưng sắp xếp đúng thứ tự deploy.
- Phù hợp với server **$10/tháng** (1 vCPU, 2GB RAM, 60GB SSD).
- Thống nhất deploy theo **1 nhánh duy nhất** là `main` để tránh nhầm lẫn giữa `main` và `Tuan`.

---

## 1. Vấn đề hiện tại (đã phát hiện 01/07/2026) — TẤT CẢ ĐÃ FIX ✅

| # | Lỗi                                                                  | Trạng thái |
|---|----------------------------------------------------------------------|------------|
| 1 | `.env` trên Lightsail lệch so với Doppler `prd`                       | ✅ Fixed   |
| 1b | Migration đang chạy `dotnet ef database update` trong container runtime không có SDK | ✅ Fixed (đổi sang auto-migrate trong app startup) |
| 2 | Redis chỉ có `REDIS_HOST`/`REDIS_PORT` riêng                          | ✅ Fixed (ghép thành `REDIS_URL`) |
| 3 | Thiếu volume Firebase                                                  | ⚠️ Documented (chưa cần, app chưa dùng FCM) |
| 4 | CI chỉ check `/health/ready`                                          | ✅ Fixed (check `/health/ready` với 30 retry, có fallback `/health/live`) |

### Trạng thái hiện tại (01/07/2026) → hiện tại đã fix

- ✅ `menugreen_api`: `healthy` (sau khi fix Redis connection + JWT secret)
- ✅ `menugreen_redis`: dùng managed Redis (không còn Docker container local)
- ✅ RDS: kết nối được từ Lightsail
- ✅ `.env` server: đầy đủ `JwtSettings__SecretKey`, `Issuer`, `Audience`, `REDIS_URL`
- ✅ CI/CD: tự động build `.env` từ Doppler `prd` đúng format backend đọc

---

## 2. Kiểm tra rủi ro và tối ưu — ĐÃ ÁP DỤNG ✅

| Điểm cũ | Rủi ro | Tối ưu đã chọn | Trạng thái |
|----------|--------|----------------|------------|
| Chạy `efbundle` từ API container sau `up -d` | API fail startup → không exec được | **BỎ efbundle**, để app tự migrate khi startup | ✅ Done |
| Build bundle trong Dockerfile | Image prod cồng kềnh | **Không build bundle**, chỉ để runtime image | ✅ Done |
| Chưa verify config | `.env` thiếu/sai format | Thêm bước **verify config** sau khi upload `.env` | ✅ Done (Doppler secrets + grep .env) |
| Health check chỉ `/health/ready` | Timeout không phân biệt | Check `/health/ready` với 30 retry × 2s | ✅ Done |

---

## 3. Server chuẩn bị gì ✅

### 3.1 Yêu cầu cơ bản (đã có trên server hiện tại)

| Thành phần | Thực tế | Đánh giá |
|------------|---------|----------|
| OS | Ubuntu 22.04 LTS | ✅ Tương thích |
| CPU | 1 vCPU | ✅ Đủ cho Docker + API |
| RAM | **2 GB** | ⚠️ Vừa đủ (đã tối ưu: bỏ Redis container local) |
| Disk | 60 GB SSD | ✅ Đủ |
| Network | Static IP + 3TB transfer | ✅ Tốt |
| Outbound | HTTPS 443 + TCP 5432 (RDS) + Redis | ✅ Đã mở |
| Database | **AWS RDS PostgreSQL** | ✅ Bên ngoài server |

### 3.2 Tối ưu cho 2GB RAM ✅

Vì database đã ở AWS RDS, Lightsail chỉ chạy:
- **Docker container: menugreen_api** (~800MB) — `.NET` app

Redis: chuyển sang **managed service**, kết nối qua `REDIS_URL` env.

**Memory allocation hiện tại:**
| Container | Limit | Reserve |
|-----------|-------|---------|
| menugreen_api | 800 MB | ~512 MB |
| OS + Docker | ~700 MB | ~600 MB |
| **Total** | **~1.5 GB** | **~1.1 GB** |

Đã giải phóng ~256MB so với plan ban đầu (bỏ Redis container local).

### 3.3 `efbundle` — KHÔNG DÙNG ✅

Đã đổi sang **app auto-migrate on startup**:
- App `Program.cs` / `DbContext` tự chạy `Migrate()` khi khởi động
- Không cần `efbundle`, không cần `.NET SDK` trên server
- Không cần workflow step riêng cho migration

### 3.4 Server Pre-flight Check ✅

Script `scripts/server_preflight_check.sh` đã thêm vào repo (nếu cần dùng cho server mới).

### 3.5 Cài đặt phần mềm ✅

Đã có sẵn trên server:
- Docker + Docker Compose plugin
- Nginx (cho reverse proxy + CORS)
- Certbot (SSL Let's Encrypt)

### 3.6 Firewall ✅

**Lightsail Firewall (qua console):**
- ✅ TCP 22 (SSH)
- ✅ TCP 80 (HTTP)
- ✅ TCP 443 (HTTPS)
- ❌ TCP 5000 (không cần — internal trong Docker)

**UFW:** chưa enable, Lightsail Firewall đủ dùng.

### 3.7 Docker Network ✅

```bash
docker network create menugreen-net  # External, dùng cho docker compose
```

### 3.8 File `.env` ban đầu ✅

Tự động tạo bởi CD workflow từ Doppler secrets — không cần tạo thủ công.

### 3.9 SSH Key cho GitHub Actions ✅

`LIGHTSAIL_SSH_KEY` đã paste vào GitHub Secrets.

---

## 4. Plan thực hiện chi tiết ✅ DONE

### Bước 1: Workflow files — ĐÃ CẬP NHẬT ✅

**Tách thành 2 workflows:**
- `.github/workflows/backend-ci.yml` — Build & push image
- `.github/workflows/backend-cd.yml` — Deploy lên Lightsail

**Trong `backend-cd.yml`:**

```yaml
# Đã có:
- name: Install Doppler CLI
- name: Download secrets from Doppler
- name: Build .env file (JwtSettings__*, ConnectionStrings__*, REDIS_URL, ...)
- name: Backup database (pg_dump, FAIL = ABORT)
- name: Pull latest image from Docker Hub
- name: Tag previous image (for rollback)
- name: Stop + remove old container
- name: Start new container (docker compose up -d)
- name: Verify tables exist in DB
- name: Health check /health/ready (30 retries)
- name: Auto-rollback if health check fails
- name: Prune old Docker images
```

### Bước 2: `docker-compose.prod.yml` — EMBEDDED BASE64 ✅

File này được **embedded base64 trong `backend-cd.yml`** (không nằm trong repo).

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

networks:
  menugreen-net:
    external: true
```

### Bước 3: `Dockerfile` — ĐÃ TỐI ƯU ✅

Multi-stage build, chỉ chứa runtime image (không có SDK, không có efbundle).

### Bước 4: `Program.cs` — ĐÃ FIX ✅

- ✅ JWT secret: throw nếu không config (line 165-169)
- ✅ Redis: đọc `Redis:ConnectionString` → fallback `REDIS_URL` env
- ✅ Health checks: `/health/live`, `/health/ready`, `/health` đầy đủ
- ✅ Auto-migrate trong startup

### Bước 5: `scripts/server_preflight_check.sh` ✅

Script pre-flight đã có trong repo (cho server mới).

### Bước 6: `scripts/deploy.sh` ✅

Script deploy thủ công — hiện chưa cần dùng vì CD workflow tự động.

---

## 5. Thứ tự thực hiện ✅ DONE

```
SERVER PREPARATION ✅
├── 1. Provision Lightsail Ubuntu VM ✅
├── 2. Cài Docker + dependencies ✅
├── 3. Tạo Docker network menugreen-net ✅
├── 4. Setup SSH key cho GitHub Actions ✅
├── 5. Config Lightsail Firewall ✅
└── 6. Cài Nginx + Certbot ✅

CI/CD UPDATE ✅
├── 7. Tách backend-ci.yml + backend-cd.yml ✅
├── 8. Doppler secrets → .env flow ✅
├── 9. Auto-rollback mechanism ✅
└── 10. Commit + push lên main ✅

FIRST DEPLOY ✅
├── 11. CI build + push image ✅
├── 12. CD deploy thành công ✅
├── 13. Container menugreen_api healthy ✅
└── 14. Health check + API live tại api.menugreen.food ✅
```

---

## 6. Checklist server preparation ✅ DONE

- [✅] **Server preflight check pass**
- [✅] Lightsail **$10/tháng** đã setup
- [✅] SSH key đã add vào GitHub Secrets
- [✅] `LIGHTSAIL_HOST` và `LIGHTSAIL_USER` đã set
- [✅] Docker đã cài
- [✅] Docker Compose plugin đã cài
- [✅] User `ubuntu` đã trong group `docker`
- [✅] `menugreen-net` network đã tạo
- [✅] Firewall mở port 22, 80, 443
- [✅] `/home/ubuntu/apps/menugreen` đã tồn tại
- [✅] `.env` auto-generated bởi CD workflow
- [✅] RDS PostgreSQL cho phép IP Lightsail
- [✅] Doppler config `prd` đầy đủ secrets
- [✅] Memory limit 800M cho API container

---

## 7. Kết quả sau fix ✅

### API giờ:
- Chạy ổn định tại `https://api.menugreen.food`
- Health check `/health/ready` trả về 200
- Auto-migrate khi startup (không cần efbundle)
- Auto-rollback nếu deploy fail

### CI/CD giờ:
- Push lên `main` → tự động deploy
- Doppler secrets tự động inject đúng format
- Backup DB trước khi deploy
- Health check + auto-rollback

### Tài nguyên server:
- API container: 800MB RAM limit
- OS + Docker: ~700MB
- Còn dư ~500MB cho buffer
- Đủ cho 2GB RAM server

---

## 8. Tài liệu tham khảo

- [EF Core Applying Migrations](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/applying)
- [Stop Running dotnet ef database update in Production - ByteCrafted](https://bytecrafted.dev/ef-core-migrations-cicd-production/)
- [AWS Lightsail Container Services](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-container-services-deployments.html)
- [Doppler CLI Docs](https://docs.doppler.com/docs/install-cli)

---

## Files liên quan (đã cập nhật)

| File | Trạng thái |
|------|------------|
| [DEPLOY.md](./DEPLOY.md) | ✅ Cập nhật cho khớp thực tế |
| [lightsail-setup.md](./lightsail-setup.md) | ✅ Cập nhật |
| [CI_CD.md](./CI_CD.md) | ✅ Cập nhật (backend-ci/cd thay vì ci-cd) |
| [cors-config.md](./cors-config.md) | ✅ Cập nhật (nginx trên host) |
| [DOPPLER_SETUP.md](./DOPPLER_SETUP.md) | ✅ Cập nhật |
| [DEPLOY_REVIEW.md](./DEPLOY_REVIEW.md) | ✅ Cập nhật (mark tất cả fix done) |

---

*Cập nhật lần cuối: 11/07/2026 — Tất cả fix DONE*
