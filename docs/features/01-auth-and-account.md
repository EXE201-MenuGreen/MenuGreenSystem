# 01. Auth & Account

**Status:** API Done · UI Done
**Last updated:** 2026-07-08

**Related controllers:**
- `backend/MenuGreen.API/Controllers/AuthController.cs`
- `backend/MenuGreen.API/Controllers/OnboardingController.cs`
- `backend/MenuGreen.API/Controllers/ProfileController.cs`
- `backend/MenuGreen.API/Controllers/HealthProfileController.cs`

**Related Flutter features:**
- `frontend/lib/features/auth/`
- `frontend/lib/features/onboarding/`

---

## 1. Overview

Nhóm tính năng nền tảng xử lý vòng đời tài khoản người dùng:

- **Authentication** — đăng ký, đăng nhập (email/mật khẩu + Google), OTP email, refresh token, đặt lại mật khẩu.
- **Onboarding** — 5 bước thu thập thông tin cơ bản, sức khỏe, mục tiêu, dị ứng, hồ sơ AI; gate vào app.
- **Profile** — xem/sửa hồ sơ cá nhân, avatar, đổi mật khẩu.
- **Health Profile** — số đo cơ thể (chiều cao, cân nặng), mức vận động, mục tiêu ăn uống; tự động tính BMR/TDEE/BMI/Target Calories/Macro Targets (xem chi tiết formula tại [`10-vietnam-local-features.md`](./10-vietnam-local-features.md)).

---

## 2. Business Rules

### 2.1 Authentication

- Email là duy nhất trong hệ thống.
- Mật khẩu đăng ký phải đạt chính sách (độ dài tối thiểu, có chữ hoa/thường/số/ký tự đặc biệt — kiểm tra tại controller).
- Sau khi đăng ký email, bắt buộc nhập OTP để kích hoạt tài khoản (`EmailConfirmed = true`).
- OTP có thời hạn và giới hạn số lần nhập sai.
- Access token có TTL ngắn; refresh token dùng để gia hạn; `ApiClient` tự refresh khi access token hết hạn.
- Đăng nhập Google trả về cùng cấu trúc token như email/password.
- **Message convention:** backend response tiếng Anh; Flutter dịch qua `localizeAuthMessage` tại `frontend/lib/features/auth/utils/auth_error_messages.dart` trước khi hiển thị user (xem rule `backend-english-frontend-vietnamese-i18n.mdc`).

### 2.2 Onboarding

- Onboarding có **5 bước** theo thứ tự: Basic Info → Health Profile → Goal/Activity → Allergy → User Ai Profile.
- Sau khi complete, backend tự động tính `NutritionSnapshot` ban đầu dựa trên health profile.
- App gate: user chưa complete onboarding sẽ bị điều hướng về onboarding khi mở MainScreen (dùng `GET /api/Profile/me/completion`).
- Có thể cập nhật lại health profile sau onboarding; recalculate được trigger tự động.

### 2.3 Profile

- Avatar upload qua multipart; backend lưu URL trong `Profile.AvatarUrl`.
- Đổi mật khẩu yêu cầu mật khẩu hiện tại đúng.
- Cập nhật health profile → trigger recalculate BMR/TDEE/Target/Macro.

### 2.4 Health Profile & Nutrition Calculation

- Dùng **Mifflin-St Jeor** cho BMR; activity multiplier (1.2 / 1.375 / 1.55 / 1.725) cho TDEE.
- Target Calories = TDEE ± delta theo goal (-500/+200/+300).
- Macro targets: 30/40/30 (protein/carbs/fat) mặc định; 35/40/25 cho build muscle.
- Minimum target: **1200 kcal** (safety floor).
- Chi tiết công thức và nguồn khoa học: xem [Appendix A trong `10-vietnam-local-features.md`](./10-vietnam-local-features.md#appendix-a-nutrition-calculation-formulas).

---

## 3. API Endpoints

### 3.1 Auth (AuthController)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Auth/register` | Đăng ký email/mật khẩu, gửi OTP (rate-limited bởi OtpPolicy) |
| `POST` | `/api/Auth/verify-otp` | Xác thực OTP kích hoạt tài khoản |
| `POST` | `/api/Auth/forgot-password` | Yêu cầu reset mật khẩu (rate-limited bởi OtpPolicy) |
| `POST` | `/api/Auth/reset-password` | Đặt lại mật khẩu qua token |
| `POST` | `/api/Auth/login` | Đăng nhập email/mật khẩu |
| `POST` | `/api/Auth/refresh-token` | Refresh access token |
| `POST` | `/api/Auth/logout` | Đăng xuất, revoke session |
| `POST` | `/api/Auth/google` | Đăng nhập Google |

**Tổng: 8 endpoint.** Lưu ý: Không có `resend-otp` endpoint riêng — client gọi lại `register` để gửi OTP mới.

### 3.2 Onboarding (OnboardingController)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Onboarding/complete` | Đánh dấu hoàn thành onboarding (tạo HealthProfile + allergy + ai profile) |

**Tổng: 1 endpoint.** Trạng thái onboarding (`GET /Profile/me/completion`) nằm trong ProfileController.

### 3.3 Profile (ProfileController)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Profile/me` | Lấy profile hiện tại |
| `GET` | `/api/Profile/me/summary` | Tóm tắt profile (gọn hơn) |
| `GET` | `/api/Profile/me/completion` | Kiểm tra mức độ hoàn thiện profile (onboarding gate) |
| `PUT` | `/api/Profile/me` | Cập nhật profile (tên, SĐT, ngày sinh, giới tính) |
| `PUT` | `/api/Profile/me/avatar` | Upload/cập nhật avatar |
| `DELETE` | `/api/Profile/me/avatar` | Xóa avatar |

**Tổng: 6 endpoint.**

### 3.4 Health Profile (HealthProfileController)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/HealthProfile/me` | Lấy health profile (BMR, TDEE, BMI đã tính) |
| `PUT` | `/api/HealthProfile/me` | Cập nhật health profile → tự động recalculate |
| `PATCH` | `/api/HealthProfile/me/goal` | Cập nhật goal (DietaryGoal) → recalculate target calories/macro |
| `POST` | `/api/HealthProfile/me/calculate` | Tính BMR/TDEE/BMI/Target/Macro (không lưu, chỉ preview) |

**Tổng: 4 endpoint.** Không có endpoint riêng cho activity level hoặc target — activity và target được cập nhật qua PUT/PATCH ở trên.

---

## 4. UI Components

### 4.1 Auth Flow

| Component | File | Status |
|-----------|------|--------|
| WelcomeScreen | `features/auth/views/welcome_screen.dart` | Done |
| RegisterScreen | `features/auth/views/register_screen.dart` | Done |
| VerifyOtpScreen | `features/auth/views/verify_otp_screen.dart` | Done |
| LoginScreen | `features/auth/views/login_screen.dart` | Done |
| ForgotPasswordScreen | `features/auth/views/forgot_password_screen.dart` | Done |
| ResetPasswordScreen | `features/auth/views/reset_password_screen.dart` | Done |
| AuthRepository | `features/auth/repositories/auth_repository.dart` | Done |
| AuthErrorMessages | `features/auth/utils/auth_error_messages.dart` | Done |
| PostAuthNavigation | `features/auth/utils/post_auth_navigation.dart` | Done |

### 4.2 Onboarding Flow

| Component | File | Status |
|-----------|------|--------|
| OnboardingScreen (5-step wizard) | `features/onboarding/views/onboarding_screen.dart` | Done |
| BasicInfoStep | `features/onboarding/views/steps/basic_info_step.dart` | Done |
| CalorieGoalStep | `features/onboarding/views/steps/calorie_goal_step.dart` | Done |
| UserTypeStep | `features/onboarding/views/steps/user_type_step.dart` | Done |
| PreferencesStep | `features/onboarding/views/steps/preferences_step.dart` | Done |
| AllergiesStep | `features/onboarding/views/steps/allergies_step.dart` | Done |
| OnboardingRepository | `features/onboarding/repositories/onboarding_repository.dart` | Done |
| HealthProfileRepository | `features/onboarding/repositories/health_profile_repository.dart` | Done |
| AllergyRepository | `features/onboarding/repositories/allergy_repository.dart` | Done |
| UserAiProfileRepository | `features/onboarding/repositories/user_ai_profile_repository.dart` | Done |
| OnboardingGate | `features/onboarding/utils/onboarding_gate.dart` | Done |

### 4.3 Profile

| Component | File | Status |
|-----------|------|--------|
| ProfileScreen | `features/profile/views/profile_screen.dart` | Done |
| EditProfileScreen | `features/profile/views/edit_profile_screen.dart` | Done |
| ChangePasswordScreen | `features/profile/views/change_password_screen.dart` | Done |

---

## 5. Navigation Flow

```
App Start
    └── AuthGate
            ├── Chưa đăng nhập ──→ WelcomeScreen
            │       ├── LoginScreen ─→ MainScreen
            │       ├── RegisterScreen ─→ VerifyOtpScreen ─→ OnboardingScreen ─→ MainScreen
            │       └── ForgotPasswordScreen ─→ ResetPasswordScreen ─→ LoginScreen
            │
            └── Đã đăng nhập ──→ Profile/me/completion
                    ├── Chưa complete ──→ OnboardingScreen (5 steps)
                    └── Complete ──→ MainScreen
                                        └── Tab Profile ─→ ProfileScreen
                                                ├── EditProfileScreen
                                                └── ChangePasswordScreen
```

---

## 6. Data Models (rút gọn)

```
User (Auth)
├── Id, Email, EmailConfirmed, IsActive
└── Session (RefreshToken, ExpiresAt)

Profile
├── UserId, FullName, PhoneNumber
├── Gender, DateOfBirth, AvatarUrl

HealthProfile
├── Height, Weight, TargetWeight
├── ActivityLevel (sedentary/light/moderate/active)
├── DietaryGoal (lose weight / maintain / gain weight / build muscle)
├── BmrKcal, TdeeKcal, Bmi
├── TargetCalories, TargetProteinG, TargetCarbsG, TargetFatG
└── MacroRatio (auto-derived from goal)

UserAiProfile
├── Preferences (JSON: dislikedFoods, eatingPattern, ...)
├── DietaryType
├── RecommendationTuning
└── CreatedAt, UpdatedAt
```

Backend models đầy đủ: [`../02-backend/backend_models_documentation.md`](../02-backend/backend_models_documentation.md) (mục 1.1 Auth & 1.2 Profile & Health).

---

## 7. Related Documents

- Nutrition formulas (BMR/TDEE/Target/Macro): [`10-vietnam-local-features.md` → Appendix A](./10-vietnam-local-features.md#appendix-a-nutrition-calculation-formulas)
- Allergy profile (CRUD + risk evaluation): [`04-discover-and-allergy.md`](./04-discover-and-allergy.md)
- Tracking dashboard dùng `HealthProfile.TargetCalories`: [`02-nutrition-tracking.md`](./02-nutrition-tracking.md)
- Goal drift alerts dựa trên target: [`09-analytics.md`](./09-analytics.md)
- User workflow cũ (mục 4.1-4.4): [`../_archive/root-readmes/README_USER_WORKFLOW.md`](../_archive/root-readmes/README_USER_WORKFLOW.md)