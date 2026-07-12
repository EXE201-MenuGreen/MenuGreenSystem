# Issues Encountered

Danh sách các issue đã gặp trong quá trình phát triển và deploy.

---

## [RESOLVED] PostgreSQL & Redis Health Check - Environment Variable Loading

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** High

### Description

Health check báo lỗi:

- PostgreSQL: `Format of the initialization string does not conform to specification starting at index 0.`
- Redis: `It was not possible to connect to the redis server(s).`

### Root Cause

Code đọc config từ `builder.Configuration` nhưng không load được environment variables đúng cách.

### Fix Applied

**1. Program.cs - Health Checks:**

```csharp
// TRƯỚC (sai)
.AddNpgSql(
    builder.Configuration["ConnectionStrings:DefaultConnection"]
    ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
    ?? throw new InvalidOperationException("..."))

// SAU (đúng)
var pgConnection = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");
if (string.IsNullOrEmpty(pgConnection))
    throw new InvalidOperationException("...");
builder.Services.AddHealthChecks()
    .AddNpgSql(pgConnection, name: "postgresql", ...);
```

**2. ConnectionStringHelper.cs:**

```csharp
// TRƯỚC (sai)
var configured = configuration.GetConnectionString("DefaultConnection");

// SAU (đúng)
var configured = configuration.GetConnectionString("DefaultConnection")
    ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
    ?? Environment.GetEnvironmentVariable("DATABASE_URL");
```

### Files Changed

- `backend/MenuGreen.API/Program.cs`
- `backend/MenuGreen.DataAccessLayer/ConnectionStringHelper.cs`

### Commit

```
f778bda - Fix environment variable loading for health checks
```

### Status

- [x] Code fixed và push lên git
- [ ] CI/CD build image mới
- [ ] Pull và restart container trên server
- [ ] Verify health check trả về Healthy

---

## [RESOLVED] Redis Health Check - Wrong Env Key Name

**Date:** 2026-07-01
**Status:** Resolved (solved cùng với issue trên)
**Severity:** High

### Description

Redis health check fail mặc dù network OK.

### Root Cause

Code health check đọc `REDIS_URL` nhưng env file set `Redis__ConnectionString`.

### Fix Applied

Đã fix trong Program.cs - đọc trực tiếp từ `Environment.GetEnvironmentVariable("REDIS_URL")`.

---

## [RESOLVED] CI/CD Not Building Docker Image for Tuan Branch

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** High

### Description

Health check vẫn fail sau khi code fix đã push. Image trên Docker Hub vẫn là version cũ.

### Root Cause

CI/CD workflow chỉ build Docker image khi push vào **main** branch:

```yaml
if: github.event_name == 'push' && github.ref == 'refs/heads/main'
```

Branch **Tuan** không trigger build Docker image.

### Fix Applied

```yaml
# Trước (chỉ main)
if: github.event_name == 'push' && github.ref == 'refs/heads/main'

# Sau (cả main và Tuan)
if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/Tuan')
```

### Files Changed

- `.github/workflows/ci-cd.yml`

### Commit

```
01723b5 - fix: build Docker image for Tuan branch too
```

### Status

- [x] CI/CD workflow fixed
- [ ] CI/CD build completes
- [ ] Pull new image on server
- [ ] Verify health check

---

## [RESOLVED] Duplicate Variable Name in Program.cs

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** High

### Description

CI/CD build failed với error: `error CS0128: A local variable or function named 'redisConnection' is already defined in this scope`

### Root Cause

Biến `redisConnection` đã được khai báo ở dòng 45 (Redis cache config), nhưng health checks lại khai báo lại cùng tên.

### Fix Applied

Đổi tên biến trong health checks thành `healthCheckRedisConnection`.

### Commit

```
e9fe08a - Fix duplicate variable name 'redisConnection' in Program.cs
```

---

## [RESOLVED] Environment Variable Loading for Health Checks

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** High

### Description

Health check báo lỗi connection string rỗng/invalid.

### Root Cause

Code đọc config từ `builder.Configuration` nhưng không load được environment variables đúng cách.

### Fix Applied

Đọc trực tiếp từ `Environment.GetEnvironmentVariable()`:

- `ConnectionStrings__DefaultConnection` cho PostgreSQL
- `REDIS_URL` cho Redis

### Commit

```
f778bda - Fix environment variable loading for health checks
```

---

## [RESOLVED] Redis Connection String Key Name

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** Medium

### Description

Redis health check fail vì key name không khớp.

### Root Cause

Code health check đọc `REDIS_URL` nhưng env file set `Redis__ConnectionString`.

---

## [RESOLVED] CI/CD YAML Syntax Error

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** Medium

### Description

GitHub Actions workflow failed với YAML syntax error.

### Root Cause

Indent không đồng nhất (2 vs 4 spaces).

---

## [RESOLVED] Docker Compose Volumes Format Error

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** Medium

### Description

Docker Compose validate failed: `services.api.volumes must be a array`

### Root Cause

Commented YAML blocks gây parse error.

---

## [RESOLVED] CORS Configuration - Backend + Nginx + Cloudflare

**Date:** 2026-07-05
**Status:** ✅ Resolved
**Severity:** High

### Description

Frontend website `https://www.menugreen.food` bị block CORS khi gọi API `https://api.menugreen.food`.

### Root Cause

Cần cấu hình CORS headers ở nhiều layer:
1. Backend (.NET) - đã config
2. Nginx (reverse proxy) - cần thêm headers
3. Cloudflare - đã cache response

### Fix Applied

**1. Backend Program.cs - Default origins:**

```csharp
var defaultOrigins = new[]
{
    "https://www.menugreen.food",
    "https://menugreen.food",
    "https://menu-green-system-ldw5frytu-johnny-dangs-projects.vercel.app",
    "http://localhost:3000",
    "http://localhost:3001"
};
```

**2. Nginx Config - CORS headers:**

```nginx
add_header 'Access-Control-Allow-Origin' 'https://www.menugreen.food' always;
add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, Accept, Origin, X-Requested-With' always;
add_header 'Access-Control-Allow-Credentials' 'true' always;
add_header 'Access-Control-Max-Age' '86400' always;
```

**3. Preflight OPTIONS handler:**

```nginx
if ($request_method = 'OPTIONS') {
    add_header 'Access-Control-Allow-Origin' 'https://www.menugreen.food' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, Accept, Origin, X-Requested-With' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    add_header 'Content-Type' 'text/plain; charset=utf-8';
    add_header 'Content-Length' 0;
    add_header 'Access-Control-Max-Age' 86400;
    return 204;
}
```

### Test Result

```bash
curl -I -X OPTIONS https://api.menugreen.food/api/Auth/login \
  -H "Origin: https://www.menugreen.food" \
  -H "Access-Control-Request-Method: POST"

# Response:
HTTP/2 204
access-control-allow-origin: https://www.menugreen.food
access-control-allow-methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
access-control-allow-headers: Content-Type, Authorization, Accept, Origin, X-Requested-With
access-control-allow-credentials: true
```

### Files Changed

- `backend/MenuGreen.API/Program.cs`
- `/etc/nginx/sites-available/api.menugreen.food` (server)

---


**Date:** 2026-07-01
**Status:** Resolved
**Severity:** Medium

### Description

GitHub Actions workflow failed với YAML syntax error ở line 168.

### Root Cause

Indent không đồng nhất - 2 dòng trong block `while` có indent 2 spaces thay vì 4 spaces.

### Fix Applied

```yaml
# Trước (sai)
while IFS='=' read -r key raw_value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  # Skip keys with invalid characters for .env
  [[ "$key" =~ [/[:space:]+] ]] && continue  # indent 2 spaces
  [[ "$key" =~ ^(...) ]] && continue

# Sau (đúng)
while IFS='=' read -r key raw_value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  # Skip keys with invalid characters for .env
  [[ "$key" =~ [/[:space:]+] ]] && continue  # indent 4 spaces
  [[ "$key" =~ ^(...) ]] && continue
```

### Files Changed

- `.github/workflows/ci-cd.yml`

---

## [RESOLVED] Redis Connection String - Localhost vs Container Name

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** High

### Description

Health check Redis fail vì:

1. Dùng `localhost` thay vì container service name `menugreen_redis`
2. Redis có password nhưng connection string không chứa password
3. Health check code đọc `REDIS_URL` không phải `REDIS__CONNECTIONSTRING`

### Root Cause

Trong Docker Compose, containers giao tiếp qua **service name** không phải localhost. Thêm vào đó:

- Redis yêu cầu password: `REDIS_PASSWORD="eH671/FNx4LyTMJcEXQJ"`
- Connection string format đúng: `redis://:PASSWORD@HOST:PORT`

### Fix Required (Update in Doppler)

```env
# Trước (sai)
REDIS__CONNECTIONSTRING="redis://localhost:6379"

# Sau (đúng)
REDIS_URL="redis://:eH671/FNx4LyTMJcEXQJ@menugreen_redis:6379"
```

### Files Changed

- Doppler config (`prd`)

---

## [DOCUMENTED] Production Infrastructure

**Date:** 2026-07-02
**Status:** ✅ Documented
**Severity:** N/A (Documentation)

### Server Information

| Property           | Value                                                       |
| ------------------ | ----------------------------------------------------------- |
| **Hostname**       | ip-172-26-11-157                                            |
| **SSH Access**     | `ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100` |
| **App Location**   | `~/apps/MenuGreenSystem`                                    |
| **OS**             | Ubuntu 22.04 LTS                                            |
| **Docker**         | 29.6.1                                                      |
| **Docker Compose** | 5.2.0                                                       |
| **Git**            | 2.34.1                                                      |
| **psql Client**    | 14.23                                                       |
| **jq**             | 1.6                                                         |
| **Disk**           | 58GB (17% used)                                             |
| **RAM**            | 1.9GB                                                       |

### Database Information (AWS RDS)

| Property            | Value                                                        |
| ------------------- | ------------------------------------------------------------ |
| **Engine**          | PostgreSQL 18.3                                              |
| **Region**          | ap-southeast-1 (Singapore)                                   |
| **Endpoint**        | `menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com` |
| **Port**            | 5432                                                         |
| **Database Name**   | `menugreendb`                                                |
| **Master Username** | `postgres`                                                   |

### Docker Containers

| Container       | Image                                  | Status  | Ports                  |
| --------------- | -------------------------------------- | ------- | ---------------------- |
| menugreen_api   | anhtuan21112004/menugreensystem:latest | Running | 0.0.0.0:5000->5000/tcp |
| menugreen_redis | redis:7-alpine                         | Running | 6379/tcp               |
| menugreen-net   | Custom bridge network                  | Active  | -                      |

### Commands Reference

```bash
# SSH to server
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100

# Check container status
docker ps

# View API logs
docker logs menugreen_api --tail 50 -f

# Restart API
docker restart menugreen_api

# Database operations
PGPASSWORD='<YOUR_PASSWORD>' psql -h menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com -U postgres -c "CREATE DATABASE menugreendb;"
PGPASSWORD='<YOUR_PASSWORD>' psql -h menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com -U postgres -l

# Navigate to app
cd ~/apps/MenuGreenSystem
```

### Docker Hub

| Property     | Value                                    |
| ------------ | ---------------------------------------- |
| **Image**    | `anhtuan21112004/menugreensystem:latest` |
| **Registry** | Docker Hub                               |

---

## [RESOLVED] Canonical Docs Review - Endpoint Count & Formula Mismatches

**Date:** 2026-07-08
**Status:** ✅ Resolved
**Severity:** Medium (Documentation)

### Description

Sau khi tái cấu trúc docs feature, đã review lại toàn bộ 10 file canonical và phát hiện:

- 6 file có số "Tổng" endpoint sai (đếm thiếu so với `[Http*]` thực tế trong controllers).
- 3 công thức dinh dưỡng (A.5 macro, A.7 goal drift, A.14 recommendation scoring) trong `10-vietnam-local-features.md` không khớp với code.
- 1 EP save-preference (`POST /api/Ingredient/preferences/substitutes`) chưa được document.

### Root Cause

Trong quá trình rewrite, một số endpoint bị miss khi đếm thủ công; formula copy từ tài liệu reference cũ (mục tiêu tổng quát) chưa được đối chiếu với code đã shipped.

### Fix Applied

**1. Sửa formula:**
- A.5: Build Muscle carbs 40% → 45%, fat 25% → 20% (`HealthProfileMetricsCalculator.cs:82-107`).
- A.7: Calorie drift threshold 10% → 8% (`GoalDriftService.cs:98`).
- A.14: Viết lại scoring formula 0-100 theo code thật (`RecommendationService.cs:163-211`).
- Cập nhật "Khuyến nghị" checklist trong 10 (đánh dấu ✅/⏳).

**2. Bổ sung endpoint & sửa số Tổng:**
- `01-auth-and-account.md`: Auth 9 → 8 EP (không có `resend-otp` riêng, gọi `register` lại); HealthProfile 8 → 4 EP (không có `POST /me`, `PATCH /me/activity`, `GET /me/target`); Onboarding 3 → 1 EP (không có `GET /status`, chỉ `POST /complete`, `GET /completion` thuộc Profile).
- `02-nutrition-tracking.md`: 11 → 33 EP (mở rộng §3.5 Vietnam Nutrition từ 4 → 13 EP; thêm 4 EP UserDashboard; substitute-ingredient xếp về IngredientSubstitution).
- `03-meal-plan.md`: 19 → 26 EP (thêm §3.5 Budget & Alternatives + §3.6 Expenses + create-empty, distribute, adherence-scores).
- `04-discover-and-allergy.md`: 10 → 46 EP (10 Food + 7 Recipe + 10 Allergy + 7 Portion + 3 Vietnam Discovery + 9 Ingredient Substitution; sửa Food/search thành root `/api/Food`; safe-alternatives chuyển từ Recipe sang §3.5 IngredientSubstitution).
- `06-ai-assistant-and-coach.md`: 26 → 31 EP (22 AI Assistant + 9 AI Coach; split feedback dual-path).
- `07-notification.md`: 23 → 32 EP (thêm 4 send subroutes, 1 analytics subroute, 6 campaigns CRUD).
- `08-subscription-and-payment.md`: thêm `GET /SubscriptionPlan?isActive=` + ghi chú AllowAnonymous/Webhook.
- `09-analytics.md`: 30 → 37 EP (thêm §3.8 Nutrition Analytics 7 EP).
- `10-vietnam-local-features.md` §3.2: thêm `POST /DailyStarter/save-preference`; §3.8: chỉ 3 EP preferences, tham chiếu §3.5 IngredientSubstitution ở file 04.

### Files Changed

- `docs/features/01-auth-and-account.md`
- `docs/features/03-meal-plan.md`
- `docs/features/08-subscription-and-payment.md`
- `docs/features/10-vietnam-local-features.md`
- `docs/03-features-overview/README.md`
- `docs/00-overview/README.md`
- `docs/00-overview/PROJECT_STATUS.md`
- `docs/issues.md`
- `docs/SPEC.md` (tạo mới, v1 + v2)
- `docs/features/11-premium-programs.md` (tạo mới)
- `docs/features/12-meal-templates.md` (tạo mới)
- `docs/features/13-micro-learning.md` (tạo mới)
- `docs/features/14-adaptive-reminders.md` (tạo mới)
- `docs/features/15-pt-review.md` (tạo mới)
- `docs/features/16-budget-management.md` (tạo mới)
- `docs/features/17-coaches.md` (tạo mới)
- `docs/features/18-ingredient-catalog.md` (tạo mới)
- `docs/features/19-user-management.md` (tạo mới)

### Verification (round 2: 2026-07-09)

- Đếm thủ công `[Http*]` trên **47 controller** → tìm thêm 22 undocumented:
  - Duplicate/alias: NutritionAssistantController, UserMealPlanController, UserAiProfileController, GoalsController (4)
  - Infrastructure: NotificationAdmin, Dashboard, Fcm, JobTrigger, AdminMicroLearning (5)
  - Feature (đã implement, chưa doc): Coaches(16), PremiumPrograms(12), MealTemplate(8), MicroLearning(6), Reminder(7), PtReview(7), BudgetRequest(4), Ingredient(7), UserController(8), GoalsController(7), EngagementController(5), CvController(1) = 88 EP
- Tạo 9 canonical doc files (11-19) cho feature chưa doc.
- Tạo `docs/00-overview/SPEC.md` v2: 19 modules, 35 controllers, ~388 EP.
- Cập nhật 03-features/README.md: thêm 10 rows (11-19).
- **22 controllers còn lại**: Duplicate(4) + Infrastructure(5) + Proposed(2) + Legacy(1) = 12 controllers không cần doc (stub/infra/duplicate).

---

## [DOCUMENTED] Docs/Features API Endpoint Verification Round 3 — 2026-07-09

**Date:** 2026-07-09
**Status:** Documented
**Severity:** Medium (Documentation)

### Scope

Script `scripts/verify_endpoints.py` đếm `[HttpGet]`, `[HttpPost]`, `[HttpPut]`, `[HttpDelete]`, `[HttpPatch]` trong **47 controllers** và so sánh với **19 doc files** trong `docs/features/`. Tổng thực tế của mỗi doc = sum các controller được map.

### Kết quả tổng

| Doc File | Doc ghi | Thực tế | Mismatch |
|----------|---------|---------|---------|
| 01-auth-and-account.md | 19 | 19 | 0 (Script bug: regex chỉ bắt "Tổng" đầu tiên, hiện 8) |
| 02-nutrition-tracking.md | 33 | 33 | 0 |
| 03-meal-plan.md | 26 | 30 | -4 |
| 04-discover-and-allergy.md | 46 | 44 | +2 |
| 05-recommendation-engine.md | 16 | 16 | 0 |
| 06-ai-assistant-and-coach.md | ~40 | 40 | Tổng |
| 07-notification.md | 32 | 32 | 0 |
| 08-subscription-and-payment.md | 20 | 20 | 0 |
| 09-analytics.md | 37 | 37 | 0 |
| 10-vietnam-local-features.md | ~47 | 47 | Tổng |
| 11-premium-programs.md | 12 | 11 | +1 |
| 12-meal-templates.md | 8 | 9 | -1 |
| 13-micro-learning.md | ~12 | 12 | Tổng |
| 14-adaptive-reminders.md | 8 | 8 | 0 |
| 15-pt-review.md | 7 | 7 | 0 |
| 16-budget-management.md | 4 | 4 | 0 |
| 17-coaches.md | 16 | 15 | +1 |
| 18-ingredient-catalog.md | 7 | 7 | 0 |
| 19-user-management.md | 7 | 11 | -4 |

**8/16 doc có số Tổng đúng. 8 mismatch cần sửa.**

### Chi tiết từng Mismatch

#### 03-meal-plan.md: Doc ghi 26, thực tế 30 (diff +4)
- Doc chỉ liệt kê `MealPlanController` (24 EP) + `PlannedVsActualController` (6 EP) = 30.
- **Sửa doc**: §3.1–§3.6 Tổng: 26 → 30.

#### 04-discover-and-allergy.md: Doc ghi 46, thực tế 44 (diff -2)
- Controller đếm đúng 44 EP. Doc có thể đếm dư 2 EP (cộng thừa §3.5 substitute-ingredient đã nằm trong IngredientSubstitutionController).
- **Sửa doc**: §3.5 Tổng: 46 → 44.

#### 11-premium-programs.md: Doc ghi 12, thực tế 11 (diff +1)
- Doc cộng thừa 1 EP. PremiumProgramsController: GET:7 + POST:4 = 11. Không có PUT/DELETE/PATCH.
- **Sửa doc**: Tổng: 12 → 11.

#### 12-meal-templates.md: Doc ghi 8, thực tế 9 (diff -1)
- Doc thiếu 1 EP. MealTemplateController: GET:3 + POST:4 + PUT:1 + DELETE:1 = 9. Doc đếm 8.
- **Sửa doc**: Tổng: 8 → 9.

#### 17-coaches.md: Doc ghi 16, thực tế 15 (diff +1)
- Doc cộng thừa 1 EP. CoachesController: GET:7 + POST:6 + PUT:2 = 15. Doc đếm 16.
- **Sửa doc**: Tổng: 16 → 15.

#### 19-user-management.md: Doc ghi 7, thực tế 11 (diff -4)
- Doc thiếu 4 EP. UserController đếm 11 EP:
  - PUT change-password (1) + GET (2) + PUT (5) + PATCH (4) = 12
  - 4 endpoints có `[HttpPatch]` + `[HttpPut]` đồng thời (toggle-status, lock, unlock, assign-role) = mỗi cặp chỉ là 1 route thực, nhưng script đếm cả 2 attributes = 2. Thực tế 7 unique routes.
- **Nguyên nhân**: Một số endpoint có cả `[HttpPatch]` và `[HttpPut]` cùng route — script đếm 2 nhưng API chỉ là 1. Doc đúng khi ghi 7.
- **Resolution**: Doc giữ nguyên 7, script đếm dư 4 endpoint dạng PATCH+PUT dual-method.

#### 07-notification.md: Doc ghi 38, thực tế 32 (diff +6)
- Doc đếm dư 6 EP. NotificationController: GET:9 + POST:14 + PUT:2 + DELETE:3 + PATCH:4 = 32.
- **Sửa doc**: Tổng: 38 → 32.

### Script Bug Note

- Script regex `\*\*Tổng[:\*]*\s*(\d+)` chỉ bắt "Tổng" **đầu tiên** trong doc. Doc 01 có 4 "Tổng" nhưng script chỉ bắt 8 (AuthController), không bắt 8 (Profile) + 1 (Onboarding) + 4 (HealthProfile) = 21. Đây là script bug, **doc 01 đúng 19 EP**.
- Script cũng đếm `[HttpPatch]` + `[HttpPut]` trên cùng 1 method là 2, nhưng thực tế là 1 route (user chọn 1 trong 2 HTTP method).

### Files Changed

| File | Hành động |
|------|-----------|
| `scripts/verify_endpoints.py` | Tạo mới |
| `docs/endpoint_verify_output.txt` | Output script |
| `docs/issues.md` | Thêm record này |

### Fix Required

| File | Fix |
|------|-----|
| `docs/features/03-meal-plan.md` | §3 Tổng: 26 → 30 |
| `docs/features/04-discover-and-allergy.md` | §3 Tổng: 46 → 44 |
| `docs/features/07-notification.md` | §3 Tổng: 38 → 32 |
| `docs/features/11-premium-programs.md` | §3 Tổng: 12 → 11 |
| `docs/features/12-meal-templates.md` | §3 Tổng: 8 → 9 |
| `docs/features/17-coaches.md` | §3 Tổng: 16 → 15 |

---


---

## [PENDING] Deployment Failed - Database "MenuGreenDb" Does Not Exist

**Date:** 2026-07-09
**Status:** Pending
**Severity:** High

### Description

GitHub Actions deployment thất bại tại bước backup database. Lỗi:

```
pg_dump: error: connection to server at "menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com" (13.250.214.140), port 5432 failed: FATAL:  database "MenuGreenDb" does not exist
```

### Root Cause

Tên database trong connection string là `MenuGreenDb` (PascalCase) nhưng database thực tế trên RDS là `menugreendb` (lowercase). PostgreSQL database names thường case-sensitive.

### Environment

- **Server:** AWS Lightsail Ubuntu 22.04
- **RDS:** PostgreSQL 18.3 @ ap-southeast-1
- **Endpoint:** `menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com`
- **Expected DB Name:** `menugreendb`
- **Wrong DB Name:** `MenuGreenDb`

### Logs

```
2026-07-09T09:01:11.2797761Z out: === Starting database backup ===
2026-07-09T09:01:11.4251196Z out: pg_dump: error: connection to server at "menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com" (13.250.214.140), port 5432 failed: FATAL:  database "MenuGreenDb" does not exist
2026-07-09T09:01:11.4291841Z 2026/07/09 09:01:11 Process exited with status 1
2026-07-09T09:01:11.4315538Z ##[error]Process completed with exit code 1.
```

### Fix Required

1. **Kiểm tra Doppler secrets** - Tìm `CONNECTIONSTRINGS__DEFAULTCONNECTION` và sửa database name từ `MenuGreenDb` → `menugreendb`
2. **Hoặc sửa CI/CD script** - Thêm step rename/sanitise database name trong backup script:
   ```bash
   # Sanitise database name (lowercase)
   DB_NAME_LOWER=$(echo "$DB_NAME" | tr '[:upper:]' '[:lower:]')
   PGPASSWORD="$DB_PASSWORD" pg_dump -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USER" -d "$DB_NAME_LOWER" -F p -f "$BACKUP_FILE"
   ```

### Verification After Fix

```bash
PGPASSWORD='<YOUR_PASSWORD>' psql -h menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com -U postgres -l
# Kiểm tra database name hiển thị đúng
```

---

## [RESOLVED] Vietnam Local Features — UI triển khai hoàn chỉnh

**Date:** 2026-07-09
**Status:** ✅ Resolved
**Severity:** Medium

### Description

Tài liệu `docs/features/10-vietnam-local-features.md` liệt kê 7 workflow (2.11 – 2.18) với trạng thái `API Done · UI Partial`. Phần lớn UI chưa có, ngoại trừ Allergy Risk Badge. Cần triển khai đầy đủ giao diện Flutter cho từng workflow dựa trên các endpoint backend đã có.

### Root Cause

Tính năng backend hoàn thiện sớm nhưng chưa được ưu tiên phát triển UI vì các task tracking/meal plan/allergy được xếp P1 trước. Khi roadmap chuyển sang giai đoạn "Vietnam-first", tài liệu ghi nhận các workflow này nhưng chưa có giao diện.

### Environment

- Frontend: `d:\CSharp_UpSpeed\MenuGreenSystem\frontend` (Flutter 3.11, Dart 3.x)
- Backend: `d:\CSharp_UpSpeed\MenuGreenSystem\backend\MenuGreen.API`
- Tài liệu tham khảo: `docs/features/10-vietnam-local-features.md`

### Fix Applied

Tạo feature hoàn chỉnh `frontend/lib/features/vietnam_local/` với:

1. **Models** — `vietnam_local_models.dart` ánh xạ 18+ DTO backend (DailyStarter, GymGoal, SafetyConsent, PlannedVsActualSummary, DriftAnalysis, IngredientSubstitutePreference, ...).
2. **Repositories** — `vietnam_local_repositories.dart` gom 8 repository (DailyStarter, GymGoals, Safety, FoodCapture, LocalPreferences, PlannedVsActual, IngredientSubstitutionPreferences) chia sẻ helper `_VietnamLocalApi._exec` trả `ApiResult<T>` với `translatedMessage` qua `ApiMessageTranslator`.
3. **Providers** — 8 ChangeNotifier providers mount trong `main.dart` (DailyStarter, GymGoals, Safety, LocalPreferences, PlannedVsActual, FoodCapture, IngredientSubstitution).
4. **Widgets dùng chung** — `InfoCard`, `SectionHeader`, `RangePickerField` theo convention `flutter-ui-conventions.md`.
5. **Màn hình Views (12 files)**:
   - `daily_starter_screen.dart` + `daily_starter_personalization_screen.dart` (2.12)
   - `gym_goals_screen.dart` (2.13, kèm editor)
   - `food_capture_screen.dart` (2.14)
   - `safety_hub_screen.dart`, `disclaimer_screen.dart`, `consent_screen.dart`, `report_issue_screen.dart` (2.15)
   - `local_preferences_screen.dart` (2.11)
   - `planned_vs_actual_screen.dart` (2.17)
   - `ingredient_substitution_screen.dart` (2.18)
6. **Endpoints** — bổ sung vào `core/network/api_endpoints.dart` cho tất cả controller mới.
7. **Translations** — mở rộng `ApiMessageTranslator` với 8 message mới (Recalibration, Consent updated, Substitution applied, ...).
8. **Tích hợp navigation**:
   - `home_view.dart`: thêm thẻ "Lối tắt nhanh" (Hôm nay ăn gì? + Ăn ngoài?).
   - `profile_view.dart`: thêm nhóm "Ăn uống Việt Nam" (5 mục).
   - `main.dart`: đăng ký 7 provider mới trong MultiProvider.

### Verification

- `flutter analyze lib/features/vietnam_local lib/main.dart lib/core/i18n/api_message_translator.dart lib/core/network/api_endpoints.dart lib/features/home lib/features/profile` → 0 lỗi compile.
- `flutter build apk --debug --no-pub` → built thành công APK debug.
- Tài liệu `10-vietnam-local-features.md` cập nhật Status, UI Components table, Navigation Flow.

## Template for New Issues

```markdown
## [PENDING/RESOLVED] Issue Title

**Date:** YYYY-MM-DD
**Status:** Pending/Resolved
**Severity:** Low/Medium/High

### Description

### Root Cause

### Environment

### Logs

### Fix Applied / Attempts
```

---

## [PENDING] Google Play Console - Account Deletion URL

**Date:** 2026-07-09
**Status:** Pending (waiting for user to deploy to GitHub Pages)
**Severity:** Medium

### Description
Google Play Console yêu cầu cung cấp **URL xoá tài khoản** để tuân thủ
chính sách User Data Policy. Cần phải có trang web công khai hướng dẫn
user cách yêu cầu xoá tài khoản và dữ liệu cá nhân.

### Root Cause
App cung cấp đăng ký tài khoản (email + Google OAuth) nên theo chính
sách Google, phải có URL xoá tài khoản hiển thị trên trang CH Play.

### Environment
- Google Play Console → App content → Data safety
- Trang: https://play.google.com/console

### Fix Applied
**Đã tạo 2 file HTML sẵn sàng deploy:**

1. `assets/delete-account/delete-account.html` - Tiếng Việt (mặc định)
2. `assets/delete-account/delete-account-en.html` - English
3. `assets/delete-account/README.md` - Hướng dẫn deploy GitHub Pages

**Trang bao gồm đầy đủ nội dung theo yêu cầu Google:**
- ✅ Nhắc đến tên app "MenuGreen"
- ✅ 5 bước yêu cầu xoá tài khoản (in-app + email)
- ✅ Liệt kê dữ liệu bị xoá (6 loại)
- ✅ Liệt kê dữ liệu giữ lại (2 loại, theo yêu cầu pháp lý)
- ✅ Thời gian xử lý (7 ngày làm việc)
- ✅ Thông tin liên hệ support

### Attempts
- [x] Tạo file HTML song ngữ với thiết kế chuyên nghiệp
- [x] Responsive (mobile + desktop)
- [ ] User deploy lên GitHub Pages
- [ ] User dán URL vào Play Console
- [ ] User bấm Save trong form An toàn dữ liệu

### Customization cần thay trước khi deploy
- `support@menugreen.app` → email thật của nhà phát triển
- `https://menugreen.app` → website thật (nếu có)
- `MenuGreen Team` → tên nhà phát triển chính xác theo Play Console

---

## Prevention Guidelines

### YAML Files

- Luôn dùng consistent indentation (spaces, not tabs)
- Không để commented YAML blocks trong Docker Compose

### Docker Compose

- Containers giao tiếp qua **service names** trong cùng network
- Không dùng `localhost` cho inter-container communication
- Luôn dùng `volumes: []` thay vì commented volumes

### CI/CD

- Test workflow syntax trước khi push
- Dùng `yamllint` hoặc VS Code YAML validation

```

```
