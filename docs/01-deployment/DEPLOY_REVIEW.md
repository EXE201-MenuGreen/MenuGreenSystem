# MenuGreen Deployment - Review & Gap Analysis ✅ DONE

> **Last updated:** 2026-07-11 — Tất cả gaps đã được fix.

---

## Tổng quan

Review ban đầu phát hiện nhiều gaps giữa plan và code thực tế. **Tất cả gaps đã được fix và verify.** File này giữ làm lịch sử.

---

## 1. Current State Analysis (Code thực tế)

### 1.1 CI/CD ✅ UPDATED

**Trước fix:**
- Workflow: `ci-cd.yml` (cũ, chạy efbundle)
- Migration: `docker compose exec api dotnet ef database update ...` (FAIL vì container không có SDK)

**Sau fix:**
- ✅ Workflow: `backend-ci.yml` + `backend-cd.yml` (tách CI/CD)
- ✅ Migration: **app auto-migrate khi startup**, không cần efbundle
- ✅ Doppler secrets → build `.env` tự động
- ✅ Backup RDS trước khi deploy
- ✅ Auto-rollback nếu health check fail

### 1.2 `docker-compose.prod.yml` ✅

**Cấu hình hiện tại (embedded base64 trong `backend-cd.yml`):**
- ✅ Redis: KHÔNG còn trong compose (chuyển sang managed service, dùng `REDIS_URL` env)
- ✅ API: memory limit 800M, cpus 1.0
- ✅ Health check: `curl /health/live`
- ✅ Network: `menugreen-net` (external)
- ✅ Image: `docker.io/anhtuan21112004/menugreensystem:latest`

### 1.3 `Dockerfile` ✅

- ✅ Multi-stage build (sdk → publish → aspnet)
- ✅ Không có migration bundle trong image
- ✅ curl cài cho healthcheck
- ✅ Image size ~200-300MB

### 1.4 `Program.cs` ✅ ALL FIXED

**Fix 1: Redis Connection String Mismatch ✅ DONE**

```csharp
// Line 45-47 — Program.cs:
var redisConnection =
    builder.Configuration["Redis:ConnectionString"]
    ?? Environment.GetEnvironmentVariable("REDIS_URL");
```

CD workflow giờ ghép `REDIS_HOST` + `REDIS_PORT` + `REDIS_PASSWORD` thành `REDIS_URL` env trong `.env`. Redis connection thật sự hoạt động.

**Fix 2: JWT Secret Fallback ✅ DONE**

```csharp
// Line 165-169 — Program.cs:
var secretKey = builder.Configuration["JwtSettings:SecretKey"];
if (string.IsNullOrEmpty(secretKey))
{
    throw new InvalidOperationException("JwtSettings:SecretKey is not configured.");
}
```

Đã bỏ hardcoded fallback, throw error rõ ràng nếu thiếu.

**Fix 3: Health Checks ✅**

- `/health` - tất cả checks
- `/health/ready` - chỉ ready tags
- `/health/live` - always healthy

### 1.5 `scripts/deploy.sh` (deprecated)

CD workflow đã thay thế chức năng của script này. Giữ lại trong repo làm fallback (chưa dùng).

---

## 2. So sánh Plan vs Reality (CẬP NHẬT)

| Điểm                          | Plan đề xuất                      | Code hiện tại                          | Trạng thái |
|------------------------------|-----------------------------------|----------------------------------------|------------|
| Migration                    | efbundle chạy trên host           | **App auto-migrate on startup**        | ✅ OK (đổi approach, đơn giản hơn) |
| Dockerfile                   | Tối giản, không SDK               | Multi-stage, không SDK                  | ✅ OK      |
| Redis connection             | `ConnectionStrings:Redis`          | `Redis:ConnectionString` + `REDIS_URL` env | ✅ OK (ghép REDIS_URL từ Doppler) |
| Health check                 | `/health/live` + `/health/ready`   | 3 endpoints đầy đủ                     | ✅ OK      |
| Memory limits                | Redis 256M, API 800M              | **API 800M only** (Redis managed)      | ✅ OK      |
| Config validation            | Verify .env sau upload            | Doppler secrets + auto-build .env      | ✅ OK      |
| Pre-flight check             | Script kiểm tra server            | `scripts/server_preflight_check.sh`    | ✅ OK      |
| Auto-rollback                | (chưa có trong plan)               | Auto-rollback nếu health fail          | ✅ BONUS   |
| DB backup trước deploy       | (chưa có trong plan)               | `pg_dump` tự động                      | ✅ BONUS   |

---

## 3. Critical Fixes — TẤT CẢ ĐÃ XONG ✅

### Fix 1: Redis Connection String Mismatch ✅

**Vấn đề trước:** CI tạo `ConnectionStrings__Redis` nhưng Program.cs đọc `Redis:ConnectionString`.

**Giải pháp đã áp dụng:** CD workflow giờ ghép `REDIS_HOST` + `REDIS_PORT` + `REDIS_PASSWORD` thành `REDIS_URL` env. Program.cs đọc đúng.

### Fix 2: Migration Strategy ✅

**Vấn đề trước:** Migration chạy trong container không có SDK.

**Giải pháp đã áp dụng:** Bỏ efbundle. App tự migrate khi startup (qua `Migrate()` trong code).

### Fix 3: Memory Limit cho API ✅

`docker-compose.prod.yml` (embedded) có `memory: 800M` cho API.

### Fix 4: Health Check Strategy ✅

CD workflow check `/health/ready` với 30 retries × 2s = 60s timeout. Auto-rollback nếu fail.

### Fix 5: JWT Secret Fallback ✅

Đã bỏ hardcoded fallback, throw error rõ ràng.

---

## 4. Plan Optimization — ĐÃ ÁP DỤNG ✅

### Những gì đã tốt, giữ nguyên:
- ✅ Dockerfile multi-stage
- ✅ Health check endpoints
- ✅ Doppler integration
- ✅ Auto-rollback mechanism

### Những gì đã cập nhật trong plan:
- ✅ Bỏ phần Dockerfile (đã tối ưu sẵn)
- ✅ Cập nhật Program.cs (Redis fallback, JWT throw)
- ✅ Thay đổi migration strategy (app auto-migrate)
- ✅ Thêm memory limit cho API trong compose
- ✅ Cải thiện health check trong CI (30 retries + auto-rollback)
- ✅ Thêm pre-flight script vào repo
- ✅ Fix JWT secret (bỏ fallback)
- ✅ BONUS: Auto-rollback nếu deploy fail
- ✅ BONUS: DB backup trước khi deploy

---

## 5. Execution Order — ĐÃ HOÀN THÀNH ✅

```
IMMEDIATE FIXES ✅
├── 1. Fix Redis connection trong Program.cs ✅
├── 2. Fix JWT secret (bỏ fallback) ✅
├── 3. Thêm mem_limit cho API trong docker-compose.prod.yml ✅
└── 4. Cải thiện health check trong CI ✅

SERVER PREPARATION ✅
├── 5. Provision Lightsail $10/tháng ✅
├── 6. Chạy server_preflight_check.sh ✅
├── 7. Cài Docker + Compose ✅
├── 8. Tạo network menugreen-net ✅
├── 9. Config Firewall (22, 80, 443) ✅
└── 10. Cài Nginx + Certbot ✅

CI/CD UPDATE ✅
├── 11. Tách backend-ci.yml + backend-cd.yml ✅
├── 12. Cập nhật migration strategy (auto-migrate) ✅
├── 13. Thêm Doppler secrets flow ✅
├── 14. Thêm DB backup step ✅
├── 15. Thêm auto-rollback mechanism ✅
└── 16. Push lên main ✅

FIRST DEPLOY ✅
├── 17. CI tự deploy ✅
├── 18. Containers + logs OK ✅
├── 19. Health endpoints pass ✅
└── 20. API live tại api.menugreen.food ✅
```

---

## 6. Conclusion

**Tất cả gaps đã được fix. Deploy hiện tại ổn định:**

- ✅ Dockerfile: multi-stage, tối ưu
- ✅ Redis: managed service, connection từ Doppler
- ✅ Doppler integration: tự động build .env
- ✅ Migration: app auto-migrate on startup
- ✅ API memory: 800MB (vừa đủ cho 2GB server)
- ✅ Health check: `/health/ready` với auto-rollback
- ✅ DB backup: tự động trước deploy
- ✅ JWT: throw nếu thiếu secret

**Workflow hiện tại:**
1. Developer push code lên `main`
2. `backend-ci.yml` build + push Docker image
3. `backend-cd.yml` SSH vào Lightsail, download Doppler secrets, backup DB, deploy image mới
4. Health check pass → deploy success
5. Health check fail → auto-rollback

---

## 7. Files liên quan (đã cập nhật)

| File | Thay đổi |
|------|----------|
| [DEPLOY.md](./DEPLOY.md) | Cập nhật cho khớp workflow mới |
| [lightsail-setup.md](./lightsail-setup.md) | Cập nhật cho server hiện tại |
| [CI_CD.md](./CI_CD.md) | Đổi từ `ci-cd.yml` sang `backend-ci.yml` + `backend-cd.yml` |
| [cors-config.md](./cors-config.md) | Cập nhật CORS qua nginx + Program.cs |
| [DOPPLER_SETUP.md](./DOPPLER_SETUP.md) | Cập nhật workflow đúng |
| [DEPLOY_FIX_PLAN.md](./DEPLOY_FIX_PLAN.md) | Đánh dấu tất cả fix DONE |

---

*Last updated: 2026-07-11 — All gaps fixed and deployed.*
