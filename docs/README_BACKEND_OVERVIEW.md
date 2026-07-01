# MenuGreen Backend Overview

Tai lieu tom tat co che hoat dong backend MenuGreen, tach theo Database, Security, Architecture.

---

## 1) Architecture

### 1.1 Tong quan cac lop

He thong theo N-Tier (Presentation -> Business Logic -> Data Access):

- Presentation: MenuGreen.API (ASP.NET Core Web API)
- Business Logic: MenuGreen.BusinessLogicLayer (services, helpers, validations, DTOs)
- Data Access: MenuGreen.DataAccessLayer (DbContext, repositories, UnitOfWork)

Luong xu ly chinh:

1. Controller nhan HTTP request.
2. Controller goi service o BusinessLogicLayer.
3. Service dung UnitOfWork/Repository truy cap DbContext.
4. Tra ket qua ve DTO/response cho controller.

### 1.2 Dependency Injection

- DataAccessLayer duoc dang ky bang AddDataAccessLayer().
- BusinessLogicLayer duoc dang ky bang AddBusinessLogicLayer().
- Moi service chinh duoc inject theo Interface.

### 1.3 API va routing

- Base route: /api/[controller].
- Swagger bat mac dinh.
- CORS policy: AllowAll.
- Health, profile, allergy, tracking, subscription, recommendation, notification, AI assistant, etc. duoc tach controller rieng.

### 1.4 Cache va external services

- Redis cache neu co Redis:ConnectionString hoac REDIS_URL.
- Neu khong co Redis thi dung in-memory cache.
- Firebase Admin dung cho Google sign-in (neu co Firebase:CredentialPath).

---

## 2) Database

### 2.1 Provider va DbContext

- Database: PostgreSQL (EF Core + Npgsql).
- DbContext: ApplicationDbContext.
- Cau hinh entity bang Fluent API tu assembly (ApplyConfigurationsFromAssembly).

### 2.2 Connection string

Uu tien theo thu tu:

1. ConnectionStrings:DefaultConnection (Npgsql format).
2. DATABASE_URL (uri) -> tu dong convert sang Npgsql format.

Neu khong co se throw exception khi khoi dong.

### 2.3 Nhom entity chinh (rut gon)

- Auth & Account: User, Role, Session, EmailVerification, PasswordResetToken
- Profile & Health: Profile, HealthProfile, WeightLog, NutritionSnapshot
- Allergy & Catalog: Allergy, UserAllergy, Food, Ingredient, Recipe, RecipeIngredient, FoodAllergenTag
- Tracking: MealLog
- Recommendation & AI: RecommendationHistory, RecommendationFeedback, AiConversation, AiMessage, UserAiProfile
- Subscription & Payment: SubscriptionPlan, UserSubscription, SubscriptionTransaction, Subscription, Payment, SepayTransaction
- Notification & Analytics: Notification, NotificationSetting, ActivityLog

### 2.4 Seed data

- Huong dan ghi chu trong Program.cs: chay `backend/seeddata.sql` sau khi migrations.

---

## 3) Security

### 3.1 Authen

- JWT Bearer Authentication.
- Access token + refresh token.
- Refresh token luu vao Session table (ExpiresAt = 7 ngay).

### 3.2 OTP va khoi phuc mat khau

- Dang ky: tao EmailVerification (OTP 6 so, het han 10 phut).
- Verify OTP: set EmailConfirmed + IsActive.
- Forgot password: tao OTP moi, invalidate OTP cu chua verify.
- Reset password: verify OTP, reset password, xoa tat ca Session cua user.

### 3.3 Role-based Authorization

- Policy: AdminOnly va UserOnly.
- Controller admin bat buoc role Admin.
- Cac API user thong thuong bat buoc [Authorize] + UserOnly.

### 3.4 Password hashing

- BCrypt.Net dung de hash password.

### 3.5 Google Sign-In

- Firebase Admin verify Google ID token.
- Neu user chua ton tai thi tao user + profile + health profile.

---

## 4) Dich vu chinh (Business Logic)

- AuthService: register/login/refresh/logout/OTP/forgot-reset password/Google login.
- ProfileService, HealthProfileService: cap nhat ho so ca nhan va suc khoe.
- NutritionTrackingService: meal logs, weight logs, daily summary, dashboard.
- RecommendationService: goi y mon an (rule-based).
- SepayPaymentService: xu ly thanh toan, webhook (chi tiet o doc SePay).
- NotificationService, CatalogService, Food/Ingredient/Recipe services.
- NutritionWarningsBuilder: canh bao calo/macro (deviation).

---

## 5) Luong API mau (rut gon)

### 5.1 Auth

- POST /api/Auth/register
- POST /api/Auth/verify-otp
- POST /api/Auth/login
- POST /api/Auth/refresh-token
- POST /api/Auth/logout
- POST /api/Auth/forgot-password
- POST /api/Auth/reset-password
- POST /api/Auth/google

### 5.2 Profile & Health

- GET/PUT /api/Profile/me
- GET /api/Profile/me/summary
- GET /api/Profile/me/completion
- GET/PUT /api/HealthProfile/me
- POST /api/HealthProfile/me/calculate
- PATCH /api/HealthProfile/me/goal

### 5.3 Nutrition tracking

- CRUD /api/NutritionTracking/meal-logs
- GET /api/NutritionTracking/daily
- GET /api/NutritionTracking/dashboard
- CRUD /api/NutritionTracking/weight-logs

---

## 6) Diem can luu y van hanh

- CORS AllowAll dang bat; can xem xet si chinh khi len production.
- JWT secret key va Firebase credential can dua vao environment.
- Redis khong bat buoc, he thong tu fallback to in-memory.
- Khi deploy Render: PORT va DATABASE_URL co the duoc inject.
