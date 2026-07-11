# MenuGreen — Deployment Documentation

> **Cập nhật lần cuối:** 2026-07-11

Tài liệu về việc deploy backend MenuGreen API lên AWS Lightsail.

---

## 📋 Mục lục

Đọc theo thứ tự nếu bạn mới:

| # | File                                  | Mục đích                              | Đối tượng              |
|---|---------------------------------------|---------------------------------------|------------------------|
| 1 | [DEPLOY.md](./DEPLOY.md)              | Tổng quan deployment, kiến trúc        | Tất cả                  |
| 2 | [lightsail-setup.md](./lightsail-setup.md) | Setup server từ đầu (tạo VM, cài Docker, Nginx) | DevOps mới             |
| 3 | [DOPPLER_SETUP.md](./DOPPLER_SETUP.md)| Quản lý secrets qua Doppler          | DevOps                  |
| 4 | [CI_CD.md](./CI_CD.md)                | Chi tiết CI/CD pipeline               | DevOps                  |
| 5 | [cors-config.md](./cors-config.md)    | CORS & Nginx config                   | Backend Dev + DevOps    |

Tài liệu lịch sử (đã hoàn thành):

| File                                  | Mục đích                                   |
|---------------------------------------|--------------------------------------------|
| [DEPLOY_FIX_PLAN.md](./DEPLOY_FIX_PLAN.md) | Plan fix deploy ban đầu (đã xong ✅)    |
| [DEPLOY_REVIEW.md](./DEPLOY_REVIEW.md)    | Gap analysis giữa plan và code (đã xong ✅) |

---

## 🚀 Quick Start (cho người mới)

### Bạn muốn...

**Setup server mới từ đầu?**
→ Đọc [lightsail-setup.md](./lightsail-setup.md)

**Hiểu cách deploy tự động hoạt động?**
→ Đọc [DEPLOY.md](./DEPLOY.md) + [CI_CD.md](./CI_CD.md)

**Thêm domain vào CORS whitelist?**
→ Đọc [cors-config.md](./cors-config.md)

**Quản lý secrets (DB password, JWT, ...)?**
→ Đọc [DOPPLER_SETUP.md](./DOPPLER_SETUP.md)

**Trigger deploy thủ công?**
→ GitHub → Actions → `Backend CD - Deploy` → `Run workflow`

---

## 🏗️ Kiến trúc tổng quan

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
3. `backend-cd.yml`: SSH vào Lightsail, pull Doppler secrets, deploy
4. Health check pass → live. Fail → auto-rollback.

Xem chi tiết: [DEPLOY.md](./DEPLOY.md)

---

## 📍 Thông tin server hiện tại

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

## 🔗 Files liên quan ngoài folder này

| File                                                       | Mục đích                      |
|------------------------------------------------------------|-------------------------------|
| [`../GITHUB_SECRETS_SETUP.md`](../GITHUB_SECRETS_SETUP.md) | Setup GitHub Secrets chi tiết |
| [`../../backend/nginx/deploy/README.md`](../../backend/nginx/deploy/README.md) | Nginx deployment workflow |
| [`../../.github/workflows/backend-ci.yml`](../../.github/workflows/backend-ci.yml) | CI workflow (build image) |
| [`../../.github/workflows/backend-cd.yml`](../../.github/workflows/backend-cd.yml) | CD workflow (deploy) |

---

## 📝 Thay đổi gần đây

- **2026-07-11:** Cập nhật toàn bộ docs cho khớp với workflow thật (backend-ci/cd, auto-migrate, managed Redis, nginx trên host).
- **2026-07-01:** Fix Doppler secrets flow, JWT throw, Redis connection string.
- **2026-06-30:** Import secrets vào Doppler config `prd`.

---

*Last updated: 2026-07-11*
