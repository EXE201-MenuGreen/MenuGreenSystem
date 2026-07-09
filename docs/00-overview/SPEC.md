# MenuGreen — System Specification (SPEC)

**Version:** 1.0
**Date:** 2026-07-08
**Status:** Production — đã deploy
**Last updated by:** Agent (docs review + verification)

---

## 1. System Overview

MenuGreen là ứng dụng dinh dưỡng cá nhân hóa cho thị trường Việt Nam, hỗ trợ ba nhóm user chính:

- **(A) User không biết hôm nay ăn gì** → nhận gợi ý hàng ngày, quick-log bữa ăn.
- **(B) User muốn cải thiện dinh dưỡng** → tracking calo/macro, dashboard, cảnh báo drift.
- **(C) User gym/PT** → goal-based meal plan, TDEE động theo ngày tập/ngày nghỉ.

### 1.1 Platform

| Platform | URL / Package | Status |
|----------|--------------|--------|
| Backend API | `https://api.menugreen.food` | Production |
| Frontend Web | `https://www.menugreen.food` | Vercel |
| Mobile (Flutter) | `com.menugreen.app` | Sắp lên CH Play |
| Database | PostgreSQL 18.3 (AWS RDS Singapore) | Production |
| Cache | Redis 7 (Lightsail container) | Production |

### 1.2 Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Users                              │
│   ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│   │ Flutter  │  │  Web     │  │   AI Coach        │   │
│   │ Android  │  │ (Vercel) │  │   (future)        │   │
│   └────┬─────┘  └────┬─────┘  └────────┬─────────┘   │
└────────┼──────────────┼──────────────────┼──────────────┘
         │              │                  │
         ▼              ▼                  ▼
┌─────────────────────────────────────────────────────────┐
│                  CDN / Cloudflare                       │
│              (reverse proxy, cache, SSL)                  │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│           AWS Lightsail Ubuntu 22.04                     │
│  ┌────────────────┐  ┌────────────────┐                │
│  │ menugreen_api  │  │ menugreen_redis│                │
│  │ .NET API:5000  │  │ Redis 7        │                │
│  │ Nginx          │  │                │                │
│  └───────┬────────┘  └───────┬────────┘                │
└──────────┼───────────────────┼──────────────────────────┘
           │                   │
           ▼                   ▼
    ┌──────────────┐   ┌──────────────┐
    │ AWS RDS      │   │ Docker Hub   │
    │ PostgreSQL 18 │   │ Image repo   │
    └──────────────┘   └──────────────┘
```

---

## 2. Feature Modules

### 2.1 Module Overview

| # | Module | Controllers | API | UI | Notes |
|---|--------|-----------|-----|-----|-------|
| 01 | Auth & Account | Auth, Onboarding, Profile, HealthProfile | ✅ Done | ✅ Done | OTP login |
| 02 | Nutrition Tracking | NutritionTracking, UserDashboard, VietnamNutrition | ✅ Done | ✅ Done | Core feature |
| 03 | Meal Plan | MealPlan, Notification (reminders) | ✅ Done | ✅ Done | Budget & expenses |
| 04 | Discover & Allergy | Food, Recipe, Allergy, PortionConverter, IngredientSubstitution | ✅ Done | ✅ Done | Full catalog |
| 05 | Recommendation Engine | Recommendation | ✅ Done | ✅ Done | Rule-based + scoring |
| 06 | AI Assistant & Coach | AiAssistant, AiCoach, AiAdmin | ✅ Done | ⚠️ Placeholder | Chưa kết nối API |
| 07 | Notification | Notification | ✅ Done | ✅ Done | Settings + inbox + campaigns |
| 08 | Subscription & Payment | SubscriptionPlan, UserSubscription, SePay | ✅ Done | ✅ Done | Free tier + SePay QR |
| 09 | Analytics | Analytics, PlannedVsActual | ✅ Done | ⛔ Out of scope | Admin/BI only |
| 10 | Vietnam Local | DailyStarter, GymGoals, FoodCapture, Safety, AllergyBadge | ✅ Done | ⚠️ Partial | Badge done |

### 2.2 Module Detail

#### 01 — Auth & Account (19 EP)
- **Auth** (8 EP): Register, VerifyOTP, ForgotPassword, ResetPassword, Login, RefreshToken, Logout, GoogleLogin. Rate-limiting: OTP endpoints bounded by `OtpPolicy`.
- **Onboarding** (1 EP): `POST /Onboarding/complete` — tạo HealthProfile + allergy + ai profile trong 1 lần gọi.
- **Profile** (6 EP): Get, GetSummary, GetCompletion (onboarding gate), Update, UpdateAvatar, RemoveAvatar.
- **HealthProfile** (4 EP): Get, Update, UpdateGoal (recalculate), Calculate (preview only, không lưu).
- **Models:** `User`, `Session`, `EmailVerification`, `PasswordResetToken`, `Profile`, `HealthProfile`.
- **UI:** 5-step wizard (BasicInfo → CalorieGoal → UserType → Preferences → Allergies), AuthRepository, OnboardingGate.
- **Cross-links:** Onboarding hoàn thành → redirect MainScreen. HealthProfile là đầu vào cho TDEE calculation.

#### 02 — Nutrition Tracking (33 EP)
- **NutritionTracking** (16 EP): MealLog CRUD + paged/range queries, WeightLog CRUD + paged/trend queries, Summary (period), Trends, Daily, Dashboard.
- **UserDashboard** (4 EP): user-summary (streak), nutrition-trend, weight-trend, recommendation-summary.
- **VietnamNutrition** (13 EP): local-preferences (CRUD), discovery/local (all/region/budget), meal-log/vn (suggestions/log/quick-add/history), recommendations/budget-aware + local-friendly + feedback alias.
- **Models:** `MealLog`, `WeightLog`, `NutritionSnapshot`, `Dashboard`.
- **UI:** MealLogSheet, WeightLogSheet, DailySummaryCard, CalorieTrendChart, WeightTrendChart, CalendarHeatmapLegend, IngredientScanScreen (CV).
- **Cross-links:** MealLog ghi vào → cập nhật Dashboard. Weight trend cần NutritionTracking. Vietnam meal-log ghi vào → update streak.

#### 03 — Meal Plan (24 EP + 2 reminder = 26 EP)
- **MealPlan CRUD** (8 EP): List, Get, Create, CreateEmpty, Update, Delete, UpdateStatus, Distribute.
- **Items CRUD** (5 EP): Add, Update, Delete, UpdateStatus, SubstituteIngredient, ConvertToLog.
- **Actions** (2 EP): Commit (toàn bộ plan → logs), Duplicate.
- **Dashboard & Stats** (4 EP): Dashboard, Compare, Streaks, AdherenceScores.
- **Budget & Alternatives** (3 EP): GenerateByBudget, BudgetStatus, Alternatives.
- **Expenses** (2 EP): CompareExpenses, ExpenseBreakdown.
- **Reminders** (2 EP — NotificationController): meal-plan-remind, schedule-prep-reminder.
- **Models:** `MealPlanHeader`, `MealPlanItem`.
- **UI:** MealPlanScreen, CreateMealPlanScreen, MealPlanDetailScreen, DashboardScreen, CalendarScreen.
- **Cross-links:** Plan items substitute → IngredientSubstitutionController. Plan commit → MealLog. Plan gợi ý → RecommendationController.

#### 04 — Discover & Allergy (46 EP)
- **Food** (10 EP): Search (root GET), GetById, GetRecipes, Favorites CRUD, Admin CRUD (POST/PUT/DELETE), UpdateAllergens.
- **Recipe** (7 EP): Search, Get, GetIngredients, GetNutrition, GetRelated, Admin Update, Admin Delete.
- **Allergy** (10 EP): GetProfile, Add, Update, Delete, BulkUpdate, Catalog, Evaluate, EvaluateBatch, GetBadge, Recommendations.
- **PortionConverter** (7 EP): GetUnits, GetUnitsForFood, Convert, CustomUnits CRUD.
- **Vietnam Discovery** (3 EP): DiscoveryLocal, ByRegion, ByBudget. *(Thực ra nằm trong VietnamNutritionController — đặt tại đây để dễ tham chiếu.)*
- **IngredientSubstitution** (9 EP): GetSubstitutes, BatchSubstitutes, Preferences CRUD (3), SubstituteInRecipe, SafeAlternatives, SubstituteInMealPlan, SubstituteInMealLog.
- **Models:** `Food`, `Recipe`, `RecipeIngredient`, `Allergy`, `UserAllergy`, `FoodAllergenTag`, `Ingredient`.
- **UI:** DiscoverView, FoodDetailScreen, RecipeDetailScreen, IngredientDetailScreen, FavoritesScreen, SafeRecommendationsScreen, AllergyRiskBadge.

#### 05 — Recommendation Engine (16 EP)
- **Generate** (7 EP): Generate, GenerateSafe, GenerateDailyMenu (25/35/30/10 split), GenerateWeeklyPlan, GenerateBudgetAware, GenerateSmartSchedule, Preview.
- **History & Feedback** (6 EP): History, GetById, DeleteHistory, Feedback, UpdateFeedback, FeedbackSummary.
- **Explain & Optimize** (3 EP): Explain, Scores (0-100 scale per criteria), Retrain.
- **Models:** `Recommendation`, `RecommendationFeedback`, scoring DTOs.
- **Formula:** xem Appendix A.14 trong file 10.
- **Cross-links:** Scores dùng cho 04 Discover. Generate dùng cho 03 MealPlan. Retrain feedback → AI improvement.

#### 06 — AI Assistant & Coach (31 EP)
- **AiAssistant** (22 EP): Conversations CRUD (6), Messages + regenerate + feedback (5), Context/Profile GET+PUT (4), Action suggestions (4), Analytics (3).
- **AiCoach** (9 EP): Context snapshot, SuggestedPrompts, Sessions CRUD (5), ExecuteAction, Feedback (2 paths).
- **AiAdmin** (Admin): Overview, health, debug, crawler normalize/ingest, training samples CRUD + review, feedback→training sample, nightly curation.
- **Models:** `AiConversation`, `AiMessage`, `AiSession`, `UserAiProfile`.
- **UI:** ⚠️ **Placeholder** — chat screen tồn tại nhưng chưa kết nối đầy đủ với API. Cần wire conversation list → chat → streaming response → action suggestions.
- **Function calling:** Both assistants thực thi actions: `log_meal`, `generate_meal_plan`, `schedule_meal`, etc.

#### 07 — Notification (32 EP)
- **Settings** (4 EP): Get, Update, Reset, GetChannels.
- **Inbox CRUD** (10 EP): List paginated, Get, UnreadCount, Read, Open, Dismiss, ReadAll, Delete, DeleteBatch, DeleteRange.
- **Send & Schedule** (7 EP): MealPlanRemind, SchedulePrepReminder, Send, SendBulk, SendEvent, SendSchedule, SendRetry.
- **Tracking** (3 EP): TrackOpen, TrackClick, TrackActionComplete.
- **Analytics** (2 EP): Analytics (open/click/conversion), Re-engagement report.
- **Campaigns** (6 EP): CRUD + Run + Pause.
- **Models:** `Notification`, `NotificationSetting`, `NotificationCampaign`.
- **UI:** SettingsScreen, InboxScreen, FCM handler.

#### 08 — Subscription & Payment (20 EP)
- **SubscriptionPlan Admin** (8 EP): List (with isActive filter), Get, GetFeatures (AllowAnonymous), GetStatus, Create, Update, Delete, UpdateStatus.
- **UserSubscription** (7 EP): GetPlans, Subscribe (free), Renew, Cancel, GetCurrent, GetById, GetHistory.
- **SePay** (5 EP): CreateOrder, CreateRenewOrder, GetPending, GetStatus, Webhook (AllowAnonymous).
- **Models:** `SubscriptionPlan`, `UserSubscription`, `SepayTransaction`.
- **Payment flow:** User chọn plan → CreateOrder → SePay tạo QR → webhook xác nhận → activate subscription.

#### 09 — Analytics (37 EP)
- **ActivityLog** (4 EP): Create, BulkCreate, List, GetById.
- **Dashboard & Metrics** (4 EP): Dashboard, Summary, Metrics, TopEvents.
- **Funnel** (4 EP): Funnel, Preview, MealOnboardingFunnel, SubscriptionFunnel.
- **Cohort** (5 EP): Cohort, Retention, BySignupDate, ByFirstMealLog, BySubscription.
- **Churn & Retention** (4 EP): DropOff, ChurnRisk, InactiveUsers, ReactivationOpportunities.
- **PlannedVsActual** (6 EP): Summary, AdherenceScore, DriftAnalysis, Recommendations, MonthlyReport, Recalibrate.
- **Export** (3 EP): ExportActivityLog, ExportFunnel, ExportCohort.
- **Nutrition Analytics** (7 EP): NutritionDashboard, MacroDistribution, GoalAchievement, TopFoods, CalorieDistribution, MealTypeBreakdown, UserInsights.
- **Models:** `ActivityLog`, `FunnelData`, `CohortData`, `NutritionSnapshot`.
- **UI:** ⛔ Không có trong mobile app — admin dùng BI tool riêng.

#### 10 — Vietnam Local Features (47+ EP across 5 controllers)
- **DailyStarter** (8 EP): Today, FeaturedMeals, SelectMeal, StartLog, Recommendations, GetPersonalization, UpdatePersonalization, SavePreference.
- **GymGoals** (7 EP): GetMe, CreateOrUpdate, Update, GetPlan, Recalibrate, GetAlerts, CoachReport.
- **FoodCapture** (4 EP): QuickTemplate, TemplateFromPlan, FallbackEstimate, SaveAsQuickAdd.
- **Safety** (7 EP): GetDisclaimer, GetConsent, UpdateConsent, GetAlerts, ExportData, DeleteData, ReportIssue.
- **AllergyBadge** (AllergyController — xem 04 §3.6).
- **IngredientSubstitution Preferences** (3 EP — xem 04 §3.5).
- **Nutrition Formulas:** xem Appendix A dưới đây.
- **UI:** ⚠️ Partial — chỉ AllergyRiskBadge đã done. Các workflow khác (Daily Starter, Gym Goals, Food Capture, Safety) chưa có UI.

#### 11 — Premium Programs (12 EP)
- **PremiumPrograms** (12 EP): List, Get, Checkout, Activate, MyActive, MyPrograms, Milestones, CheckIn, ProgressTrend, Graduate, WrapUpReport.
- **Models:** `PremiumProgram`, `UserPremiumSubscription`, `ProgramMilestone`, `ProgramCheckIn`.
- **UI:** ❌ Chưa có. Cần: catalog, checkout, active program, weekly check-in, graduation.
- **Cross-links:** Checkout → SePayController. Check-in → NutritionTracking.

#### 12 — Meal Templates (8 EP)
- **MealTemplate** (8 EP): CRUD, Log, Duplicate, Usage, CreateFromLog.
- **Models:** `MealTemplate`.
- **UI:** ❌ Chưa có. Cần: template list, create, log from template.
- **Cross-links:** Log → MealLog. Food data → FoodController.

#### 13 — Micro-Learning (6 EP)
- **MicroLearning** (6 EP): Recommended, GetById, Categories, RecordAction, Saved, SubmitQuiz.
- **AdminMicroLearning** (7 EP — riêng controller): CRUD cards + AdminMicroLearningController.
- **Models:** `MicroLearningCard`, `MicroLearningCategory`, `UserCardAction`.
- **UI:** ❌ Chưa có. Cần: card feed, card detail, quiz, saved list.
- **Cross-links:** Recommended → HealthProfile + NutritionTracking.

#### 14 — Adaptive Reminders (7 EP)
- **Reminder** (7 EP): GetProfile, RecalculateProfile, UpdateProfile, Scheduled CRUD, Snooze.
- **Models:** `ReminderProfile`, `ScheduledReminder`.
- **UI:** ❌ Chưa có. Cần: profile setup, scheduled list, create/edit, snooze.
- **Cross-links:** Recalculate → NutritionTracking. Reminders gửi → NotificationController.

#### 15 — PT Review (7 EP)
- **PtReview** (7 EP): CreateReport, GetSharedReport, MyRequests, SubmitReview, GetResult, ApplyReview, RejectReview.
- **Models:** `PtReviewRequest`, `PtReviewReport`.
- **UI:** ❌ Chưa có. Cần: create request, my requests, PT report page (mobile-friendly).
- **Cross-links:** Apply → MealPlan + HealthProfile targets. Notification → NotificationController.

#### 16 — Budget Management (4 EP)
- **BudgetRequest** (4 EP): GetActive, Create, Update, Delete.
- **Models:** `BudgetRequest`.
- **UI:** ❌ Chưa có. Cần: budget setup screen.
- **Cross-links:** Đọc bởi MealPlanController (generate-by-budget) và RecommendationController (budget-aware).

#### 17 — Coaches Ecosystem (16 EP)
- **Coaches** (16 EP): List, GetById, Register, Connect, ApproveConnection, MyClients, GrantAccess, RevokeAccess, ClientProfile, ClientNutritionSummary, ClientWeightTrend, AddFeedback, GetFeedbacks, AdjustMealPlan, AdjustHealthTargets.
- **Models:** `CoachProfile`, `CoachStudentConnection`, `CoachFeedback`.
- **UI:** ❌ Chưa có. Cần: coach catalog, coach detail, my coaches, coach dashboard (clients), feedback forms.
- **Cross-links:** Client data → NutritionTracking + HealthProfile + MealPlan. Coach role policy → UserController.

#### 18 — Ingredient Catalog (7 EP)
- **Ingredient** (7 EP): Search, GetById, GetRecipes, Catalog, Create, Update, Delete (Admin).
- **Models:** `Ingredient`.
- **UI:** ❌ Chưa có riêng. Tích hợp vào Discover/Recipe screens.
- **Cross-links:** Allergy mode → AllergyController. Recipe link → RecipeController.

#### 19 — User Management (7 EP)
- **User** (7 EP): ChangePassword (user), List, GetById, ToggleStatus, Lock, Unlock, AssignRole (admin).
- **Models:** `User` (role, IsActive).
- **UI:** ⚠️ Partial — ChangePasswordScreen đã có (Profile feature). Admin user management ❌.
- **Cross-links:** Role assignment → policy gates (`UserOnly`, `CoachOnly`, `AdminOnly`).

---

## 3. API Architecture

### 3.1 API Style
- RESTful HTTP API trên .NET 8.
- Base URL: `https://api.menugreen.food/api/`
- Authentication: JWT Bearer token (`Authorization: Bearer <token>`).
- Authorization: policy-based (`UserOnly`, `AdminOnly`).
- Rate limiting: `AuthPolicy` cho toàn bộ AuthController; `OtpPolicy` cho register/forgot-password.
- Response format: JSON. Error: `{ "Message": "..." }`. Messages viết **tiếng Anh**.

### 3.2 Authorization Matrix

| Controller | Policy | Notes |
|-----------|--------|-------|
| AuthController | Public (rate-limited) | Không cần token |
| OnboardingController | UserOnly | |
| ProfileController | Authorized | Mọi endpoint cần token |
| HealthProfileController | UserOnly | |
| NutritionTrackingController | UserOnly | |
| UserDashboardController | UserOnly | |
| VietnamNutritionController | UserOnly | |
| MealPlanController | UserOnly | |
| FoodController | UserOnly | Admin CRUD cùng policy — service layer kiểm tra role |
| RecipeController | UserOnly | |
| AllergyController | UserOnly | |
| PortionConverterController | UserOnly | |
| IngredientSubstitutionController | UserOnly | |
| RecommendationController | UserOnly | |
| AiAssistantController | UserOnly | |
| AiCoachController | UserOnly | |
| NotificationController | UserOnly | |
| SubscriptionPlanController | AdminOnly | |
| UserSubscriptionController | UserOnly | |
| SePayController | Public + UserOnly | Webhook AllowAnonymous |
| AnalyticsController | AdminOnly | |
| PlannedVsActualController | Authorized | |
| DailyStarterController | UserOnly | |
| GymGoalsController | UserOnly | |
| FoodCaptureController | UserOnly | |
| SafetyController | UserOnly | |
| AiAdminController | AdminOnly | |
| CoachesController | Public + UserOnly + CoachOnly | AllowAnonymous for list/detail; CoachOnly for student data |
| PremiumProgramsController | Public + UserOnly | AllowAnonymous for program discovery |
| MealTemplateController | UserOnly | |
| MicroLearningController | Authorized | |
| AdminMicroLearningController | AdminOnly | |
| ReminderController | UserOnly | |
| PtReviewController | Authorized + AllowAnonymous | AllowAnonymous for shared report token |
| BudgetRequestController | UserOnly | |
| IngredientController | UserOnly + AdminOnly | Admin CRUD cùng policy |
| UserController | Authorized + AdminOnly | change-password user; CRUD admin |
| AiAdminController | AdminOnly | |

### 3.3 Database Schema (PostgreSQL)

```
┌──────────────────┐     ┌──────────────────┐
│      User         │────<│    Session        │
│  (Auth + Role)    │     │  (RefreshToken)   │
└────────┬─────────┘     └──────────────────┘
         │
    ┌────┴────────┐   ┌──────────────────┐
    │  Profile     │   │  EmailVerification│
    │              │   │  PasswordResetToken│
    └────┬────────┘   └──────────────────┘
         │
    ┌────┴────────────┐
    │  HealthProfile   │──< NutritionSnapshot
    │  (BMR,TDEE,Goal) │
    └────┬────────────┘
         │
┌────────┴───────────────────────────┐
│  MealLog   │  MealPlanHeader  │ MealPlanItem │
│  WeightLog │  (1:N)           │  ──────────── │
└────────────┴────────────────────┴───────────────┘

┌──────────────┐   ┌──────────────────┐
│    Food       │───<│  Recipe          │
│  (catalog)    │   │  (Ingredient list)│
└────┬──────────┘   └────────┬─────────┘
     │                         │
┌────┴──────────┐    ┌────────┴──────────┐
│FoodAllergenTag│    │ RecipeIngredient    │
│   (labels)    │    └───────────────────┘
└───────────────┘

┌──────────────────┐   ┌────────────────────┐
│    Allergy        │──<│  UserAllergy       │
│ (master catalog)  │   │  (user preferences)│
└──────────────────┘   └────────────────────┘

┌──────────────────┐   ┌──────────────────────┐
│SubscriptionPlan   │──<│  UserSubscription    │
│ (Admin-managed)   │   │  (user subscription) │
└──────────────────┘   └──────┬───────────────┘
                               │
                        ┌──────┴──────────┐
                        │SepayTransaction  │
                        │ (payment logs)   │
                        └─────────────────┘

┌──────────────────┐   ┌──────────────────────┐
│ AiConversation    │──<│  AiMessage          │
│ AiSession         │   │  UserAiProfile       │
│ Notification      │   │  NotificationCampaign │
└──────────────────┘   └──────────────────────┘

┌──────────────────┐   ┌──────────────────────┐
│   ActivityLog     │   │  UserAllergy         │
│   FunnelData      │   │  FoodAllergenTag     │
│   CohortData      │   └──────────────────────┘
└──────────────────┘
```

### 3.4 Cross-Service Dependencies

```
AuthService ──> UserService, EmailService
ProfileService ──> UserService
HealthProfileService ──> UserService
  ├── HealthProfileMetricsCalculator (BMR/TDEE/Macro formulas)
  └── GoalDriftService (drift detection)

NutritionTrackingService ──> UserService, HealthProfileService
  ├── GoalDriftService (warnings)
  └── NutritionSnapshot (daily aggregate)

MealPlanService ──> UserService, NutritionTrackingService, RecommendationService

RecommendationService ──> UserService, HealthProfileService, FoodService
  ├── IngredientSubstitutionService
  └── GoalDriftService

VietnamNutritionService ──> FoodService, RecommendationService,
                           NutritionAssistantService, PortionConverterService

AllergyService ──> UserService, FoodService
  └── AllergenMatchingService

AiAssistantService ──> UserService, NutritionTrackingService,
                        HealthProfileService, RecommendationService

AiCoachService ──> (full context: all services)

NotificationService ──> UserService

AnalyticsService ──> UserService, NutritionTrackingService,
                       MealPlanService

PlannedVsActualService ──> NutritionTrackingService, MealPlanService
```

---

## 4. Mobile App Architecture (Flutter)

### 4.1 App Structure

```
lib/
├── main.dart                          # App entry, Provider setup, theme
├── core/
│   ├── config/                       # API base URL, constants
│   ├── theme/                        # AppColors, AppTheme, TextStyles
│   ├── network/                      # Dio client, interceptors, API client
│   ├── storage/                      # SharedPreferences, secure storage
│   ├── i18n/                        # ApiMessageTranslator, localization
│   └── utils/                       # Formatters, validators, helpers
├── features/
│   ├── auth/                        # 01 Auth & Account
│   ├── onboarding/                 # 01 Onboarding (5-step wizard)
│   ├── profile/                     # 01 Profile
│   ├── tracking/                   # 02 Nutrition Tracking
│   ├── meal_plan/                  # 03 Meal Plan
│   ├── discover/                   # 04 Discover & Allergy
│   ├── recommendation/             # 05 Recommendation Engine
│   ├── ai_assistant/               # 06 AI Assistant & Coach ⚠️ Placeholder
│   ├── notification/               # 07 Notification
│   └── subscription/               # 08 Subscription & Payment
└── shared/
    └── widgets/                     # Reusable: CalorieRing, MacroBar, etc.
```

### 4.2 State Management

- **Provider** pattern: mỗi feature có `Provider` + `StateNotifier`.
- Repository pattern cho data layer: `XxxRepository` gọi API, trả về model.
- `ChangeNotifierProvider` cho global state (auth, user profile).
- Navigation: `go_router` hoặc Navigator 2.0.

### 4.3 Navigation Flow

```
App Start
└── AuthGate
    ├── Chưa login ──→ WelcomeScreen
    │                    ├── RegisterScreen → VerifyOtpScreen → OnboardingScreen(5-step)
    │                    └── LoginScreen → ForgotPasswordScreen / ResetPasswordScreen
    │
    └── Đã login ──→ OnboardingGate
                      ├── Chưa onboarding ──→ OnboardingScreen(5-step)
                      │
                      └── Hoàn thành ──→ MainScreen
                                          ├── Tab Home (Dashboard)
                                          │    ├── DailySummaryCard
                                          │    ├── MealLogSheet → SearchAndLogModal
                                          │    └── Quick actions (AI Coach)
                                          │
                                          ├── Tab Lịch sử
                                          │    ├── Dashboard (day/week/month)
                                          │    ├── CalorieTrendChart
                                          │    ├── WeightTrendChart
                                          │    ├── CalendarHeatmap
                                          │    └── Meal log list → Edit
                                          │
                                          ├── Tab Khám phá
                                          │    ├── DiscoverView → FoodDetail / RecipeDetail
                                          │    ├── AllergyRiskBadge
                                          │    ├── SafeRecommendations
                                          │    └── FavoritesScreen
                                          │
                                          ├── Tab AI Chat ⚠️ Placeholder
                                          │
                                          └── Tab Tài khoản
                                               ├── ProfileScreen → EditProfileScreen
                                               ├── HealthProfileScreen
                                               ├── NotificationSettings
                                               ├── SubscriptionScreen
                                               └── Safety / DeleteAccount
```

### 4.4 API Communication

- HTTP client: **Dio** với interceptors.
- Interceptors: attach JWT token, log request/response, handle 401 (redirect login).
- Error handling: API trả về `{ "Message": "..." }` → `ApiMessageTranslator.translate()` → hiển thị tiếng Việt.
- Caching: `cached_network_image` cho food/recipe photos, `flutter_cache_manager` cho assets.

---

## 5. Infrastructure

### 5.1 Backend Infrastructure

| Component | Detail |
|-----------|--------|
| Server | AWS Lightsail Ubuntu 22.04, 52.77.218.100 |
| Docker | 29.6.1, Docker Compose 5.2.0 |
| API Image | `anhtuan21112004/menugreensystem:latest` (Docker Hub) |
| Port | 5000 |
| Caching | Redis 7 Alpine container |
| Secrets | Doppler (production), .env (local) |

### 5.2 Database

| Property | Value |
|----------|-------|
| Engine | PostgreSQL 18.3 |
| Host | menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com |
| Region | ap-southeast-1 (Singapore) |
| Port | 5432 |
| Database | menugreendb |
| ORM | Entity Framework Core |

### 5.3 CI/CD

- **Trigger:** Push lên `main` hoặc `Tuan` branch.
- **Pipeline:** Build .NET → Docker build → Push to Docker Hub → SSH deploy → docker restart.
- **Secrets:** GitHub Actions secrets cho DB URL, Redis URL, JWT secret, Doppler sync.

### 5.4 Monitoring

- **Uptime:** UptimeRobot giám sát `https://api.menugreen.food/health`.
- **Logs:** `docker logs menugreen_api --tail 50 -f`.
- **Health endpoint:** `GET /health` trả về PostgreSQL + Redis status.

---

## 6. Business Rules & Formulas

*(Chi tiết tại [`10-vietnam-local-features.md` → Appendix A](./features/10-vietnam-local-features.md#appendix-a-nutrition-calculation-formulas))*

| Rule | Value | File |
|------|-------|------|
| BMR (Mifflin-St Jeor) | Male: 10×weight + 6.25×height − 5×age + 5; Female: −161 | `HealthProfileMetricsCalculator.cs` |
| TDEE | BMR × ActivityMultiplier (1.2–1.9) | `HealthProfileMetricsCalculator.cs` |
| TDEE Floor | ≥ 1200 kcal | `HealthProfileMetricsCalculator.cs:23` |
| Macro (Build Muscle) | Protein 35% / Carbs 45% / Fat 20% | `HealthProfileMetricsCalculator.cs:85-87` |
| Macro (Other goals) | Protein 30% / Carbs 40% / Fat 30% | `HealthProfileMetricsCalculator.cs:85-87` |
| Protein clamp | [0.8, 2.2] g/kg body weight | `HealthProfileMetricsCalculator.cs:92-100` |
| Calorie Drift threshold | 8% (7-day average) | `GoalDriftService.cs:98` |
| Macro Drift threshold | 15% | `GoalDriftService.cs:99-101` |
| Recommendation scoring | 0–100 per metric, avg = overall | `RecommendationService.cs:189-202` |
| Daily menu split | Breakfast 25% / Lunch 35% / Dinner 30% / Snack 10% | `RecommendationService.cs` |
| Streak rule | today = yesterday OR yesterday missed → streak resets | `UserDashboardService.cs:151-194` |
| Adherence Score | 4-component formula | `PlannedVsActualService.cs` |

---

## 7. Open Issues & Technical Debt

### 7.1 Known Gaps

| Priority | Issue | File / Module |
|----------|-------|--------------|
| 🔴 High | AI Assistant UI chưa kết nối API (chat screen placeholder) | 06 |
| 🟡 Medium | 3 controller chưa có canonical doc: GoalsController, EngagementController, BudgetRequestController | docs/features/ |
| 🟡 Medium | Duplicated route `/api/Nutrition/recommendations/feedback` = alias cho `/api/Recommendation/feedback` | VietnamNutritionController.cs:268 |
| 🟡 Medium | CORS đã config nhưng Flutter mobile cần SSL pinning / certificate config | Flutter |
| 🟢 Low | 2.12 Beginner Quick-Start UI chưa có (API đã done) | 10 |
| 🟢 Low | 2.13 Gym/PT UI chưa có (API đã done) | 10 |
| 🟢 Low | 2.14 Food Capture UI chưa có (API đã done) | 10 |
| 🟢 Low | 2.15 Safety UI chưa có (API đã done) | 10 |
| 🟢 Low | Adherence Score weights chưa calibrate bằng A/B test | 10, formula |

### 7.2 Duplicate / Inconsistency Log

| Date | Item | Resolution |
|------|------|-----------|
| 2026-07-08 | VietnamNutritionController: 3 local-preferences + 3 discovery + 2 recommendations = 12 EP chưa đầy đủ trong doc | Đã fix 02-nutrition-tracking.md §3.5 |
| 2026-07-08 | IngredientSubstitutionController: `/safe-alternatives` route đặt ở đây, không phải RecipeController | Đã fix 04-discover-and-allergy.md §3.5 |
| 2026-07-08 | HealthProfileController: doc nói 8 EP, code chỉ có 4 | Đã fix 01-auth-and-account.md §3.4 |
| 2026-07-08 | AuthController: doc nói 9 EP, code có 8 (không có resend-otp riêng) | Đã fix 01-auth-and-account.md §3.1 |
| 2026-07-08 | OnboardingController: doc nói 3 EP, code chỉ có 1 | Đã fix 01-auth-and-account.md §3.2 |
| 2026-07-08 | MealPlanController: doc nói 19 EP, code có 24 | Đã fix 03-meal-plan.md §3.1–§3.6 |
| 2026-07-08 | A.5 Build Muscle macro: doc nói 40C/25F, code 45C/20F | Đã fix 10-vietnam-local-features.md A.5 |
| 2026-07-08 | A.7 Drift threshold: doc nói 10%, code 8% | Đã fix 10-vietnam-local-features.md A.7 |
| 2026-07-08 | A.14 Recommendation scoring: doc ghi distance, code là 0-100 candidate-set score | Đã fix 10-vietnam-local-features.md A.14 |

---

## 8. Appendix

### A. File Map

| File | Chủ đề |
|------|--------|
| [`README.md`](./README.md) | Trang chủ tài liệu |
| [`PROJECT_STATUS.md`](./PROJECT_STATUS.md) | Trạng thái production, server info |
| [`03-features-overview/README.md`](./03-features-overview/README.md) | Bảng tổng hợp 19 feature modules |
| [`docs/features/01-auth-and-account.md`](./features/01-auth-and-account.md) | Auth + Onboarding + Profile + HealthProfile |
| [`docs/features/02-nutrition-tracking.md`](./features/02-nutrition-tracking.md) | Meal log + Weight + Dashboard |
| [`docs/features/03-meal-plan.md`](./features/03-meal-plan.md) | Meal plan + Budget + Expenses |
| [`docs/features/04-discover-and-allergy.md`](./features/04-discover-and-allergy.md) | Food + Recipe + Allergy + Portion |
| [`docs/features/05-recommendation-engine.md`](./features/05-recommendation-engine.md) | Recommendation + Feedback + Retrain |
| [`docs/features/06-ai-assistant-and-coach.md`](./features/06-ai-assistant-and-coach.md) | AI Chatbot + Contextual Coach |
| [`docs/features/07-notification.md`](./features/07-notification.md) | Inbox + Settings + Campaigns |
| [`docs/features/08-subscription-and-payment.md`](./features/08-subscription-and-payment.md) | Subscription + SePay |
| [`docs/features/09-analytics.md`](./features/09-analytics.md) | Activity + Funnel + Cohort + Churn |
| [`docs/features/10-vietnam-local-features.md`](./features/10-vietnam-local-features.md) | Vietnam features + Formulas |
| [`docs/02-backend/backend_models_documentation.md`](./02-backend/backend_models_documentation.md) | Entity + DTO reference |
| [`docs/issues.md`](./issues.md) | Issue tracker |

### B. Endpoint Count Summary

| Module | Controllers | Endpoint Count |
|--------|-------------|--------------|
| 01 Auth & Account | 4 | 19 |
| 02 Nutrition Tracking | 3 | 33 |
| 03 Meal Plan | 2 | 30 |
| 04 Discover & Allergy | 5 | 44 |
| 05 Recommendation | 1 | 16 |
| 06 AI Assistant & Coach | 3 | 40 |
| 07 Notification | 1 | 32 |
| 08 Subscription & Payment | 3 | 20 |
| 09 Analytics | 2 | 37 |
| 10 Vietnam Local | 7 | 47 |
| 11 Premium Programs | 1 | 11 |
| 12 Meal Templates | 1 | 9 |
| 13 Micro-Learning | 2 | 12 |
| 14 Adaptive Reminders | 1 | 8 |
| 15 PT Review | 1 | 7 |
| 16 Budget Management | 1 | 4 |
| 17 Coaches Ecosystem | 1 | 15 |
| 18 Ingredient Catalog | 1 | 7 |
| 19 User Management | 1 | 7 |
| **Total** | **35** | **~391** |

> **Ghi chú:** Số trên là endpoint count tổng hợp, bao gồm cả cross-reference giữa các module. Một số endpoint thuộc về nhiều module (ví dụ: Notification reminders trong Meal Plan, Allergy endpoints trong Vietnam Local). Đây là số liệu reference — không phải tổng cộng unique endpoint.

### C. Key External Dependencies

| Service | Purpose |
|---------|---------|
| Google OAuth 2.0 | Social login (AuthController.google) |
| SendGrid / SMTP | Email OTP, password reset |
| Gemini AI | AI Assistant + Coach (function calling) |
| SePay | Vietnam QR payment gateway |
| Firebase Cloud Messaging | Push notification |
| AWS RDS PostgreSQL | Primary database |
| Docker Hub | Container image registry |
| Doppler | Secrets management |
