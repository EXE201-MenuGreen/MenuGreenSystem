# Issues Encountered

Danh sách các issue đã gặp trong quá trình phát triển và deploy.

---

## [RESOLVED] Firebase PEM newline bug — Deploy aborts after Doppler extract

**Date:** 2026-07-16
**Status:** ✅ Resolved (commits `273403e` + `8225e0d` on `main` / `Tuan`)
**Severity:** High

### Description

Sau khi backend CI build xong image, CD deploy chạy `deploy-server.sh`. Tại bước `=== Materialize Firebase credentials JSON ===`, file JSON trên server bị sanity-check reject:

```
err: FATAL: private_key PEM has no real newlines between BEGIN and END -
     GoogleCredential needs real \n in the PEM body, not literal \n.
out: >>> Aborting deploy before pulling new image.
```

`GoogleCredential.FromFile()` của .NET SDK yêu cầu real newlines trong PKCS8 PEM block (giữa `-----BEGIN PRIVATE KEY-----` và `-----END PRIVATE KEY-----`). PEM body bị "smash" thành 1 dòng dài → `System.ArgumentException` → container crash-loop → health check fail 30 lần.

### Root Cause

Script extract secret `FIREBASE_CREDENTIALS_JSON` từ Doppler `--format env`. Doppler wrap multi-line value trong `"..."`, escape `"` thàng `\"`, và newline handling phụ thuộc Doppler CLI version. Python extractor trong `deploy-server.sh` chỉ replace `\"` → `"`, không robust với newline → PEM body trên disk có thể bị mất real newlines.

4 commit trước đó (`122de45`, `3546f1a`, `d6f4b6a`, `20ebdce`) thử fix extractor nhưng vẫn fail vì Doppler escape format không ổn định.

### Fix Applied

**Commit `273403e`**: Chuyển sang `doppler secrets get FIREBASE_CREDENTIALS_JSON --plain` (Doppler khuyến nghị cho multi-line secret dùng cho file-on-disk). `--plain` emit raw value byte-for-byte, không quote-wrap, không escape.

```bash
FIREBASE_JSON=""
if command -v doppler > /dev/null 2>&1; then
  FIREBASE_JSON="$(doppler secrets get FIREBASE_CREDENTIALS_JSON \
    --token "$DOPPLER_TOKEN" \
    --project menugreen \
    --config prd \
    --plain 2>/dev/null)"
fi
```

Sanity check `/tmp/firebase_pem_check.py` (json.load + PEM newline check + json.dump re-serialize) giữ nguyên làm safety net.

**Commit `8225e0d`**: Sửa bug phụ — `rm -f /tmp/firebase_pem_check.py` thiếu `sudo`. File tạo bởi `sudo tee` (owned by root) nên rm không có sudo fail với "Operation not permitted". Đổi thành `sudo rm -f`.

### Lessons Learned

1. Khi ingest multi-line JSON secret vào Doppler để dùng cho file-on-disk, **đừng** extract từ `--format env` bulk download. Dùng `doppler secrets get NAME --plain` riêng cho secret đó.
2. Mọi lệnh thao tác file trong `/tmp/firebase_pem_check.py` đều phải có `sudo` vì file owned by root.

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

- Redis yêu cầu password: `REDIS_PASSWORD="<set-in-secret-manager>"`
- Connection string format đúng: `redis://:PASSWORD@HOST:PORT`

### Fix Required (Update in Doppler)

```env
# Trước (sai)
REDIS__CONNECTIONSTRING="redis://localhost:6379"

# Sau (đúng)
REDIS_URL="redis://:${REDIS_PASSWORD}@menugreen_redis:6379"
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

## [RESOLVED] Release APK/AAB Crash on Install - Missing .env + libapp.so Not Packaged

**Date:** 2026-07-14
**Status:** Resolved
**Severity:** High

### Description

Build `app-release.apb` 38.5MB trước đó (2026-07-09) bị lỗi khi cài lên thiết bị: mở app lên thì crash ngay với log:

```
[ERROR:flutter/runtime/dart_vm_data.cc(20)] VM snapshot invalid and could not be inferred from settings.
[ERROR:flutter/runtime/dart_vm.cc(253)] Could not set up VM data to bootstrap the VM from.
F libc    : Fatal signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x6b8 in tid X
```

Sau đó `Process com.menugreen.app has crashed too many times, killing!`.

### Root Cause

Hai vấn đề đồng thời khiến AAB không chạy được:

**1. File `.env` thiếu so với khai báo trong `pubspec.yaml`:**
```yaml
flutter:
  assets:
    - assets/images/
    - .env  # <- file này không tồn tại
```
Build release lần đầu (sau khi pubspec đã thêm `.env`) fail với:
```
Error detected in pubspec.yaml: No file or variants found for asset: .env.
Target aot_android_asset_bundle failed: Exception: Failed to bundle asset files.
```
Dev có thể đã tạo `.env` tạm thời để build pass, rồi xoá đi. Sau đó build bằng cached intermediate → APK thiếu assets nhưng vẫn ra file.

**2. AGP `mergeReleaseNativeLibs` không pick up `libapp.so`:**
Trong build intermediates có file:
```
build/app/intermediates/flutter/release/jniLibs/arm64-v8a/libapp.so (14MB)
build/app/intermediates/flutter/release/jniLibs/x86_64/libapp.so (14MB)
```
nhưng AGP chỉ merge `libflutter.so` vào APK. Kết quả APK không có `libapp.so` (chứa AOT snapshot), app boot lên thì Flutter engine không tìm được VM snapshot → SIGSEGV.

Nguyên nhân: project đã config `subprojects { afterEvaluate { project.layout.buildDirectory.value(...) } }` trong `android/build.gradle.kts:10-26` để redirect `:app` build sang `frontend/build/`. Có thể Flutter Gradle plugin không tự động register `libapp.so` như native lib qua cơ chế `jniLibs` mặc định của nó khi build directory bị override.

### Environment
- Flutter 3.44.0 / Dart 3.12.0
- Android Gradle Plugin 8.9.1, Gradle 8.11.1
- Emulator Pixel_6 (Android 14, x86_64)

### Logs

```
# Build ban đầu fail:
Error detected in pubspec.yaml: No file or variants found for asset: .env.

# Build sau khi tạo .env:
Release app bundle failed to strip debug symbols from native libraries.

# Verify APK thiếu libapp.so:
unzip -l app-release.apk | grep "\.so"
  lib/arm64-v8a/libflutter.so
  lib/x86_64/libflutter.so
  # <- KHÔNG có libapp.so

# Logcat khi cài lên emulator:
E flutter : [ERROR:flutter/runtime/dart_vm_data.cc(20)] VM snapshot invalid and could not be inferred from settings.
F libc    : Fatal signal 11 (SIGSEGV)
W ActivityManager: Process com.menugreen.app has crashed too many times, killing!
```

### Fix Applied

**1. Tạo file `.env` mẫu** tại `frontend/.env` (đã có trong `.gitignore`):
```
# MenuGreen - Environment Configuration
API_BASE_URL=
GOONG_API_KEY=
```

**2. Thêm `jniLibs.srcDirs` vào `android/app/build.gradle.kts`** để ép AGP include `libapp.so`:
```kotlin
android {
    defaultConfig {
        applicationId = "com.menugreen.app"
        // ...
        ndk {
            // no abiFilters override here - let --target-platform drive it
        }
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDirs(
                "src/main/jniLibs",
                "../../build/app/intermediates/flutter/release/jniLibs",
            )
        }
    }
    // ...
}
```

**3. Tăng version `1.0.0+1 → 1.0.0+2`** trong `pubspec.yaml`.

**4. Build lại AAB** với đầy đủ architectures:
```bash
flutter clean
flutter pub get
flutter build appbundle --release --target-platform android-arm,android-arm64,android-x64
# -> build/app/outputs/bundle/release/app-release.aab (67.2 MB)
```

**5. Build APK cho local test:**
```bash
flutter build apk --release --target-platform android-arm64,android-x64
# -> build/app/outputs/flutter-apk/app-release.apk (49.4 MB)
```

**6. Verify APK có đủ `libapp.so`:**
```
unzip -l app-release.apk | grep "\.so"
  lib/arm64-v8a/libapp.so        9.8 MB
  lib/arm64-v8a/libflutter.so   11.6 MB
  lib/x86_64/libapp.so          10.0 MB
  lib/x86_64/libflutter.so      12.9 MB
```

**7. Smoke test trên emulator Pixel_6 (Android 14, x86_64):**
- Install via adb: `Success`
- Launch app: `Displayed com.menugreen.app/.MainActivity for user 0: +1s102ms`
- Flutter engine: `Using the Impeller rendering backend (OpenGLES)` → OK
- Splash screen render đúng (icon + "MenuGreen" + tagline + progress bar)
- Không còn fatal/crash
- Firebase Messaging + Geolocator background services init OK

### Files Changed
- `frontend/.env` (mới, đã có trong .gitignore)
- `frontend/pubspec.yaml` (line 19: version bump)
- `frontend/android/app/build.gradle.kts` (thêm sourceSets.jniLibs.srcDirs)
- `docs/issues.md` (record này)

### Verification
- `flutter analyze`: 0 errors, chỉ có 6 warnings (unnecessary_underscores) + 1 warning `asset_does_not_exist` (.env đã tạo).
- `apksigner verify --print-certs` trên APK:
  ```
  Signer #1 certificate DN: CN=MenuGreen Team, O=MenuGreen, L=Ho Chi Minh, ST=HCM, C=VN
  ```
- `unzip -l` AAB có `.env` ở `base/assets/flutter_assets/.env` (331 bytes) ✅

### Build Artifacts
- `frontend/build/app/outputs/bundle/release/app-release.aab` (67.2 MB) — upload Play Store
- `frontend/build/app/outputs/flutter-apk/app-release.apk` (49.4 MB) — local test
- Backup tại `C:\Users\Admin\menu-green-assets\app-release-closed-v2.aab`

### Status
- [x] Root cause identified
- [x] Fix applied + committed
- [x] AAB/APK build thành công, có libapp.so
- [x] Smoke test trên emulator pass (no crash, splash render)
- [ ] Closed testing track trên Play Console (cần user thực hiện thủ công)

---

## [PENDING] EF Core Migration Conflict — foods table already exists

**Date:** 2026-07-20
**Status:** Pending
**Severity:** High

### Description

`dotnet ef database update` (PM> update-database) bị lỗi khi chạy migration `20260629084940_InitialCreate`:

```
Npgsql.PostgresException (0x80004005): 42P07: relation "foods" already exists
```

Migration cố tạo bảng `foods` nhưng bảng đã tồn tại trong database.

### Root Cause

1. Bảng `foods` được tạo bằng **script SQL thủ công** (`backend/database/01_foods_seed.sql`) — không phải qua EF Core migration.
2. Bảng đã tồn tại nhưng record trong `__EFMigrationsHistory` cho migration `InitialCreate` **chưa có** (hoặc đã bị xoá).
3. EF Core không biết bảng đã tồn tại → cố tạo lại → conflict.

### Environment

- PostgreSQL database (local hoặc production)
- EF Core 9.0 / Npgsql
- Migration: `20260629084940_InitialCreate`

### Logs

```
CREATE TABLE foods (
    "Id" uuid NOT NULL,
    "NameVi" text NOT NULL,
    ...
    CONSTRAINT "PK_foods" PRIMARY KEY ("Id")
);
Npgsql.PostgresException (0x80004005): 42P07: relation "foods" already exists
```

### Solution

**Cách 1 (Recommended):** Insert record vào `__EFMigrationsHistory` để đánh dấu migration đã applied:

```sql
INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260629084940_InitialCreate', '9.0.0');
```

Sau đó chạy lại:
```bash
dotnet ef database update
```

**Cách 2:** Dùng EF Core tool để mark migration as applied:

```bash
dotnet ef database update 20260629084940_InitialCreate --no-build
```

### Attempts

- [ ] Chạy SQL insert vào `__EFMigrationsHistory`
- [ ] Verify `dotnet ef database update` không còn lỗi
- [ ] Verify các migration tiếp theo áp dụng đúng

---

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

---

## [PENDING] Google Sign-In Fails on Real Device — Missing google-services.json & SHA-1 Fingerprint Not Registered

**Date:** 2026-07-15 (mở) · 2026-07-26 (re-open với lỗi network_error)
**Status:** Pending
**Severity:** High

### Description

Khi login bằng Google trên **thiết bị thật**, app gọi `GoogleSignIn.signIn()` nhưng flow đứt ngang — `SignInHubActivity` mở lên rồi bị đóng (`WindowStopped`, `Input channel destroyed` trong logcat 8.txt) và không trả về Google account. Trên emulator thì chạy ổn.

Backend `POST /api/Auth/google` trả về `Invalid Google sign-in token.` (frontend map sang "Token đăng nhập Google hết hạn hoặc không hợp lệ." qua `localizeAuthMessage`).

**Update 2026-07-26:** user báo lỗi mới trên thiết bị thật:

```
PlatformException(network_error, com.google.android.gms.common.api.Api7: , null, null)
```

`ApiException` code bị null → SDK strip error code, message rỗng. Triệu chứng cho thấy Google Sign-In SDK không thể handshake với backend Play Services, gần như chắc chắn vì **OAuth Android Client thiếu/sai SHA-1** trong Firebase project `menugreen-9fb5b`.

### Root Cause

Hai vấn đề đồng thời khiến plugin `google_sign_in` không nhận được idToken trên thiết bị thật:

**1. Thiếu file `frontend/android/app/google-services.json`:**
- Plugin `google_sign_in` (v6.2.2) + plugin Gradle `com.google.gms.google-services:4.4.4` đều cần file này để generate `res/values/strings.xml` chứa OAuth Client ID Android + SHA-1 đã đăng ký.
- Repo hiện **không có file này** (đã glob toàn workspace — không tìm thấy).
- File `frontend/lib/firebase_options.dart` chỉ hardcode cho `Firebase Core SDK`, **không đủ** cho plugin `google_sign_in` lấy Android OAuth Client.
- Kết quả: `GoogleSignIn.signIn()` ném `PlatformException(sign_in_failed, ApiException: 10 — DEVELOPER_ERROR)` trên thiết bị thật (Play Services check SHA-1 nghiêm ngặt). Emulator bypass một phần nên "có vẻ" chạy.

**2. Release build fallback về debug keystore + SHA-1 debug chưa đăng ký Firebase Console:**
- File `frontend/android/key.properties` **không tồn tại** trong repo → `hasReleaseSigningConfig = false` trong `build.gradle.kts:16-18`.
- `signingConfig = signingConfigs.getByName("debug")` ở `build.gradle.kts:69-74` → APK/AAB release được ký bằng debug keystore của máy build (random SHA-1 mỗi máy).
- SHA-1 của debug keystore máy dev **chưa được add vào Firebase Console** → Android app `com.menugreen.app` (project `menugreen-9fb5b`) không có OAuth client Android khớp → Google từ chối cấp `idToken`.

### Environment

- **Project:** `menugreen-9fb5b` (Firebase)
- **Android app:** `com.menugreen.app`
- **Frontend packages:** `firebase_core ^3.15.2`, `firebase_auth ^5.7.0`, `google_sign_in ^6.2.2`
- **Hard-coded web client ID trong code:** `709315528907-sd0et9a55hqo9ksitbn3lg3jpvhmiqol.apps.googleusercontent.com` (`lib/core/services/firebase_google_auth_service.dart:9`)
- **Keystore info file:** `frontend/android/app/keystore_pass.txt` (chưa có file `.jks` thật)

### Logs

```
# terminals/8.txt — flow bị ngắt giữa chừng
I/ViewRootImpl@4df76ac[SignInHubActivity](29137): Resizing ...
I/InsetsSourceConsumer(29137): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.menugreen.app/com.google.android.gms.auth.api.signin.internal.SignInHubActivity
...
I/ViewRootImpl@4df76ac[SignInHubActivity](29137): handleAppVisibility mAppVisible = true visible = false
I/ViewRootImpl@4df76ac[SignInHubActivity](29137): stopped(true) old = false
D/ViewRootImpl@4df76ac[SignInHubActivity](29137): WindowStopped on com.menugreen.app/com.google.android.gms.auth.api.signin.internal.SignInHubActivity set to true
W/WindowOnBackDispatcher(29137): sendCancelIfRunning: isInProgress=falsecallback=android.view.ViewRootImpl$$ExternalSyntheticLambda19@5235198
I/ViewRootImpl@4df76ac[SignInHubActivity](29137): dispatchDetachedFromWindow
D/InputTransport(29137): Input channel destroyed: '66a4ca5', fd=169
# => SignInHubActivity bị dispose, MainActivity focus lại nhưng không có user/auth object.
```

User-facing message tiếng Việt (qua `auth_error_messages.dart`):
```
Token đăng nhập Google hết hạn hoặc không hợp lệ.
```

### Attempts

- [x] (2026-07-26) User paste SHA-1 `ce85cc9395ac7852f3973df862efaa2afbac4709` → **KHỚP** với `oauth_client` dòng 98 của `google-services.json` (package `com.menugreen.food`, client_id `709315528907-th40q44ip2j6jlf387aqb2vdojfde307`).
- [x] (2026-07-26) User paste SHA-256 `2f84c94916a092868f62f8ee21d9a3a10bed7fffa5634189828f8fc36801abee` → **KHỚP** SHA-256 certificate của `app-debug.apk` (verified bằng `apksigner verify --print-certs`).
- [x] (2026-07-26) `frontend/android/app/google-services.json` đã có sẵn trong repo (124 dòng, 2 package_names `com.menugreen.app` + `com.menugreen.food`). Package `com.menugreen.food` match `namespace` trong `build.gradle.kts:30`.
- [x] (2026-07-26) Rebuild debug APK sau khi xác nhận SHA — APK mới build lúc 12:59, đã verify certificate vẫn match `ce85cc...` / `2f84c9...` (không thay đổi vì cùng debug keystore).
- [x] (2026-07-26) Install APK mới lên emulator `emulator-5554` → Success.
- [ ] Test trên emulator: bấm Đăng nhập Google → confirm flow thành công.
- [ ] Kiểm tra `frontend/android/key.properties` đã tồn tại hay chưa (release build hiện vẫn fallback debug keystore)
- [ ] Lấy SHA-1 + SHA-256 của **release keystore** (`frontend/android/app/upload-keystore.jks` khi đã tạo) và add vào Firebase Console
- [ ] (Nếu chưa có file `.jks`) tạo release keystore từ thông tin trong `keystore_pass.txt`
- [ ] Tạo `frontend/android/key.properties` để release build dùng đúng keystore (tránh phải gỡ app khi lên Play Store)
- [ ] `flutter clean && flutter pub get && flutter build apk --release`
- [ ] Cài lại lên thiết bị thật và test Google Sign-In

### Verification After Fix

```bash
# 1. SHA-1 phải có trong google-services.json sau khi tải về
cat frontend/android/app/google-services.json | grep -A 2 "oauth_client"

# 2. APK release phải được ký đúng keystore
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk

# 3. Logcat không còn PlatformException
adb logcat | grep -i "GoogleSignIn\|ApiException"
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

## [RESOLVED] Google sign-in / FCM fail on production - Firebase credentials missing

**Date:** 2026-07-16
**Status:** ✅ Resolved (deploy pending — see Attempts)
**Severity:** High

### Description
Google sign-in (`FirebaseAuth.VerifyIdTokenAsync`) và push notification (`FirebaseMessaging.SendAsync`) silently fail trên production vì `FirebaseApp.DefaultInstance == null` ở startup. Code path đã có sẵn (`Program.cs` dòng 27-38, `AuthService` dòng 248-249, `FcmService` dòng 22-28), nhưng thiếu file `firebase-adminsdk.json` trên server.

Triệu chứng cụ thể:
- Mobile app bấm "Sign in with Google" → backend trả `Google sign-in is not configured on the server.` (`AuthService` line 249).
- Push notification bị skip với log `Firebase is not initialized. Message will not be sent.` (`FcmService` line 196).

### Root Cause
1. `docker-compose.prod.yml` không mount `firebase-adminsdk.json` vào container (chỉ có `volumes: []` rỗng).
2. `Program.cs` đọc `builder.Configuration["Firebase:CredentialPath"]` — nếu file không tồn tại thì skip `FirebaseApp.Create()` (line 33 guard `File.Exists(fullPath)`).
3. Không có file nào cung cấp secret ở `/etc/secrets/firebase-adminsdk.json` trong container.

### Environment
- Production server: `menugreen-api` (Lightsail LXD container)
- Docker image: `docker.io/anhtuan21112004/menugreensystem`
- Doppler project: `menugreen`, config: `prd`

### Logs
Không có error log trước đó vì đây là silent failure — `File.Exists` guard nuốt mất log. User đã manually chạy:
```
sudo chown 0:0 /home/ubuntu/apps/menugreen/firebase-adminsdk.json
sudo chmod 600 /home/ubuntu/apps/menugreen/firebase-adminsdk.json
docker exec menugreen_api id   # → uid=0(root) gid=0(root)
```
→ Confirmed file đã sẵn trên host với owner=root, mode=600. Nhưng chưa được mount vào container.

### Fix Applied (committed locally, pending deploy)

**1. `docker-compose.prod.yml`** — thêm volume mount + env var:
```yaml
environment:
  - Firebase__CredentialPath=${FIREBASE_CREDENTIAL_PATH:-/etc/secrets/firebase-adminsdk.json}
volumes:
  - /home/ubuntu/apps/menugreen/firebase-adminsdk.json:/etc/secrets/firebase-adminsdk.json:ro
```

**2. `backend/scripts/deploy-server.sh`** — materialize JSON từ Doppler mỗi deploy:
- Đọc secret `FIREBASE_CREDENTIALS_JSON` (full JSON body) từ Doppler
- Ghi ra `$APP_DIR/firebase-adminsdk.json` với mode 600, owner root
- Validate JSON parse + có `private_key` field trước khi pull image mới
- Block tương tự trong `perform_rollback()` để rollback path cũng có Firebase

**3. Doppler secrets cần thêm** (user đã thêm xong):
- ✅ `FIREBASE_CREDENTIAL_PATH=/etc/secrets/firebase-adminsdk.json` (đã thêm)
- ⏳ `FIREBASE_CREDENTIALS_JSON=<full nội dung firebase-adminsdk.json>` (CẦN THÊM)

### Attempts
- [x] Confirmed file ownership=root trên host, mode=600
- [x] Smoke test container mount bằng `docker run --rm alpine:3.19` → READ_OK
- [x] Sửa `docker-compose.prod.yml` (volume + env var)
- [x] Sửa `deploy-server.sh` (main path + rollback path)
- [x] User thêm Doppler secret `FIREBASE_CREDENTIALS_JSON`
- [x] User commit + push lên branch `Tuan` (commits `ecfe8ef`, `c316277`)
- [x] **Bug phát hiện trong deploy đầu tiên**: `FIREBASE_CREDENTIALS_JSON` multi-line JSON bị inject vào `.env` loop → `unexpected character "}"` ở line 22 → container không start → rollback fail vì không có local tag + không có `:previous` trên Hub → **service DOWN**
- [x] Fix commit `c316277`: skip `FIREBASE_CREDENTIALS_JSON=` trong cả main + rollback path của .env loop
- [x] Push `c316277` lên `Tuan` → CI/CD workflow chạy với SHA `c316277` → **SUCCESS** trên dashboard API (nhưng commit `Database` merge vào `main` lại trigger CD fail với SHA `cbf657f` dùng script CŨ)
- [x] **Bug phát hiện lần 2**: `origin/main` không có commits fix Firebase → mỗi lần có push lên `main` (vd merge PR `Database`), CD trigger với commit `cbf657f` → fail lại → service DOWN tiếp
- [x] Cherry-pick `ecfe8ef` + `c316277` từ `Tuan` lên `main` (tạo commits `8e18aca`, `a1b395c`)
- [x] Push lên `origin/main` (bypass rule violation, do push trực tiếp không qua PR)
- [ ] **Verify workflow CD mới với SHA `a1b395c` PASS** (đang chờ)
- [ ] Verify volume mount + file Firebase có trong container
- [ ] Test Google sign-in trên Flutter app (production build) → phải tạo được user
- [ ] Test gửi FCM push từ backend → notification phải đến device

---

## [PENDING] Role rename Free → User + add Coach — partial change (SQL only)

**Date:** 2026-07-19
**Status:** Pending — backend C# + Flutter not yet updated
**Severity:** Medium

### Description

User yêu cầu đổi role `Free` thành `User` và thêm role `Coach`. Hiện tại chỉ cập nhật `backend/database/01_roles.sql`, các lớp service phía backend (và có thể Flutter) vẫn đang tham chiếu chuỗi `"Free"` cứng → khi áp seed mới, các flow lọc theo role Free sẽ không match user nào.

### Root Cause

Đổi tên role ở tầng DB seed mà chưa đồng bộ tầng code:

- `backend/MenuGreen.BusinessLogicLayer/Services/SepayPaymentService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/AnalyticsService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/AiAssistantService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/SubscriptionPlanService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/UserSubscriptionService.cs`
- `backend/MenuGreen.BusinessLogicLayer/BackgroundJobs/SubscriptionExpirationBackgroundService.cs`
- `backend/database/02_users.sql` (FK seed về role Free)

Ngoài ra cần kiểm tra Flutter (`ApiMessageTranslator`, role label mapping, quick action filter, etc.) để hiển thị `User` / `Coach` đúng và không hiển thị `Free` cũ.

### Environment

- DB seed: `backend/database/01_roles.sql`
- Backend services: `MenuGreen.BusinessLogicLayer`
- Frontend (chưa khảo sát): `frontend/lib`

### Changes Applied

- `01_roles.sql`: đổi `('...0001', 'Free', ...)` → `('...0001', 'User', 'Standard registered user', ...)`.
- `01_roles.sql`: thêm `('00000000-0000-0000-0000-000000000008', 'Coach', 'Personal trainer / nutrition coach', ...)`.
- Giữ nguyên Id `...0001` (không phá FK cũ).

### Attempts

- [ ] Tìm & thay `"Free"` → `"User"` trong 6 file C# ở trên.
- [ ] Cập nhật `02_users.sql` nếu seed có user cứng gắn role Free.
- [ ] Kiểm tra `coach_profiles.sql` (42) và `coach_connections.sql` (43) — đã có schema cho Coach chưa, có cần FK sang `roles.Id` mới `...0008` không.
- [ ] Khảo sát Flutter: `lib/core/i18n/api_message_translator.dart`, các màn hình liên quan role (home, profile, subscription) để map nhãn `User` / `Coach`.
- [ ] Viết migration EF Core nếu DB production đang chạy — `UPDATE roles SET "Name"='User', "Description"='Standard registered user' WHERE "Id"='00000000-0000-0000-0000-000000000001'; INSERT INTO roles ... Coach ...`.
- [ ] Test lại flow: đăng ký user mới → role mặc định là gì (cần xem `AuthService` / seed default), filter analytics, downgrade subscription.

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

---

## [PENDING] Backend throws Vietnamese string instead of English

**Date:** 2026-07-23
**Status:** Pending
**Severity:** Low (violates `backend-english-frontend-vietnamese-i18n.mdc`)

### Description

Khi audit backend trong Phase 6, phát hiện ít nhất 1 chỗ `PtReviewService.cs:37` throw exception với chuỗi tiếng Việt thay vì tiếng Anh:

```csharp
if (!connections.Any())
{
    throw new Exception("Bạn chưa Đăng ký kết nối với PT");
}
```

Điều này vi phạm rule workspace `"Backend English · Flutter Vietnamese UI"` — backend phải trả về English để Flutter `ApiMessageTranslator` map chính xác sang tiếng Việt. Nếu backend lỡ trả tiếng Việt thì Flutter sẽ hiển thị nguyên chuỗi Việt cho user mà không qua dịch.

### Root Cause

Code viết tắt trong quá trình dev nhanh, không theo convention.

### Environment

- File: `backend/MenuGreen.BusinessLogicLayer/Services/PtReviewService.cs`
- Method: `CreateReportAsync`

### Attempts

- [ ] Sửa `"Bạn chưa Đăng ký kết nối với PT"` → English (ví dụ: `"You are not connected to any coach."`)
- [ ] Chạy grep toàn project: `grep -rn '"[^"]*[ăâđêôơưĂÂĐÊÔƠƯ][^"]*"' backend/MenuGreen.BusinessLogicLayer/Services/` để tìm các chuỗi Việt còn sót
- [ ] Thêm mapping tương ứng vào `frontend/lib/core/i18n/api_message_translator.dart`
- [ ] Verify Flutter analyzer pass

---

## [RESOLVED] Catalog data inconsistency — recipes và ingredients chưa khớp foods

**Date:** 2026-07-24
**Status:** ✅ Resolved (2026-07-24 — Phase 7: full 150-food catalog)
**Severity:** Medium (ảnh hưởng UX màn hình Recipe Detail và macro tính từ ingredient; không gây crash nhưng thiếu dữ liệu cho ~38% recipes và ~85% foods)

### Description

Sau khi seed `15_ingredients.sql`, `16_foods.sql`, `17_recipes.sql`, `18_recipe_ingredients.sql` vào DB mới, đếm thực tế:

| File | Rows | Unique |
|---|---|---|
| `15_ingredients.sql` | 20 | 20 |
| `16_foods.sql` | 130 (50 main + 80 home-cooked) | 130 |
| `17_recipes.sql` | 26 | 26 |
| `18_recipe_ingredients.sql` | 41 | 41 |

Liên kết thực tế (cross-reference FK):

- **recipes → foods**: 20/26 recipes có `FoodId` (FK `foods("Id")`), 6/26 có `FoodId = NULL` (chỉ là recipe tổng quát, không gắn món cụ thể — chấp nhận được theo schema `recipes.FoodId NULLABLE`).
- **recipes → recipe_ingredients**: **10/26 recipes KHÔNG có dòng nào trong `recipe_ingredients`** (khoảng 38%):
  - `ec000011` Bánh mì thịt nướng
  - `ec000012` Gỏi cuốn tôm thịt
  - `ec000013` Xôi xéo giò lụa
  - `ec000014` Overnight oats với berries
  - `ec000015` Grilled chicken với rau nướng
  - `ec000016` Quinoa salad với sốt tahini
  - `ec000017` Acai smoothie bowl
  - `ec000018` Cơm gà Hainan
  - `ec000019` Cơm rang dưa bò
  - `ec000020` Gỏi đu đủ khô bò
- **foods → recipes**: **110/130 foods KHÔNG có recipe** (khoảng 85%). Phần lớn là các món quán / món nước Việt Nam (Phở bò, Bún chả, Bún bò Huế, Mì quảng, Cơm tấm, Hủ tiếu…) hoặc 80 món home-cooked tự nấu (chưa cần recipe vì user tự biết cách nấu, nhưng UI vẫn cần hiển thị ingredient breakdown nếu user chấm điểm).
- **ingredients**: 2/20 ingredients được seed nhưng không recipe nào dùng:
  - `ea000008-1111-2222-3333-444444444444` (Mật ong)
  - `ea000009-1111-2222-3333-444444444444` (Hạt hạnh nhân)

### Root Cause

Trong quá trình phát triển, phần "Extended Recipes (Items 11-20)" trong `17_recipes.sql` được seed INSERT nhưng **không có bước seed `recipe_ingredients` tương ứng** — có lẽ dev đã định làm sau nhưng bị bỏ quên. Tương tự, 80 món home-cooked mới thêm vào `16_foods.sql` (merged từ `16a_home_cooked_foods.sql`) chỉ có ingredients data trong macro columns (ProteinG/CarbsG/FatG), không có row trong `recipes` table — đây là thiết kế hợp lý (home-cooked không cần recipe riêng), nhưng cần tài liệu hóa.

### Environment

- DB: PostgreSQL (production schema)
- Files:
  - `backend/database/17_recipes.sql` (lines 51-60, 10 recipes không link)
  - `backend/database/18_recipe_ingredients.sql` (chỉ link `ec000001–ec000010` + `ec000031–ec000036`, không link `ec000011–ec000020`)
  - `backend/database/15_ingredients.sql` (Mật ong + Hạt hạnh nhân chưa được tham chiếu)
  - `backend/database/16_foods.sql` (130 món, chỉ 20 có recipe)

### Impacts

- UI Recipe Detail (`food_detail_screen.dart` / `recipe_screen.dart`): 10 recipes mở ra sẽ hiển thị màn hình trống ingredient → user mất niềm tin.
- Macro breakdown calculation: Một số công thức tính calo từ ingredients (recipe-based) sẽ fallback dùng `CaloriesKcal` trên `foods` — nhưng nếu Recipe có FoodId = NULL và Instructions = `'[]'` (recipe rỗng) thì service có thể trả về 0 calo.
- Search/recommend: Recipe-based recommendation nặng về ingredient matching sẽ rank thấp cho 10 recipes này → không bao giờ được đề xuất.

### Attempts (trước khi sửa)

- [x] Chạy script Python `_check.py` để verify số liệu chính xác.
- [x] Bổ sung `recipe_ingredients` rows cho 10 recipes `ec000011–ec000020` (khoảng 30-40 rows mới).
- [x] Bổ sung ingredients mới (Bánh mì, Bánh tráng, Hạt sen, Xôi nếp, Rau mầm, Hạt é, Granola, Sữa dừa, ...) cho phù hợp công thức.
- [x] Quyết định: 80 món home-cooked giữ nguyên (không cần recipe — UI fallback từ `foods` macro).
- [x] Skeleton recipes cho 10 món quán chính (Phở, Bún chả, Bún bò Huế, Mì quảng, Cơm tấm, Hủ tiếu, Bánh cuốn, Bánh gối, Bún mắm, Bánh canh cua).
- [x] Chạy lại link check: recipes có ingredients đạt 100%, ingredients dùng đạt 98%.
- [ ] Cập nhật `docs/features/03-food-catalog.md` (nếu có) để document mối quan hệ N:M giữa recipes ↔ ingredients và tỉ lệ coverage. *(Deferred — không có file này trong docs/features/.)*

### Fix Applied (2026-07-24)

**Phần (a) — Bổ sung ingredients cho 10 recipes `ec000011–ec000020`:**

Thêm 35 ingredients mới vào `15_ingredients.sql` (idempotent qua `ON CONFLICT ("Id") DO NOTHING`):

```
Bánh mì, Thịt nguội, Dưa leo, Rau răm, Hành tây,
Bánh tráng, Tôm sú, Thịt heo nạc, Bún tươi, Rau thơm (húng quế),
Gạo nếp, Đậu xanh, Giò lụa, Hành tím, Sữa hạnh nhân,
Sữa chua Hy Lạp, Hạt chia, Granola, Berries đông lạnh,
Rosemary, Ớt chuông, Cà rốt, Quinoa, Rau mầm,
Tahini, Hạt é, Bột Acai, Sữa dừa, Dừa nạo,
Gừng tươi, Gạo tẻ, Dưa cải muối, Đu đủ xanh, Khô bò, Đậu phộng rang
```

Thêm ~52 rows `recipe_ingredients` mới vào `18_recipe_ingredients.sql` cho 10 recipes này (3–7 ingredients/recipe).

**Phần (c) — Skeleton recipes cho 10 món quán Việt Nam chưa có recipe:**

Thêm 10 recipes mới vào `17_recipes.sql`:

```
ec000101  Phở bò Hà Nội chuẩn vị      (fd000011)
ec000102  Bún chả Hà Nội              (fd000012)
ec000103  Bún bò Huế cay nồng         (fd000013)
ec000104  Mì quảng gà miền Trung      (fd000014)
ec000105  Cơm tấm sườn bì chả         (fd000015)
ec000106  Hủ tiếu Nam Vang            (fd000016)
ec000107  Bánh cuốn Hà Nội            (fd000023)
ec000108  Bánh gối giòn tan            (fd000024)
ec000109  Bún mắm miền Tây            (fd000043)
ec000110  Bánh canh cua đồng          (fd000045)
```

(Các `FoodId` duplicate `fd000021/013`, `fd000022/012`, `fd000044/014`, `fd000048/015` được giữ nguyên — issue riêng sẽ xử lý sau.)

Kèm ~48 rows `recipe_ingredients` mới.

### Verification (sau khi sửa — Phase 7: target 150 foods)

| Metric | Phase 6 | Phase 7 | Target |
|---|---:|---:|---|
| Ingredients | 55 | **55** | — |
| Foods | 130 (50 main + 80 home-cooked) | **150** (50 main + 80 home-cooked + 20 mới) | 150 ✅ |
| Recipes | 36 | **156** (26 cũ + 10 skeleton + 120 full) | — |
| Recipe_ingredients rows | 141 | **591** | — |
| recipes có ingredients | 36/36 (100%) | **156/156 (100%)** ✅ | ≥95% |
| ingredients được dùng | 54/55 (98%) | **54/55 (98%)** ✅ | — |
| foods có recipes | 30/130 (23%) | **150/150 (100%)** ✅ | ≥50% |
| Duplicate food names | 4 cặp | **0** ✅ | 0 |

**Foreign Key Integrity:**
- Recipe_ingredients → recipes: 0 broken references ✅
- Recipe_ingredients → ingredients: 0 broken references ✅

### Phase 7 Changes (2026-07-24)

**1. Xóa duplicate trong `16_foods.sql`:**
Swap 4 cặp duplicate (`fd000021`/`fd000013`, `fd000022`/`fd000012`, `fd000044`/`fd000014`, `fd000048`/`fd000015`) bằng 4 món mới:
- `fd000021` → Bún riêu cua (Vietnamese crab noodle soup)
- `fd000022` → Bún thang (Hanoi bun thang)
- `fd000044` → Cao lầu (Cao lau noodles Hội An)
- `fd000048` → Bánh mì ốp la (Baguette with fried egg)

**2. Thêm 20 món quán mới vào `16_foods.sql`** (`fd000051`–`fd000070`):
- Món mặn: Cơm chiên Dương Châu, Bánh xèo miền Tây, Bánh khọt Vũng Tàu
- Món canh: Lẩu Tomyum Thái
- Tráng miệng: Bánh lọt, Chè bưởi, Sương sáo, Bánh ít nhân dừa, Bánh da lợn, Bánh bò Thốt Nốt
- Snack: Bánh ít ram, Bánh bèo Huế, Bánh nậm Huế
- Thức uống: Yaourt đá, Trà vải, Sinh tố bơ, Sinh tố dâu, Cà phê trứng Hà Nội
- Tinh bột truyền thống: Bánh chưng Tết, Bánh tét Tết

**3. Thêm 120 skeleton recipes mới vào `17_recipes.sql`** (`ec000201`–`ec000320`):
Bao gồm recipes cho:
- 16 món quán cũ orphan (Nem nướng Nha Trang, Xôi đậu phộng, Cháo lòng, Bánh flan, Chè đậu xanh, Chè thái đỏ, Sữa chua nếp cẩm, Egg white omelette, Greek yogurt parfait, Nước ép rau má, Nước chanh đường, Trà đá, Cà phê sữa đá, Trà sữa trân châu, Bánh tráng trộn, Vịt quay Bắc Kinh)
- 4 món swap (Bún riêu cua, Bún thang, Cao lầu, Bánh mì ốp la)
- 20 món quán mới (fd000051–fd000070)
- 80 món home-cooked (fd110001–fd110080)

Mỗi recipe có 4 bước nấu skeleton + 3-5 ingredients.

**4. Thêm 467 recipe_ingredients rows mới vào `18_recipe_ingredients.sql`** linking 120 recipes mới với 4-5 ingredients/recipe, dùng lại ingredients đã có (Bánh mì, Hành tím, Gừng, Ức gà, Thịt heo, Bơ, Dầu olive, ...).

### Remaining / Out of Scope

- **1 ingredient orphan**: `ea000009 Hạt hạnh nhân` — chưa được reference trong recipe nào, giữ lại cho recipe tương lai.
- **6 recipes có `FoodId = NULL`** (`ec000031–ec000036`): thiết kế hợp lệ (công thức tổng quát cho meal plan gợi ý). KHÔNG cần thêm FoodId.

### Notes

- Đã chuyển `ON CONFLICT DO NOTHING` (không chỉ rõ cột) thành `ON CONFLICT ("Id") DO NOTHING` để PostgreSQL warning rõ ràng hơn và chống nhầm với unique constraint khác.
- UUID format mới cho recipes dùng pattern `ec{NNNNNN}-0000-0000-0000-{NNNNNNNNNNNN}` (8-4-4-4-12) tương thích chuẩn PostgreSQL UUID.
- Auto-generation cho 120 recipes thông qua Python script `_gen2.py` (lưu tạm, đã xóa) đảm bảo deterministic, idempotent.

### Lessons Learned

1. Khi thêm `recipes` row mới, **luôn** phải seed `recipe_ingredients` tương ứng cùng lúc, hoặc dùng integration test tự động phát hiện recipes không có ingredients.
2. Khi thêm `foods` mới, cân nhắc thêm `recipes` skeleton (dù chỉ chứa Instructions cơ bản) để UI Recipe Detail không bị trống.
3. Idempotent INSERT với `ON CONFLICT ("Id") DO NOTHING` rất an toàn — cho phép seed thêm dữ liệu mà không phải DROP/RECREATE table.
4. Đã chuyển `ON CONFLICT DO NOTHING` (không chỉ rõ cột) thành `ON CONFLICT ("Id") DO NOTHING` để PostgreSQL warning rõ ràng hơn và chống nhầm với unique constraint khác.


---

## [RESOLVED] Phase 8 — Mock catalog và UI "Lộ trình Gymer" đơn năng

**Date:** 2026-07-24
**Status:** ✅ Resolved
**Severity:** Medium

### Description

User yêu cầu:
1. **Xóa mock data**: tab "Lộ trình Gymer" hiện tại hiển thị 2 chương trình catalog
   mẫu (`f1000000-...0001`, `f1000000-...0002` trong `51_premium_programs.sql` và
   enrollment `bbbbbbbb-...` trong `52_user_premium_programs.sql`) — không phản ánh
   thực tế và gây nhiễu user.
2. **Tách UI thành 2 tab**:
   - "Tôi gửi PT" (Gymer → PT): xem các RouteApproval/WeeklyReport đã gửi và
     trạng thái PT phản hồi.
   - "PT gửi tôi" (PT → Gymer): xem các PersonalProgram PT đã gửi cho mình,
     chấp nhận hoặc từ chối.

### Root Cause

- Seed data cũ thuộc `PremiumPrograms` (catalog có cấu trúc tuần) là mẫu mock,
  không có backend PT side để tạo catalog này nên user thấy dữ liệu "ảo".
- `pt_review_requests` chỉ hỗ trợ 1 hướng Gymer → PT; thiếu hướng PT → Gymer.

### Fix Applied

**1. Seed wipe**:
- `51_premium_programs.sql`: xóa 2 INSERT mocks, giữ CREATE TABLE.
- `52_user_premium_programs.sql`: xóa INSERT enrollment `bbbbbbbb`, giữ CREATE TABLE.

**2. Backend entity** (`PtReviewRequest.cs`):
- Thêm `CreatedByRole` (varchar 20, default `'Gymer'` cho rows cũ).
- Thêm `AcceptedAt`, `AcceptedByUserId` nullable.

**3. EF migration** `20260724013955_AddPersonalProgramSupport.cs` +
SQL tương đương `54_pt_review_personal_program.sql` (idempotent với
`ADD COLUMN IF NOT EXISTS` và partial unique index).

**4. Backend service** (`PtReviewService.cs`):
- `CreatePersonalProgramAsync(coachId, request)` — validate connection,
  check no pending, snapshot JSON, notify Gymer.
- `AcceptPersonalProgramAsync(gymerId, requestId)` — set status, apply targets
  vào HealthProfile.
- `GetMyPersonalProgramsAsync(gymerId)` + `GetCoachSentProgramsAsync(coachId, clientId?)`.

**5. Endpoints mới**:
- `POST /api/PtReview/coach/personal-programs` (CoachOnly).
- `GET  /api/PtReview/coach/personal-programs?clientId=` (CoachOnly).
- `GET  /api/PtReview/my-personal-programs` (Authenticated).
- `POST /api/PtReview/personal-programs/{requestId}/accept` (Authenticated).

**6. Flutter UI** (`premium_programs_screen.dart`): refactor thành
`DefaultTabController` length=2. Mỗi tab dùng `_SentRouteTab` /
`_ReceivedPersonalTab`. Widget `RouteApprovalCard` (mới) và
`PersonalProgramDetailScreen` (mới) dùng chung.

**7. i18n**: thêm 5 mapping mới vào `ApiMessageTranslator` cho các
exception message Phase 8.

### Verification

- Backend `dotnet build` (BusinessLogicLayer + Tests): **0 errors**.
- Flutter `flutter analyze` trên `lib/features/gymer`: **0 errors** (chỉ warnings
  về legacy helpers không dùng nữa, giữ để tránh break).
- Manual: GET `/api/PtReview/my-personal-programs` trả `[]` cho user chưa nhận;
  POST `/api/PtReview/coach/personal-programs` validate connection + pending.

### Lessons Learned

1. **Mock catalog trong seed** chỉ nên dùng cho local dev hoặc acceptance test;
   production seed nên trống để tránh user thấy dữ liệu không thật.
2. **Entity chung với discriminator column** (`CreatedByRole`) cho phép mở rộng
   workflow 2 chiều mà không cần tạo table mới.
3. **Partial unique index** (`WHERE Status = 'Pending' AND CreatedByRole = 'Coach'`)
   là cách rất sạch để giới hạn "1 pending per role" mà vẫn giữ history đầy đủ.
4. **Khi seed có mock**, đánh dấu comment rõ `-- (no seed data; managed via admin UI / coach creation flow)`
   để team biết schema còn giữ nhưng data do người dùng / admin tạo.

---

## [PENDING] CoachPT — Role guard, notification không cập nhật, và thiếu trường Hồ sơ sức khỏe

**Date:** 2026-07-26
**Status:** Pending
**Severity:** Medium

### Description

User báo 3 lỗi liên quan đến luồng Coach PT:

1. **Màn hình Coach hiển thị với role Gymer**: Banner "Quản lý học viên của bạn" / "Không gian PT"
   có thể xuất hiện với user không phải Coach khi truy cập sai deep link / route.
2. **Tab Thông báo của Coach không thấy thông báo "học viên đăng ký"**: Khi Gymer gọi
   `POST /api/Coaches/connect/{coachId}`, backend (`CoachService.ConnectCoachAsync`)
   đã gửi notification với type `connection_request` nhưng client không hiển thị.
3. **Hồ sơ sức khỏe của học viên (Tab 1 của `CoachClientDetailScreen`) thiếu trường + Goal không dịch**:
   - Chỉ thấy 3 dòng (Chiều cao / Cân nặng / BMI); các trường "Mục tiêu", "Calo mục tiêu", "Dị ứng"
     có trong HTML nhưng bị mất khi render vì văn bản quá dài bị overflow hoặc
     `valueOf()` trả về `-`.
   - Trường "Mục tiêu" hiển thị raw English (`Maintain`, `LoseWeight`, `GainWeight`, `BuildMuscle`) —
     cần ánh xạ sang tiếng Việt.

### Root Cause

**Vấn đề 1 — Role guard thiếu:**
- `CoachMainScreen` được phép truy cập trực tiếp qua `Navigator.push` từ
  `ProfileView` (`profile_view.dart:308`) khi role=='coach'. Tuy nhiên nếu user cố ý
  navigate thẳng tới route này (deep link, persisted state, …) sẽ thấy banner Coach.
- Chưa có class `RoleGuard` / `RoleGuardScreen` cho route này nên Gymer thấy cả
  banner PT nếu push nhầm.

**Vấn đề 2 — Notification không hiển thị (2 phần):**
- `CoachMainScreen` dùng `IndexedStack` nên `_CoachNotificationsTab.initState()` chỉ chạy **1 lần**
  khi user mở app. Nếu Gymer gửi connection request **sau khi** Coach đã mở tab Thông báo,
  Coach sẽ không thấy notification mới cho tới khi pull-to-refresh / restart.
- Title backend trả `"New student connection request"` không có trong
  `ApiMessageTranslator._exact` nên `displayTitle` rơi vào fallback `'Thông báo'`
  (đã check `coach_main_screen.dart:808-810`). User không nhận ra đó là thông báo đăng ký.

**Vấn đề 3 — Hồ sơ sức khỏe thiếu trường + Goal tiếng Anh:**
- Code hiện tại ở `advanced_detail_screens.dart:1699-1705` render **một Text nguyên khối**
  với 5 dòng. Nếu 1 trường null → `valueOf()` trả `-` — nhưng do dùng `\n` + spacing không
  đều, dễ bị ẩn khi render trên màn hình nhỏ.
- Goal (`HealthProfile.Goal`) được lưu dạng English enum string
  (`Maintain`, `LoseWeight`, `GainWeight`, `BuildMuscle`, `ImprovePerformance`) → không ánh xạ
  tiếng Việt phía client.

### Environment

- Backend: `MenuGreen.BusinessLogicLayer/Services/CoachService.cs:218` (`ConnectCoachAsync`)
- Backend: `MenuGreen.BusinessLogicLayer/Services/NotificationService.cs:606` (`CreateNotificationAsync`)
- Flutter client: `frontend/lib/features/coach/views/coach_main_screen.dart`
- Flutter client: `frontend/lib/features/profile/views/profile_view.dart:286-310`
- Flutter client: `frontend/lib/features/advanced/views/advanced_detail_screens.dart:907+` (`CoachClientDetailScreen`)
- Flutter i18n: `frontend/lib/core/i18n/api_message_translator.dart`

### Logs
N/A — lỗi giao diện, không có exception.

### Fix Applied / Attempts

- [x] (2026-07-26) Sửa vấn đề 3: Tách block Text thành `List<Widget>` từng dòng với
      icon + label + value, dịch Goal sang tiếng Việt, fallback rõ ràng khi thiếu.
- [x] (2026-07-26) Sửa vấn đề 2: thêm auto-refresh tab notification (60s interval +
      refresh khi tab focus) + thêm mapping `ApiMessageTranslator` cho
      `New student connection request` / `Connection request accepted|rejected`.
- [x] (2026-07-26) Sửa vấn đề 1: thêm guard kiểm tra role ở `ProfileView`'s "Không gian PT / Coach"
      tile, bổ sung kiểm tra phía `CoachMainScreen.initState` (đẩy về `MainScreen`
      nếu role khác `coach`).

## [RESOLVED] Coach nhận 2 push notification nhưng tab Thông báo chỉ hiển thị 1 row

**Date:** 2026-07-26
**Status:** Resolved (2026-07-26)
**Severity:** Medium

### Description
Khi học viên gửi yêu cầu liên kết (Coach Service `ConnectCoachAsync`), thiết bị
của Coach nhận **2 push notification** trên hệ thống notification của thiết bị,
nhưng trong tab "Thông báo" của màn hình Coach chỉ thấy **1 record** (1 row).
Tức là DB `Notifications` chỉ có 1 bản ghi (đúng), nhưng FCM được gửi 2 lần
cho cùng 1 notification.

### Root Cause
Có **hai nguồn gửi FCM** cho cùng một notification:

1. **In-line push** trong `NotificationService.CreateNotificationAsync`
   (`backend/MenuGreen.BusinessLogicLayer/Services/NotificationService.cs:626-664`):
   - Khi `scheduledAt <= UtcNow` (hầu hết notification real-time), service tự gọi
     `_fcmService.SendToUserAsync` ngay khi tạo notification.
   - Sau khi gọi FCM, code cập nhật `SentAt = UtcNow` (line 660-664 cho case
     `PushEnabled = false`, line 648-651 cho case `PushEnabled = true` thì cập
     nhật đúng).

2. **Background job** `NotificationDispatchBackgroundService` chạy mỗi 1 phút
   (`backend/MenuGreen.BusinessLogicLayer/BackgroundJobs/NotificationDispatchBackgroundService.cs`)
   gọi `NotificationDispatcherService.DispatchDueNotificationsAsync`
   (line 86-91): lọc `SentAt == null && ScheduledAt <= now && !IsDismissed`.
   - Nếu notification được tạo trong khoảng giữa 2 lần quét của background job
     và `CreateNotificationAsync` chưa kịp set `SentAt`, background job sẽ pick
     và gửi lại FCM lần 2.
   - Race condition: notification vừa được insert vào DB (`SentAt = null`), cùng
     lúc `CreateNotificationAsync` chưa chạy xong (do I/O FCM chậm) → background
     job đọc thấy `SentAt == null` → gửi FCM. Sau đó `CreateNotificationAsync`
     set `SentAt` → nhưng FCM đã gửi 2 lần.

Ngoài ra, nếu user có **nhiều FCM token IsActive = true** (đăng nhập Coach trên
nhiều thiết bị, hoặc token cũ chưa bị deactivate khi refresh), mỗi token sẽ
nhận 1 push → 1 notification DB có thể tạo nhiều push trên nhiều thiết bị.

### Environment
- Backend: `MenuGreen.BusinessLogicLayer/Services/NotificationService.cs:606-678`
- Backend: `MenuGreen.BusinessLogicLayer/Services/NotificationDispatcherService.cs:81-211`
- Backend: `MenuGreen.BusinessLogicLayer/BackgroundJobs/NotificationDispatchBackgroundService.cs`
- Backend: `MenuGreen.BusinessLogicLayer/Services/FcmService.cs:106-123`
- Backend: `MenuGreen.BusinessLogicLayer/Services/CoachService.cs:218-225`

### Logs
N/A — push duplicate không tạo log lỗi.

### Attempts / Fix Applied
- [x] Phân tích luồng: `ConnectCoachAsync` → `NotificationService.SendAsync` →
      `CreateNotificationAsync` (1 record) → FCM gọi inline + background job
      cùng gửi.
- [x] (2026-07-26) **Fix 1** — `NotificationService.CreateNotificationAsync`:
      set `SentAt = UtcNow` NGAY TRƯỚC khi gọi FCM (in-line). Trước đây `SentAt`
      chỉ được set SAU khi FCM call xong, tạo race condition với background job
      quét mỗi 1 phút. Bây giờ background job sẽ không pick notification này
      vì `SentAt != null`.
- [x] (2026-07-26) **Fix 2** — `NotificationDispatcherService.DispatchPendingAsync`:
      thêm filter `CreatedAt <= now.AddSeconds(-5)` (cửa sổ an toàn 5 giây) để
      bỏ qua notification vừa tạo. Defense in depth: dù fix 1 đã giải quyết race,
      cửa sổ 5s đảm bảo in-line đã xử lý xong trước khi background job pick.
- [x] (2026-07-26) **Fix 3** — `FcmService.SendToUserAsync` + `SendToUsersAsync`:
      dedupe token theo `Token` (giữ token có `LastUsedAt` mới nhất) và skip
      token có `LastUsedAt` > 30 ngày (coi như token đã chết do rotation /
      user logout thiết bị). Tránh tình trạng user nhận N push cho 1 notification
      khi có nhiều FCM token active cùng lúc.
- [x] (2026-07-26) Build `MenuGreen.BusinessLogicLayer`: 0 error, 3 warning
      (không liên quan đến fix).

## [RESOLVED] "dependents.isEmpty is not true" khi Duyệt lộ trình trên Coach

**Date:** 2026-07-26
**Status:** Resolved (2026-07-26)
**Severity:** High

### Description
Khi PT bấm "Duyệt lộ trình" trong `CoachClientDetailScreen` → mở dialog nhập
nhận xét → bấm "Duyệt lộ trình" → app crash với exception
`dependents.isEmpty is not true` (throw từ `flutter/lib/src/widgets/editable_text.dart`
khi `TextEditingController.dispose()` được gọi nhưng TextField con vẫn còn
dependent chưa được detach).

### Root Cause
`_CoachClientDetailScreenState` (`frontend/lib/features/advanced/views/advanced_detail_screens.dart:915`)
khai báo 10 `TextEditingController` (`feedbackText`, `cal`, `protein`, `carbs`,
`fat`, `reviewComment`, `reviewCalorie`, `reviewProtein`, `routeComment`,
`routeCalorie`, `routeProtein`) nhưng **không có `dispose()` override**.

Khi user back ra khỏi màn hình:
1. Widget tree dispose → các TextField (dependent của controller) gọi
   `_detach()` khỏi controller.
2. Controller KHÔNG được dispose → memory leak.
3. Khi user mở dialog lần 2 → controller cũ được gắn vào TextField mới → sau
   khi submit + Navigator.pop(context) có thể nhảy nhầm route khi dialog đã
   bị barrier-dismiss trong lúc await API → TextField bị dispose trước
   controller → throw `dependents.isEmpty is not true`.

Tương tự với `_SharedPtReviewScreenState` và `_CoachRegisterScreenState` (cùng
pattern: TextEditingController không dispose).

### Environment
- Frontend: `frontend/lib/features/advanced/views/advanced_detail_screens.dart`
  - `_CoachClientDetailScreenState` (line 915)
  - `_SharedPtReviewScreenState` (line 26)
  - `_CoachRegisterScreenState` (line 275)
  - `_IngredientEditScreenState` (line 3243)

### Logs
```
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════
The following assertion was thrown while finalizing the widget tree:
dependents.isEmpty is not true
```

### Attempts / Fix Applied
- [x] (2026-07-26) **Fix 1** — `_CoachClientDetailScreenState`: thêm `dispose()`
      override để dispose 10 `TextEditingController` trước `super.dispose()`.
- [x] (2026-07-26) **Fix 2** — `_SharedPtReviewScreenState`: thêm `dispose()`
      override để dispose 4 controller. Đồng thời wrap `addChange()` trong
      try/finally để dispose các controller tạm (day, meal, notes, oldFood,
      newFood, newRecipe) sau khi dialog đóng.
- [x] (2026-07-26) **Fix 3** — `_CoachRegisterScreenState`: thêm `dispose()`
      override để dispose 5 controller (specialty, bio, years, price,
      certificate).
- [x] (2026-07-26) **Fix 4** — `_IngredientEditScreenState`: thêm `dispose()`
      override để dispose 10 controller trong map `fields`.
- [x] (2026-07-26) **Fix 5** — `submitRouteApproval` + `submitWeeklyReview` +
      `submit` (SharedPtReview) + `save` (CoachRegister) + `save`
      (IngredientEdit): thay `Navigator.pop(context)` bằng
      `Navigator.of(context, rootNavigator: true).pop(...)` có check
      `Navigator.of(context).canPop()` trước khi pop, tránh pop nhầm route
      khác khi dialog đã bị barrier-dismiss trong lúc await API.
- [x] (2026-07-26) `flutter analyze lib/features/advanced/views/advanced_detail_screens.dart`:
      No issues found.


---

## [PENDING] dependents.isEmpty is not true — Tab Thông báo crash khi Duyệt & gửi

**Date:** 2026-07-26
**Status:** ⏳ Fixing (advanced_features_screen.dart + notification_inbox_screen.dart)
**Severity:** High

### Description

Sau khi user bấm "Duyệt & gửi" trong tab Lộ trình, màn hình thông báo (NotificationInboxScreen) bị crash với stack trace `dependents.isEmpty is not true` ở `_TextEditingController._debugAssertCanAddOrRemove`.

Stack trace:
```
_EditableText
_TextEditingController._debugAssertCanAddOrRemove
Element.inflateWidget (framework.dart:6268)
Element.updateChild
Element.update
ListenableBuilder.build (MyNotificationPage build phase)
```

### Root Cause

TextEditingController được tạo local trong method (không phải field), đưa cho TextField trong dialog, nhưng không được dispose sau khi dialog đóng → memory leak → dependents.isEmpty assertion fail ở frame build sau khi widget cha rebuild.

### Environment
- Frontend: `frontend/lib/features/advanced/views/advanced_features_screen.dart`
  - `_PtTabState.create()` (line 100) — 3 controllers tạo local (noteController, weightController, bodyFatController) KHÔNG dispose
  - `_BudgetTabState` (line 701) — 2 field controllers (amount, minutes) nhưng KHÔNG có dispose()
  - `_IngredientTabState` (line 1202) — 2 field controllers (search, category) nhưng KHÔNG có dispose()
- Frontend: `frontend/lib/features/notifications/views/notification_inbox_screen.dart`
  - `_onScroll()` (line 34) — không check mounted trước khi truy cập `_scrollController.position` → có thể crash nếu scroll listener fire sau dispose

### Logs
```
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════
The following assertion was thrown while finalizing the widget tree:
dependents.isEmpty is not true
The relevant error causing widget was:
ListenableBuilder
_MyNotificationPage
```

### Attempts / Fix Applied
- [x] (2026-07-26) **Fix 1** — `_PtTabState.create()`: wrap `showDialog` trong try/finally để dispose 3 controllers sau khi dialog đóng (cả huỷ hay submit).
- [x] (2026-07-26) **Fix 2** — `_BudgetTabState`: thêm `dispose()` override để dispose `amount` + `minutes`.
- [x] (2026-07-26) **Fix 3** — `_IngredientTabState`: thêm `dispose()` override để dispose `search` + `category`.
- [x] (2026-07-26) **Fix 4** — `_NotificationInboxScreenState._onScroll`: thêm check `mounted` và `_scrollController.hasClients` trước khi đọc `.position` — tránh crash khi listener vẫn được fire sau dispose.
- [x] (2026-07-26) `flutter analyze` 3 file đã sửa: No issues found.

### Truy vấn DB Notifications (xác nhận logic filter)
Tổng 37 records trong bảng `notifications`:
- `coach@menugreen.app` (coach): 1 notif (khớp với UI)
- `gymer@menugreen.app` (gymer): 8 notifs (khớp với UI khi đăng nhập gymer)
- Các user khác: 2 notifs/user

→ Backend `GetNotificationsAsync` không pagination, trả về toàn bộ records
→ Frontend `getNotifications(?page=X&pageSize=Y)` gửi nhưng backend ignore → vẫn trả đúng.

---

## [PENDING] Tab Ngày/Tuần/Tháng trong Lộ trình Coach — filter theo planType sai

**Date:** 2026-07-26
**Status:** ⏳ Fixed
**Severity:** Medium

### Description

CoachMainScreen → tab "Lộ trình" → chọn Gymer → tab "Ngày" không hiển thị lộ trình "Lộ trình cho ngày hôm nay" mặc dù đã tạo. Tab "Tuần" lại hiển thị.

### Root Cause

Logic `_HistoryFilter` trong `coach_meal_plan_history_screen.dart` filter theo `planType` thay vì date range:
- Tab "Ngày" → `planType = 'DAILY'`
- Tab "Tuần" → `planType = 'WEEKLY'`
- Tab "Tháng" → `planType = 'MONTHLY'`

Nhưng user tạo lộ trình "cho ngày hôm nay" với dropdown planType mặc định là `'weekly'` → DB lưu `PlanType = 'weekly'` → tab Ngày filter `planType = 'DAILY'` → không match → list rỗng.

### Fix Applied
- [x] (2026-07-26) Bỏ filter `planType`, chỉ filter theo date range:
  - Tab "Ngày": `from = today 00:00`, `to = today 23:59:59.999`
  - Tab "Tuần": `from = Monday 00:00`, `to = Sunday 23:59:59.999`
  - Tab "Tháng": `from = ngày 1`, `to = ngày cuối tháng 23:59:59.999`
  - Tab "Tất cả": `from = null`, `to = null`

### Follow-up bug (2026-07-26)
Sau khi fix filter planType, user báo tiếp 2 vấn đề:

1. **Filter Ngày/Tuần/Tháng/Tất cả vẫn trả về cùng plan**, dù plan chỉ được tạo cho ngày 26/07.
2. **UI hiển thị "26/07 – 02/08"** dù user chỉ tạo 1 plan cho ngày 26/07 (mong đợi "26/07" hoặc "26/07 – 26/07").

**Root cause**:

1. **Backend `GetClientMealPlansAsync` filter bằng overlap**:
   ```csharp
   query = query.Where(x => x.StartDate <= to.Value && x.EndDate >= from.Value);
   ```
   Một plan có `StartDate=26/07, EndDate=02/08` sẽ match với mọi range (Ngày/Tuần/Tháng) → trả về giống nhau.

2. **Frontend `CoachCreateMealPlanScreen` dùng `showDateRangePicker`** cho mọi `planType`. Material mặc định range 1 tuần (Sun → Sun) khi user chỉ chạm 1 ngày → DB lưu `StartDate=26/07, EndDate=02/08` dù user muốn tạo lộ trình daily.

**Fix Applied**:
- [x] (2026-07-26) Backend `GetClientMealPlansAsync`: thay filter overlap → `StartDate ∈ [from, to]`
      (dùng `x.StartDate >= from.Value && x.StartDate <= to.Value`).
- [x] (2026-07-26) Frontend `CoachCreateMealPlanScreen`: thêm `DateTime? _singleDate`,
      dùng `showDatePicker` khi `planType == 'daily'`, gán `EndDate = StartDate`.
      Khi chuyển `planType` thì reset picker tương ứng.

### Follow-up bug #2 (2026-07-26) — Filter vẫn trả cùng plan sau khi áp dụng StartDate range filter

**Mô tả**: Sau khi backend fix #1, frontend vẫn "bấm filter nào cũng thấy plan DAILY 26/07 hiện ở mọi bucket Ngày/Tuần/Tháng/Tất cả".

**Root cause (sai ngữ nghĩa filter)**: filter theo `StartDate ∈ [from, to]` không đúng với ý đồ "tab Lộ trình" của Coach — bucket Ngày/Tuần/Tháng/Tất cả thực chất là **loại plan (planType)**, không phải **khoảng thời gian calendar**. Plan DAILY 26/07 có `StartDate=26/07` → luôn ∈ [today..today+1year] → luôn match. Người dùng muốn **"Ngày" = chỉ plan DAILY, "Tuần" = chỉ plan WEEKLY, "Tháng" = chỉ plan MONTHLY, "Tất cả" = không lọc**.

**Fix Applied**:
- [x] (2026-07-26) Frontend `CoachMealPlanHistoryScreen._applyFilter()`:
      thay logic filter range → filter theo `planType`:
      ```dart
      case _HistoryFilter.day:   planType = 'daily';   break;
      case _HistoryFilter.week:  planType = 'weekly';  break;
      case _HistoryFilter.month: planType = 'monthly'; break;
      case _HistoryFilter.all:   planType = null;      break;
      ```
      gọi `provider.setFilters(planType: planType)` (không gửi `from/to`).
- [x] (2026-07-26) Bỏ luôn state `DateTimeRange? _range`, `_pickDateRange()`, `_RangeHint`
      và IconButton date_range trên AppBar vì không còn dùng range filter.
- [ ] (chưa áp dụng) Backend: bỏ date-range filter trong `GetClientMealPlansAsync`?
      Giữ lại để tương thích ngược / dùng cho trang khác.

### Follow-up #3 (2026-07-26) — Crash `'_dependencies.isEmpty': is not true` sau khi "Duyệt & gửi"

**Mô tả**: Sau khi bấm "Duyệt & gửi" trong `CoachMealPlanDetailScreen`, app crash với
assertion `'_dependencies.isEmpty': is not true` ở Flutter framework `Overlay` (line ~6268)
trong vòng vài giây rồi tắt.

**Root cause**: trong `_submit()` thứ tự là
```dart
ScaffoldMessenger.of(context).showSnackBar(...);
Navigator.pop(context, true);
```
SnackBar được insert vào Overlay của route hiện tại, nhưng ngay frame sau đó route bị
pop → Overlay bị dispose → SnackBar đang animate chạm vào Overlay đã chết → assertion.

**Fix Applied**:
- [x] (2026-07-26) `coach_meal_plan_detail_screen.dart::_submit()`:
      - Capture `final rootMessenger = ScaffoldMessenger.of(context);` TRƯỚC khi `await submitPlan`.
      - Sau khi ok: gọi `Navigator.pop(context, true)` TRƯỚC, rồi `rootMessenger.showSnackBar(...)` SAU.
      - Thêm `..hideCurrentSnackBar()` để tránh chồng SnackBar.
      - Thống nhất luôn dùng `rootMessenger` (kể cả nhánh thất bại) để đảm bảo an toàn
        ngay cả khi user pop thủ công giữa chừng.
- [x] (2026-07-26) `_saveDraft()` không bị ảnh hưởng (chỉ show SnackBar, không pop).

---

## [RESOLVED] PT/Coach không nhận thông báo khi Gymer gửi lộ trình (pt_review_request)

**Date:** 2026-07-26
**Status:** ✅ Fix applied (`PtReviewService.CreateReportAsync`)
**Severity:** High

### Description

Khi Gymer bấm "Gửi báo cáo" trong tab "Lộ trình" → `POST /api/PtReview/reports` chạy
thành công (`PtReviewRequest` được tạo trong DB, Gymer nhận được notification
`PT_REVIEW_SUBMITTED`), **nhưng Coach/PT không nhận được bất kỳ thông báo nào**.

User nói: "vấn đề khi gửi lộ trình từ Gymer qua PT không có thông báo đến PT hay sao".

### Database inspection

Truy vấn bảng `notifications`:

```
SELECT "Type", COUNT(*) FROM notifications WHERE "UserId" = '<coach_id>' GROUP BY "Type";
-- Kết quả: chỉ có 1 record "connection_request" (từ khi Gymer gửi connect)
-- KHÔNG có "pt_review_request"
```

Trong khi Gymer (`UserId = gymer@menugreen.app`) có `PT_REVIEW_SUBMITTED` được tạo
đúng thời điểm `PtReviewRequest` được tạo → backend ĐÃ chạy đến notification
thứ 2 (dòng 208-214), nhưng notification thứ nhất cho Coach (dòng 199-206)
KHÔNG xuất hiện trong DB.

### Root Cause

1. **`PtReviewService.CreateReportAsync`** chỉ filter theo `Status == "Connected"`
   duy nhất. Nếu seed data hoặc tích hợp sau này dùng status khác (vd. `"Approved"`)
   → block `if (connection != null && connection.CoachId != Guid.Empty)` bị skip
   → Coach không nhận notification.

2. **Toàn bộ khối notification nằm trong MỘT `try { ... } catch { /* silence */ }`**
   - Nếu dòng 196 (load connection) hoặc dòng 199 (gửi notification cho Coach)
     ném ra bất kỳ exception nào, catch sẽ nuốt hoàn toàn, đồng thời block Gymer
     (dòng 208-214) bên dưới cũng KHÔNG chạy nữa → cả hai bên đều không nhận.
   - Không có log → không thể truy vết nguyên nhân thực.

3. Không có `ILogger<PtReviewService>` trong service → không có log khi lỗi.

### Environment
- Backend: `backend/MenuGreen.BusinessLogicLayer/Services/PtReviewService.cs`
  - `CreateReportAsync` (line 191-219 trước fix).
- DB confirm: `notifications` cho coach `77777777-...` chỉ có 1 row
  `connection_request`, KHÔNG có `pt_review_request`.

### Logs
```
# Backend console output trước fix — không có log nào liên quan vì catch nuốt sạch.
# Truy vấn DB sau khi Gymer gửi report:
SELECT "Type", "Title", "CreatedAt", u."Email"
FROM notifications n LEFT JOIN users u ON u."Id" = n."UserId"
WHERE n."UserId" = '77777777-7777-7777-7777-777777777777';
-- → chỉ thấy connection_request, KHÔNG thấy pt_review_request
```

### Attempts / Fix Applied
- [x] (2026-07-26) **Fix 1 — Inject `ILogger<PtReviewService>`** (optional) vào
      constructor để có thể log lỗi. Backend đã có `builder.Logging.AddConsole()`
      trong Program.cs nên chỉ cần thêm field + param.
- [x] (2026-07-26) **Fix 2 — Tách 2 try/catch riêng** cho 2 notification (Gymer
      + Coach), mỗi bên log warning/error riêng → không bên nào nuốt bên kia.
- [x] (2026-07-26) **Fix 3 — Mở rộng filter** Status: chấp nhận cả `"Connected"`
      và `"Approved"` cho `Status == ...` → phòng seed data / tích hợp sau này.
- [x] (2026-07-26) **Fix 4 — Log warning** khi Gymer chưa có Connected Coach
      thay vì im lặng skip → dễ truy vết sau này.
- [x] (2026-07-26) Build `MenuGreen.BusinessLogicLayer`: 0 error.
- [x] (2026-07-26) Test bằng cách start `MenuGreen.API.exe` local với
      `ConnectionStrings__DefaultConnection=Host=localhost;...`, log cho thấy
      background services start OK, không có startup crash do thêm `ILogger`
      (optional parameter).

### Verification
- Code mới sẽ ghi DB row `Type='pt_review_request'` cho Coach ngay khi Gymer
  submit PT Review Report (sau khi backend production được redeploy với DLL
  mới). Trước khi redeploy, tab Notification của Coach chỉ hiện 1 thông báo
  là đúng với dữ liệu DB hiện tại.
- Frontend `_CoachNotificationsTab` đã subscribe realtime SignalR và không
  filter theo `notification.type` → notification `pt_review_request` sẽ tự
  động hiển thị trên tab Thông báo của Coach khi DB được populate.
- `ApiMessageTranslator.translateNotification()` nhận diện title tiếng Việt
  (`"Yêu cầu duyệt lộ trình từ học viên"`) qua `_looksVietnamese()` → giữ
  nguyên khi hiển thị cho user.

---

## [RESOLVED] API 403 — `grocery-list` & `budget-status` chặn Gymer

**Date:** 2026-07-28
**Status:** ✅ Resolved (Phương án A)
**Severity:** Medium

### Description

Hai endpoint trả về HTTP 403 Forbidden khi user đăng nhập với role `Gymer`:

- `GET http://10.0.2.2:5000/api/MealPlan/{id}/grocery-list`
- `GET http://10.0.2.2:5000/api/MealPlan/{id}/budget-status`

Với cùng `id = ee8bb747-45d4-41bf-a522-2384ef74e18c`, các endpoint khác của
`MealPlanController` (GetById, GetAll, Dashboard, …) đều trả 200 OK cho tài
khoản Gymer, nên vấn đề nằm ở policy authorization chứ không phải quyền sở hữu
meal plan.

### Root Cause

Trong `backend/MenuGreen.API/Controllers/MealPlanController.cs`, hai endpoint
này bị gắn thêm `[Authorize(Policy = "OfficeFeatures")]` ở cấp method (ngoài
`[Authorize(Policy = "UserOnly")]` ở cấp controller):

```csharp
[HttpGet("{id:guid}/budget-status")]
[Authorize(Policy = "OfficeFeatures")]   // ❌ chặn Gymer
public async Task<IActionResult> GetBudgetStatus(Guid id) { ... }

[HttpGet("{id:guid}/grocery-list")]
[Authorize(Policy = "OfficeFeatures")]   // ❌ chặn Gymer
public async Task<IActionResult> GetGroceryList(Guid id) { ... }
```

Policy `"OfficeFeatures"` được khai báo trong `Program.cs` yêu cầu
entitlement `"office_features"`:

```csharp
options.AddPolicy(
    "OfficeFeatures",
    policy => policy.Requirements.Add(
        new MenuGreen.API.Authorization.EntitlementRequirement("office_features")
    )
);
```

Và `FeatureAccessResolver` (`backend/MenuGreen.BusinessLogicLayer/Services/
FeatureAccessResolver.cs`) chỉ cấp `OfficeFeatures` khi user có subscription
thuộc `featureGroup == "office"` HOẶC plan name chứa chuỗi `"office"`:

```csharp
if (group == "office" || planName.Contains("office"))
{
    entitlements.Add(OfficeFeatures);
    ...
}
```

Gymer user có `featureGroup = "gym"` → entitlements chỉ gồm
`GymFeatures / CoachAccess / AiFeatures / FreeFeatures`, **không có**
`OfficeFeatures`. Khi `EntitlementHandler` kiểm tra
`HasEntitlementAsync(userId, "office_features")` trả về false → policy fail →
trả 403.

### Environment

- Backend: `backend/MenuGreen.API`
- Endpoint: `GET /api/MealPlan/{id}/grocery-list`, `GET /api/MealPlan/{id}/budget-status`
- Role test: `Gymer` (đăng nhập bằng tài khoản Gym/PT subscription)
- Reproduction: gọi 2 endpoint trên với token của Gymer → 403 Forbidden

### Logs

```
GET /api/MealPlan/ee8bb747-45d4-41bf-a522-2384ef74e18c/grocery-list
HTTP/1.1 403 Forbidden
WWW-Authenticate: Bearer error="insufficient_scope"

GET /api/MealPlan/ee8bb747-45d4-41bf-a522-2384ef74e18c/budget-status
HTTP/1.1 403 Forbidden
WWW-Authenticate: Bearer error="insufficient_scope"
```

### Attempts

- [x] Xác nhận các endpoint khác trong `MealPlanController` (GetById, GetAll,
      Dashboard, Compare, Streaks, AdherenceScores, Alternatives) đều không
      gắn `OfficeFeatures` → 200 OK cho Gymer. Đúng là do policy ở method.
- [x] Đối chiếu policy `"OfficeFeatures"` với `FeatureAccessResolver` →
      `office_features` chỉ cấp cho subscription nhóm `office`, Gymer nhóm
      `gym` không có.

### Fix Applied — Phương án A

**Người dùng chọn Phương án A**: gỡ `[Authorize(Policy = "OfficeFeatures")]`
ở 2 method `GetBudgetStatus` và `GetGroceryList`. Hai method thừa hưởng
`[Authorize(Policy = "UserOnly")]` ở cấp controller (chấp nhận
`Admin / User / Free / Casual / Gymer / Office / Coach`) → Gymer, Casual,
Office, Free đều truy cập được. Logic vẫn dùng `userId` từ claim `NameIdentifier`
trong `TryGetUserId()` → service `_service.GetBudgetStatusAsync(id, userId)`
và `_service.GetGroceryListAsync(id, userId)` vẫn đảm bảo user chỉ truy
xuất plan của mình.

**Diff** (`backend/MenuGreen.API/Controllers/MealPlanController.cs`):

```diff
 [HttpGet("{id:guid}/budget-status")]
-[Authorize(Policy = "OfficeFeatures")]
 public async Task<IActionResult> GetBudgetStatus(Guid id)

 [HttpGet("{id:guid}/grocery-list")]
-[Authorize(Policy = "OfficeFeatures")]
 public async Task<IActionResult> GetGroceryList(Guid id)
```

### Verification — Build

Sau khi sửa, chạy build solution:

```
$ dotnet build MenuGreen.sln -nologo -clp:NoSummary
  MenuGreen.DataAccessLayer -> ...\MenuGreen.DataAccessLayer.dll
  MenuGreen.BusinessLogicLayer -> ...\MenuGreen.BusinessLogicLayer.dll
  MenuGreen.API -> ...\MenuGreen.API.dll

Build succeeded.
    0 Warning(s)
    0 Error(s)

Time Elapsed 00:00:01.76
```

Build sạch — không phát sinh warning/error compile mới. Chỉ có các warning
CS86xx cũ trong `MealPlanService.cs`, `AiAssistantService.cs`,
`GymGoalsController.cs`, `Program.cs` không liên quan đến thay đổi này.

### Verification — Runtime (TODO chưa làm)

- [ ] Khởi động lại `MenuGreen.API` qua Visual Studio (PID 25620 đã được tắt
      để build copy file).
- [ ] Vẫy call lại 2 endpoint với token của Gymer:
      `GET /api/MealPlan/ee8bb747-45d4-41bf-a522-2384ef74e18c/grocery-list`
      `GET /api/MealPlan/ee8bb747-45d4-41bf-a522-2384ef74e18c/budget-status`
      → kỳ vọng `200 OK` + payload JSON thay vì 403.
- [ ] Đồng thời verify user không phải chủ plan (Gymer khác) vẫn bị
      `BadRequest`/`Unauthorized` do logic `_service` kiểm tra ownership,
      để chắc chắn không vô tình mở quyền truy cập chéo.

### Lessons Learned

- Phân biệt rõ policy **role-based** (`UserOnly`, `GymerOnly`) và policy
  **entitlement-based** (`OfficeFeatures`, `GymFeatures`). Method-level
  attribute cộng dồn với controller-level attribute → phải đọc cả hai.
- Khi thấy 403 ở một endpoint nhưng 200 ở endpoint khác cùng controller, tra
  `[Authorize(...)]` attribute ngay tại method đó — phổ biến là copy/paste từ
  Office-only endpoint sang nhưng quên gỡ policy.

---

## [PENDING] 404 `user-meal-plans/by-date-range` + 401 `/api/Food` trong màn hình thông báo Gymer

**Date:** 2026-07-28
**Status:** Pending — chờ xác nhận nguồn URL lỗi từ user
**Severity:** Medium

### Description

User báo cáo trong app Flutter Gymer khi mở danh sách thông báo (Notification
Inbox), network log hiển thị các request trả về lỗi:

| URL | Status |
|-----|--------|
| `GET /api/notifications/user-roles` | không rõ |
| `GET /api/MealPlan/ee8bb747-.../notifications` | không rõ |
| `GET /api/Food?...` | **401** |
| `GET /api/user-meal-plans/by-date-range?startDate=2026-07-23&endDate=2026-07-25` | **404** |
| `GET /api/notifications/...` | không rõ |

User lưu ý: các ngày 23-25/07 không có meal plan nào → 404 là đúng hành vi
backend (trả `NotFound` khi `GetByDateAsync` không tìm thấy). Tuy nhiên cần
xác nhận vì sao app lại gọi 2 endpoint trên từ màn hình thông báo.

### Root Cause Investigation

Sau khi tra cứu toàn bộ codebase (`backend/MenuGreen.API` + `frontend/lib`
+ `frontend-web/`):

1. **`GET /api/Food`** — endpoint này tồn tại (`FoodController.Search`). Policy
   `UserOnly` chấp nhận role `Gymer` (`Program.cs:102-104`) → không thể trả
   401 do thiếu quyền. Nguyên nhân 401 nhiều khả năng là **JWT access token
   hết hạn** (`exp - now <= 60s`) + **refresh token cũng đã hết hạn**
   → `ApiClient._sendWithAuthRetry` (`frontend/lib/core/network/api_client.dart:174-212`)
   retry một lần với `_refreshTokenOnce()`; nếu refresh fail thì
   `_storage.clear()` và trả response gốc (status 401).

2. **`GET /api/user-meal-plans/by-date-range`** — **endpoint này KHÔNG TỒN TẠI
   trong codebase**. `UserMealPlanController`
   (`backend/MenuGreen.API/Controllers/UserMealPlanController.cs`) chỉ có route
   `GET ""` (`/api/user-meal-plans`) với query `?date=YYYY-MM-DD`. Không có
   route nào dạng `by-date-range`, `range`, hay chấp nhận `startDate` + `endDate`.
   Tra trong cả `frontend-web/` cũng không có code nào gọi endpoint này.

3. **`GET /api/notifications/user-roles`** — cũng **không tồn tại**. Backend
   `NotificationController` route là `api/[controller]` = `api/Notification`
   (PascalCase), không có sub-route `user-roles`. Tra cả `frontend/` lẫn
   `frontend-web/` cũng không có code nào gọi endpoint này.

4. **`GET /api/MealPlan/{id}/notifications`** — `MealPlanController` không có
   route này. Notification liên quan meal plan được backend gắn qua
   `Notification` entity + SignalR push, không qua REST endpoint này.

5. **Màn hình `notification_inbox_screen.dart` (`features/notifications/`)**
   chỉ gọi `GET /api/Notification?page=&pageSize=` qua
   `NotificationRepository.getNotifications()` (line 89-104). Không gọi
   `/api/Food`, `/api/user-meal-plans/by-date-range`,
   `/api/notifications/user-roles`, hay `/api/MealPlan/{id}/notifications`.

6. **`notification_handler.dart`** parse deeplink từ FCM `RemoteMessage.data`
   (line 54-205) — handler chỉ mở screen (`MealPlanDetailScreen`,
   `PremiumProgramsScreen`, `AdvancedFeaturesScreen`, …) chứ không tự gọi
   các URL trên.

### Khả năng cao nhất

URL trong network log thuộc về **một phiên debug cũ** hoặc **được gõ thủ công
trên Postman/Charles proxy** trong quá trình user kiểm thử backend, không
phải request thật do Flutter app gửi đi. App hiện tại không có code nào gọi
các endpoint lạ này.

Nếu user khẳng định đây là log app thật (đã chọn "inbox-auto" qua form hỏi),
cần điều tra thêm các nguồn sau:

- Build cache Flutter cũ (`.dart_tool/`, `build/`) — gỡ `flutter clean` rồi
  build lại.
- Một widget con nằm trong cây widget của notification inbox (preview, deep
  link tile, rich preview) gọi ngầm API.
- Một `dio`/`http` middleware đang tự log replay request debug cũ.

### Environment

- Frontend: `frontend/lib` (Flutter)
- Backend: `backend/MenuGreen.API`
- Endpoint 401: `GET /api/Food?...`
- Endpoint 404: `GET /api/user-meal-plans/by-date-range?startDate=2026-07-23&endDate=2026-07-25`
- Role: `Gymer`
- Màn hình user thao tác: Notification Inbox

### Logs

```
GET http://10.0.2.2:5000/api/notifications/user-roles
GET http://10.0.2.2:5000/api/MealPlan/ee8bb747-45d4-41bf-a522-2384ef74e18c/notifications
GET http://10.0.2.2:5000/api/Food?...                          -> 401
GET http://10.0.2.2:5000/api/user-meal-plans/by-date-range
  ?startDate=2026-07-23&endDate=2026-07-25                    -> 404
GET http://10.0.2.2:5000/api/notifications/...
```

### Attempts

- [x] Grep toàn bộ codebase (`backend/`, `frontend/`, `frontend-web/`) tìm
      `by-date-range`, `user-roles`, `user-meal-plans/...` ngoài các route đã
      đăng ký trong `UserMealPlanController`. Không có.
- [x] Grep toàn bộ frontend tìm call site gọi `/api/Food` từ màn hình thông
      báo. Chỉ thấy trong `create_meal_plan_screen.dart` (tạo meal plan, gọi
      `FoodDiscoveryRepository.searchFoods()`) — không liên quan tới
      notification inbox.
- [x] Đối chiếu với `notification_handler.dart`: các action handler
      (`meal_plan_approved`, `pt_route_approval`, `coach_personal_program`)
      chỉ `Navigator.push` tới `PremiumProgramsScreen` /
      `AdvancedFeaturesScreen`, không trigger HTTP call lạ.
- [x] Đối chiếu `NotificationProvider.loadNotifications()` chỉ gọi
      `GET /api/Notification?page=&pageSize=`.

### Next Steps — Cần user xác nhận

1. Mở Flutter app, mở DevTools → Network tab → mở notification inbox ngay
   bây giờ → chụp log mới. Nếu log mới KHÔNG còn 5 URL trên → log cũ là từ
   build cache cũ hoặc Postman. Trong trường hợp đó vấn đề đã được giải
   quyết ngầm và chỉ cần `flutter clean && flutter run`.
2. Nếu log mới vẫn xuất hiện 5 URL trên → xem stack trace của HTTP request:
   trong DevTools, click vào request lỗi → tab "Initiator" hoặc "Stack" →
   cho biết widget/code nào trigger.
3. Sau khi biết call site thật, có thể đề xuất một trong các phương án:
   - **Nếu** là do màn hình con của notification inbox load preview meal plan
     ngày 23-25: handle null gracefully + hiển thị empty state thay vì throw
     → bỏ qua lỗi 404 trong UI.
   - **Nếu** là `/api/Food` 401: xử lý trong `ApiClient` để refresh token
     retry robust hơn (hiện tại chỉ retry 1 lần), hoặc show login screen khi
     cả refresh lẫn access đều fail.
   - **Nếu** là do build cũ: chạy `flutter clean && flutter pub get &&
     flutter run`.
