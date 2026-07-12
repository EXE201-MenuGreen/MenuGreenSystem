# MenuGreen — Deployment Documentation

> **Cập nhật lần cuối:** 2026-07-12

Tài liệu về việc deploy backend MenuGreen API lên AWS Lightsail.

---

## Mục lục

Đọc theo thứ tự nếu bạn mới:

| # | File                                          | Mục đích                                                          | Đối tượng              |
|---|-----------------------------------------------|-------------------------------------------------------------------|------------------------|
| 1 | [ARCHITECTURE.md](./ARCHITECTURE.md)          | Kiến trúc tổng quan, GitHub Secrets, server info                 | Tất cả                  |
| 2 | [SERVER_SETUP.md](./SERVER_SETUP.md)          | Setup server từ đầu (tạo VM, cài Docker, Nginx)                  | DevOps mới             |
| 3 | [SECRETS_MANAGEMENT.md](./SECRETS_MANAGEMENT.md) | Quản lý secrets qua Doppler                                    | DevOps                  |
| 4 | [CI_CD.md](./CI_CD.md)                        | Chi tiết CI/CD pipeline (Phase A pre-flight + Phase B deploy với EXIT trap) | DevOps                  |
| 5 | [NGINX_AND_CORS.md](./NGINX_AND_CORS.md)      | CORS & Nginx config (deploy tự động qua CI/CD)                   | Backend Dev + DevOps    |

---

## Quick Start (cho người mới)

### Bạn muốn...

**Setup server mới từ đầu?**
→ Đọc [SERVER_SETUP.md](./SERVER_SETUP.md)

**Hiểu kiến trúc hệ thống + các services?**
→ Đọc [ARCHITECTURE.md](./ARCHITECTURE.md)

**Hiểu cách deploy tự động hoạt động?**
→ Đọc [CI_CD.md](./CI_CD.md)

**Thêm domain vào CORS whitelist?**
→ Đọc [NGINX_AND_CORS.md](./NGINX_AND_CORS.md)

**Quản lý secrets (DB password, JWT, ...)?**
→ Đọc [SECRETS_MANAGEMENT.md](./SECRETS_MANAGEMENT.md)

**Trigger deploy thủ công?**
→ GitHub → Actions → `Backend CD - Deploy` → `Run workflow`

**Deploy fail / cần rollback?**
→ Xem [CI_CD.md#rollback--fail-safe](./CI_CD.md#rollback--fail-safe) — 3-tier local rollback + EXIT trap fail-safe

---

## Kiến trúc tổng quan

```
Internet
   ↓
[Nginx trên host:443]  ← SSL + CORS + rate limit
   ↓
[Docker: menugreen_api:5000]  ← .NET API
   ↓                            ↓
[AWS RDS PostgreSQL]    [Managed Redis]
```

**Workflow:**
1. Dev push code lên `main`
2. `backend-ci.yml`: build + push Docker image lên Docker Hub
3. `backend-cd.yml`: SCP nginx files + SSH vào Lightsail, pull Doppler secrets, deploy
4. Health check pass → live. Fail → auto-rollback.

Xem chi tiết: [ARCHITECTURE.md](./ARCHITECTURE.md) + [CI_CD.md](./CI_CD.md)

---

## Thông tin server hiện tại

| Property          | Value                              |
|-------------------|------------------------------------|
| **Provider**      | AWS Lightsail                      |
| **Plan**          | Small ($10/mo) - 2GB RAM           |
| **Public IP**     | `52.77.218.100`                    |
| **Domain**        | `https://api.menugreen.food`       |
| **App directory** | `/home/ubuntu/apps/menugreen`      |
| **Container**     | `menugreen_api` (port 5000)        |
| **Database**      | AWS RDS PostgreSQL                 |
| **Redis**         | Managed (kết nối qua REDIS_URL)    |
| **Nginx**         | Trên host (`/etc/nginx/`)          |
| **SSL**           | Let's Encrypt (auto-renew)         |

---

## Files liên quan ngoài folder này

| File                                                       | Mục đích                      |
|------------------------------------------------------------|-------------------------------|
| [`../GITHUB_SECRETS_SETUP.md`](../GITHUB_SECRETS_SETUP.md) | Setup GitHub Secrets chi tiết |
| [`../../backend/nginx/deploy/README.md`](../../backend/nginx/deploy/README.md) | Nginx deployment workflow |
| [`../../.github/workflows/backend-ci.yml`](../../.github/workflows/backend-ci.yml) | CI workflow (build image) |
| [`../../.github/workflows/backend-cd.yml`](../../.github/workflows/backend-cd.yml) | CD workflow (deploy) |

---

## Thay đổi gần đây

- **2026-07-12:** Cập nhật toàn bộ docs cho khớp với code thực tế:
  - **ARCHITECTURE.md / CI_CD.md:** Bỏ mô tả "base64-embed docker-compose.prod.yml" (file đã có sẵn trong repo). Bổ sung tài liệu về 3-tier local rollback tag và EXIT trap fail-safe.
  - **SECRETS_MANAGEMENT.md:** Bỏ `LIGHTSAIL_*` khỏi danh sách Doppler (chỉ ở GitHub Secrets). Bổ sung bảng mapping Doppler secret → .NET config key.
  - **NGINX_AND_CORS.md:** Sửa mapping env `ALLOWEDORIGINS` → `AllowedOrigins` cho khớp với `Program.cs`.
  - **SERVER_SETUP.md:** Bổ sung self-signed catch-all cert (CD tự generate) và Doppler CLI auto-install.
- **2026-07-11:** Tổ chức lại docs (8 → 6 file, archive removed). Merge DEPLOY.md + CI_CD.md overview thành ARCHITECTURE.md. Rename: cors-config → NGINX_AND_CORS, DOPPLER_SETUP → SECRETS_MANAGEMENT, lightsail-setup → SERVER_SETUP.
- **2026-07-11:** Cập nhật toàn bộ docs cho khớp với workflow thật (Nginx apply qua CI/CD, SCP + SSH, auto-migrate, managed Redis).
- **2026-07-01:** Fix Doppler secrets flow, JWT throw, Redis connection string.
- **2026-06-30:** Import secrets vào Doppler config `prd`.

---

*Last updated: 2026-07-12*