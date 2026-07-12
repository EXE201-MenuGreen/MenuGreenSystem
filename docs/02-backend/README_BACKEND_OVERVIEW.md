# MenuGreen Backend — Overview

> **Last updated:** 2026-07-12 — Phản ánh đúng trạng thái hiện tại của codebase.
>
> **Đã sửa:** Xóa tuyên bố "CORS AllowAll đang bật" (đã có whitelist + default origins), bỏ mọi mention về Render (dự án deploy lên AWS Lightsail), bổ sung mục Migration + Admin endpoint, sửa mapping JWT key đúng với Program.cs.

Tài liệu tóm tắt cơ chế hoạt động backend MenuGreen, tách theo **Architecture**, **Database**, **Security**, **Business Logic**.

---

## 1) Architecture

### 1.1 Tổng quan các lớp (N-Tier)

```
HTTP Request
    ↓
[MenuGreen.API]              ← Presentation (ASP.NET Core Web API + SignalR)
    ↓ gọi
[MenuGreen.BusinessLogicLayer] ← Business Logic (services, helpers, validations, DTOs)
    ↓ dùng
[MenuGreen.DataAccessLayer]  ← Data Access (EF Core DbContext, repositories, UnitOfWork)
    ↓
[PostgreSQL]                ← Database
```

**Luồng xử lý chính:**

1. Controller nhận HTTP request, validate input.
2. Controller gọi service ở BusinessLogicLayer.
3. Service dùng `UnitOfWork` + `Repository` truy cập `DbContext` (EF Core).
4. Service trả kết quả về DTO/response cho controller.
5. Controller serialize JSON trả về client.

### 1.2 Dependency Injection

- `DataAccessLayer` đăng ký qua extension `AddDataAccessLayer()`.
- `BusinessLogicLayer` đăng ký qua extension `AddBusinessLogicLayer()`.
- Mỗi service chính được inject qua **interface** (`IXxxService`), không inject class trực tiếp.
- Repositories cũng theo pattern `IXxxRepository`.

### 1.3 API và routing

- **Base route:** `/api/[controller]` (vd `/api/Auth/login`, `/api/Profile/me`).
- **Swagger UI** bật mặc định (kèm nút Authorize để paste JWT).
- **CORS:** whitelist cứng trong code (`defaultOrigins`, xem line 88 `Program.cs`) + whitelist bổ sung từ `AllowedOrigins` config (Doppler `ALLOWEDORIGINS` env). Wildcard `*` chỉ bật khi `ASPNETCORE_ENVIRONMENT=Development` (qua `builder.Environment.IsDevelopment()`) hoặc khi `ALLOWEDORIGINS=*`.
- **Rate limiting:** 100 req / 1 phút / IP (global limiter qua `PartitionedRateLimiter`).
- **Health checks:** `/health/live`, `/health/ready`, `/health`.
- **SignalR hub:** `/notificationHub` (real-time notifications, đọc JWT từ query string).

### 1.4 Cache và external services

| Service                | Config key                  | Fallback                              |
|------------------------|------------------------------|---------------------------------------|
| Redis                  | `Redis:ConnectionString`    | `REDIS_URL` env                       |
| Firebase Admin (FCM)   | `Firebase:CredentialPath`   | Optional (Google sign-in chỉ enable nếu có) |
| Doppler                | CLI chạy ngoài (CD workflow)| Không có trong app                     |
| Computer Vision microservice | `CVService:BaseUrl` + `CVService:ApiSecretKey` | Optional |
| Nutrition AI worker    | `NutritionAssistant:WorkerUrl` | Optional                              |
| Email (Resend)         | `Resend:ApiKey`, `Resend:FromEmail`, `Resend:FromName` | Optional |

Nếu **Redis không có** → app tự fallback in-memory cache (không throw).

---

## 2) Database

### 2.1 Provider và DbContext

- **Database:** PostgreSQL (EF Core + Npgsql).
- **DbContext:** `ApplicationDbContext`.
- **Cấu hình entity:** Fluent API qua `ApplyConfigurationsFromAssembly` (mỗi entity có 1 file `IEntityTypeConfiguration<T>` riêng).

### 2.2 Connection string resolution

Thứ tự ưu tiên (xem `ConnectionStringHelper.ResolvePostgresConnectionString`):

1. `ConnectionStrings:DefaultConnection` (Npgsql format `Host=...;Port=...;Database=...;Username=...;Password=...`).
2. `DATABASE_URL` (URI format `postgresql://user:pass@host:port/db`) → tự convert sang Npgsql.

> Doppler secret tương ứng: `CONNECTIONSTRINGS__DEFAULTCONNECTION` (đã chuẩn hóa). CD script inject thẳng vào `.env` dưới key `ConnectionStrings__DefaultConnection=...`.

Nếu **không có** cả hai → app throw exception khi khởi động.

### 2.3 EF Core Migration

- **Tự động chạy lúc startup** (xem `Program.cs`). Không cần `efbundle` hay chạy `dotnet ef database update` thủ công trong container.
- Migration files ở `MenuGreen.DataAccessLayer/Migrations/`. Mỗi migration là 1 file `.cs` + `.Designer.cs` + snapshot.
- **Manual trigger:** Có sẵn endpoint admin `POST /api/AdminMigration/migrate` (xem `AdminMigrationController.cs`) — chỉ dùng khi auto-migration fail.

### 2.4 Seed data

Sau khi chạy migration, nếu cần seed thêm (admin user, sample categories...), xem `backend/seeddata.sql`. CD workflow **không tự chạy file này** — chạy thủ công nếu cần:

```bash
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME < seeddata.sql
```

### 2.5 Nhóm entity chính

| Nhóm                      | Entities                                                                                                    |
|---------------------------|-------------------------------------------------------------------------------------------------------------|
| Auth & Account            | `User`, `Role`, `Session`, `EmailVerification`, `PasswordResetToken`                                       |
| Profile & Health          | `Profile`, `HealthProfile`, `WeightLog`, `NutritionSnapshot`                                                |
| Allergy & Catalog         | `Allergy`, `UserAllergy`, `Food`, `Ingredient`, `Recipe`, `RecipeIngredient`, `FoodAllergenTag`              |
| Tracking & Planning       | `MealLog`, `MealPlanHeader`, `MealPlanItem`                                                                 |
| Recommendation & AI       | `RecommendationHistory`, `RecommendationFeedback`, `AiConversation`, `AiMessage`, `UserAiProfile`            |
| Subscription & Payment    | `SubscriptionPlan`, `UserSubscription`, `SubscriptionTransaction`, `Subscription`, `Payment`, `SepayTransaction` |
| Notification & Analytics  | `Notification`, `NotificationSetting`, `ActivityLog`                                                        |

Chi tiết từng entity (fields, relationships): xem [`backend_models_documentation.md`](./backend_models_documentation.md).

---

## 3) Security

### 3.1 Authentication

- **JWT Bearer Authentication** với secret key lấy từ `JwtSettings:SecretKey` (Doppler secret `JWT_SECRET` hoặc `JWTSETTINGS__SECRETKEY`).
- **Access token** (short-lived, trong Authorization header) + **Refresh token** (lưu DB `Session` table, ExpiresAt = 7 ngày).
- JWT Issuer/Audience: `JwtSettings:Issuer` / `JwtSettings:Audience` (Doppler `JWT_ISSUER` / `JWT_AUDIENCE`).

### 3.2 OTP và khôi phục mật khẩu

- **Đăng ký:** Tạo `EmailVerification` (OTP 6 số, hết hạn 10 phút).
- **Verify OTP:** Set `EmailConfirmed = true` + `IsActive = true`.
- **Forgot password:** Tạo OTP mới, invalidate OTP cũ chưa verify.
- **Reset password:** Verify OTP, hash password mới, xóa tất cả `Session` cũ của user (force logout mọi thiết bị).

### 3.3 Role-based Authorization

- Policies: `AdminOnly`, `UserOnly`, `CoachOnly`.
- Controller admin bắt buộc role `Admin` (check qua policy `AdminOnly`).
- API user thông thường bắt buộc `[Authorize]` + policy `UserOnly` (chấp nhận role `User`, `Admin`, `Free`, `Pro`).
- API coach bắt buộc policy `CoachOnly` (chấp nhận role `Coach`, `Admin`).

### 3.4 Password hashing

- `BCrypt.Net` dùng để hash password (cost factor mặc định).

### 3.5 Google Sign-In

- `FirebaseAdmin` verify Google ID token.
- Nếu user chưa tồn tại → tạo user + profile + health profile mặc định.
- **Optional:** chỉ enable nếu `Firebase:CredentialPath` có giá trị hợp lệ.

---

## 4) Business Logic — Services chính

| Service                      | Chức năng                                                                                |
|------------------------------|------------------------------------------------------------------------------------------|
| `AuthService`                | register, login, refresh, logout, OTP, forgot/reset password, Google login              |
| `ProfileService`             | Cập nhật hồ sơ cá nhân                                                                  |
| `HealthProfileService`       | Cập nhật thông số sức khỏe, tính toán mục tiêu dinh dưỡng                              |
| `NutritionTrackingService`   | Meal logs, weight logs, daily summary, dashboard                                        |
| `RecommendationService`      | Gợi ý món ăn (rule-based)                                                               |
| `SepayPaymentService`        | Xử lý thanh toán, webhook SePay                                                         |
| `NotificationService`        | Push notification qua FCM + SignalR realtime                                            |
| `CatalogService`             | CRUD foods, ingredients, recipes                                                         |
| `NutritionWarningsBuilder`   | Cảnh báo calo/macro (deviation so với target)                                           |

---

## 5) Luồng API mẫu (rút gọn)

### 5.1 Auth

| Method | Endpoint                        | Mô tả                       |
|--------|----------------------------------|------------------------------|
| POST   | `/api/Auth/register`            | Đăng ký (gửi OTP email)    |
| POST   | `/api/Auth/verify-otp`          | Xác nhận OTP                |
| POST   | `/api/Auth/login`               | Đăng nhập                   |
| POST   | `/api/Auth/refresh-token`       | Refresh access token        |
| POST   | `/api/Auth/logout`              | Đăng xuất (revoke session)  |
| POST   | `/api/Auth/forgot-password`     | Gửi OTP reset               |
| POST   | `/api/Auth/reset-password`      | Reset password với OTP      |
| POST   | `/api/Auth/google`              | Google sign-in              |

### 5.2 Profile & Health

| Method | Endpoint                              | Mô tả                         |
|--------|----------------------------------------|--------------------------------|
| GET    | `/api/Profile/me`                     | Lấy profile hiện tại          |
| PUT    | `/api/Profile/me`                     | Cập nhật profile              |
| GET    | `/api/Profile/me/summary`             | Tóm tắt profile               |
| GET    | `/api/Profile/me/completion`          | % hoàn thành profile          |
| GET    | `/api/HealthProfile/me`               | Lấy health profile            |
| PUT    | `/api/HealthProfile/me`               | Cập nhật health profile       |
| POST   | `/api/HealthProfile/me/calculate`     | Tính lại target dinh dưỡng    |
| PATCH  | `/api/HealthProfile/me/goal`          | Đổi mục tiêu (gain/lose/maintain) |

### 5.3 Nutrition tracking

| Method | Endpoint                                  | Mô tả                    |
|--------|--------------------------------------------|---------------------------|
| GET/POST/PUT/DELETE | `/api/NutritionTracking/meal-logs` | CRUD meal logs            |
| GET    | `/api/NutritionTracking/daily`            | Tổng quan trong ngày      |
| GET    | `/api/NutritionTracking/dashboard`        | Dashboard metrics         |
| GET/POST/PUT/DELETE | `/api/NutritionTracking/weight-logs` | CRUD weight logs         |

---

## 6) Configuration & Environment

### 6.1 Env loading order

1. **`appsettings.json`** (default, có trong repo) — development defaults.
2. **`appsettings.{ASPNETCORE_ENVIRONMENT}.json`** — env-specific override.
3. **Environment variables** — override mọi thứ (CD inject từ Doppler vào `.env`).
4. **Command-line args** — cao nhất.

### 6.2 Production env (Doppler → `.env`)

Đầy đủ danh sách secrets: xem [`../01-deployment/SECRETS_MANAGEMENT.md`](../01-deployment/SECRETS_MANAGEMENT.md).

Tóm tắt các key **bắt buộc** để app khởi động:

| Key                              | Bắt buộc | Mục đích                                |
|----------------------------------|-----------|------------------------------------------|
| `ConnectionStrings__DefaultConnection` | ✅ | PostgreSQL connection string         |
| `JwtSettings__SecretKey`         | ✅        | JWT signing key                          |
| `JwtSettings__Issuer`            | ⚠️        | JWT issuer (optional nhưng khuyến nghị) |
| `JwtSettings__Audience`          | ⚠️        | JWT audience                            |
| `ASPNETCORE_ENVIRONMENT`        | ✅        | `Production` (hoặc `Staging`)           |
| `ASPNETCORE_URLS`                | ✅        | `http://+:5000`                          |

Tùy chọn (app chạy được nhưng thiếu tính năng):

- `REDIS_URL` — nếu không có, fallback in-memory cache.
- `Resend__*` — nếu không có, không gửi email được.
- `Firebase__CredentialPath` — nếu không có, Google sign-in disabled.
- `CVService__*` — nếu không có, food recognition bằng AI không khả dụng.

---

## 7) Deploy

Xem [`../01-deployment/ARCHITECTURE.md`](../01-deployment/ARCHITECTURE.md) và [`../01-deployment/CI_CD.md`](../01-deployment/CI_CD.md).

**Tóm tắt:**

- Image build qua GitHub Actions (`backend-ci.yml`) → push lên Docker Hub `:main`.
- Deploy qua `backend-cd.yml` → SCP files + SSH chạy `deploy-server.sh` trên AWS Lightsail.
- **App tự chạy EF Core migration khi startup.**
- **Auto-rollback** nếu health check fail 30 lần + **EXIT trap fail-safe** cho mọi lỗi không lường trước.

---

## 8) Lưu ý vận hành

- CORS whitelist đã được fix cứng trong code (`defaultOrigins`) + override qua `AllowedOrigins` env (Doppler). **Không nên dùng `*` cho production.**
- JWT secret key và Firebase credential **phải** ở environment (Doppler), không hardcode.
- Redis không bắt buộc — hệ thống tự fallback in-memory cache nếu không kết nối được.
- Admin migration endpoint (`POST /api/AdminMigration/migrate`) chỉ dành cho emergency recovery, không nên gọi trong code path bình thường.
- Khi thêm EF Core migration mới: tạo file local → commit → push → CD tự build image + container mới apply migration lúc startup.
