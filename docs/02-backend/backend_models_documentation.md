# Tài liệu các Models trong Hệ thống MenuGreen

> **Last updated:** 2026-07-12 — Đồng bộ với codebase thực tế (57 entities).
>
> **Đã sửa:** Bổ sung đầy đủ các nhóm entity (Coach, PremiumProgram, Substitution, MealTemplate, Reminder, Budget, Campaign, GoalDrift, DeviceToken, FavoriteFood, MicroLearning, v.v.). Thêm Pydantic schemas từ CV service.

Tài liệu này tổng hợp toàn bộ các mô hình dữ liệu (Entities/DTOs/Pydantic schemas) đang được sử dụng trong hệ thống backend của MenuGreen (gồm .NET Web API và Python CV Service).

File entity thực tế: `MenuGreen.DataAccessLayer/Entities/*.cs` (57 files).

---

## 1. Database Entities (MenuGreen.DataAccessLayer)

Các thực thể đại diện cho bảng PostgreSQL, ánh xạ qua Entity Framework Core (Fluent API qua `ApplyConfigurationsFromAssembly`).

### 1.1 Quản lý Tài khoản & Bảo mật (Auth & Accounts)

| Entity                       | File                  | Mô tả                                                                       |
|------------------------------|-----------------------|------------------------------------------------------------------------------|
| `User`                       | `User.cs`             | Tài khoản cơ bản — `Id`, `Email`, `PasswordHash`, `EmailConfirmed`, `IsActive`, `RoleId`, `LastSignInAt`, `CreatedAt`, `UpdatedAt` |
| `Role`                       | `Role.cs`             | Phân quyền — `Id`, `Name` (Admin, User), `Description`                       |
| `Session`                    | `Session.cs`          | Phiên đăng nhập + Refresh Token — `Id`, `UserId`, `RefreshToken`, `ExpiresAt`, `IsRevoked`, `CreatedAt` |
| `EmailVerification`          | `EmailVerification.cs`| OTP xác thực email đăng ký                                                  |
| `PasswordResetToken`         | `PasswordResetToken.cs`| OTP/Token khôi phục mật khẩu                                              |
| `DeviceToken`                | `DeviceToken.cs`      | FCM device token cho push notification (1 user có nhiều device)             |

### 1.2 Hồ sơ & Sức khỏe (Profile & Health)

| Entity                  | File                  | Mô tả                                                                            |
|-------------------------|-----------------------|-----------------------------------------------------------------------------------|
| `Profile`               | `Profile.cs`          | Hồ sơ cá nhân — `Id`, `UserId`, `FullName`, `PhoneNumber`, `Gender`, `DateOfBirth`, `AvatarUrl` |
| `HealthProfile`         | `HealthProfile.cs`    | Sức khỏe + target dinh dưỡng — `Height`, `Weight`, `TargetWeight`, `ActivityLevel`, `DietaryGoal`, `DailyCalorieLimit`, `DailyProteinLimit`, `DailyCarbsLimit`, `DailyFatLimit` |
| `WeightLog`             | `WeightLog.cs`        | Nhật ký cân nặng theo thời gian (vẽ biểu đồ xu hướng)                          |
| `NutritionSnapshot`     | `NutritionSnapshot.cs`| Ảnh chụp nhanh calo/macros tiêu thụ trong ngày                                   |

### 1.3 Dị ứng & Danh mục món ăn (Allergies, Foods & Recipes)

| Entity                  | File                    | Mô tả                                                                              |
|-------------------------|-------------------------|-----------------------------------------------------------------------------------|
| `Allergy`               | `Allergy.cs`            | Danh mục dị ứng master (Hải sản, Đậu phộng, Trứng, Sữa...)                       |
| `UserAllergy`           | `UserAllergy.cs`        | Quan hệ nhiều-nhiều User ↔ Allergy                                                |
| `Food`                  | `Food.cs`               | Danh mục thực phẩm cơ bản — `Name`, `Barcode`, `Brand`, `ServingSize`, `Calories`, `Protein`, `Carbs`, `Fat`, `Fiber`, `IsVerified` |
| `Ingredient`            | `Ingredient.cs`         | Nguyên liệu thô dùng trong nấu ăn                                                 |
| `Recipe`                | `Recipe.cs`             | Công thức nấu ăn — `Title`, `Description`, `Instructions`, `PrepTimeMinutes`, `CookTimeMinutes`, `Difficulty`, `Servings` |
| `RecipeIngredient`      | `RecipeIngredient.cs`   | Quan hệ nhiều-nhiều Recipe ↔ Ingredient kèm khối lượng                            |
| `FoodAllergenTag`       | `FoodAllergenTag.cs`    | Gắn thẻ dị ứng (`allergen_key`) vào food để scan nhanh độ an toàn                  |
| `FoodAllergy`           | `FoodAllergy.cs`        | Bảng quan hệ phụ cho allergy lookup                                                |
| `FoodPortionMapping`    | `FoodPortionMapping.cs` | Mapping giữa food và portion unit (vd 1 phần = 100g)                              |
| `DefaultPortionUnit`    | `DefaultPortionUnit.cs` | Đơn vị đo lường mặc định cho food (g, ml, oz...)                                  |
| `CustomUserPortion`     | `CustomUserPortion.cs`  | User tự custom portion riêng (vd "1 bát cơm của tôi")                             |
| `FavoriteFood`          | `FavoriteFood.cs`       | User đánh dấu food yêu thích                                                      |

### 1.4 Nhật ký Ăn uống & Kế hoạch (Meal Tracking & Planning)

| Entity                       | File                          | Mô tả                                                                       |
|------------------------------|-------------------------------|------------------------------------------------------------------------------|
| `MealLog`                    | `MealLog.cs`                  | Nhật ký bữa ăn — `UserId`, `MealType` (Breakfast/Lunch/Dinner/Snack), `LogDate`, `FoodId?`, `CustomFoodName?`, `GramsConsumed`, `Calories`, macros |
| `MealLogSubstitution`        | `MealLogSubstitution.cs`      | User thay thế món trong meal log (vd đổi từ gà sang cá)                    |
| `MealPlanHeader`             | `MealPlanHeader.cs`           | Kế hoạch ăn uống đã lên lịch trước cho user                                |
| `MealPlanItem`               | `MealPlanItem.cs`             | Item cụ thể trong meal plan (1 meal = n items)                              |
| `MealPlanItemSubstitution`   | `MealPlanItemSubstitution.cs` | User thay thế món trong meal plan                                            |
| `UserSubstitutionPreference` | `UserSubstitutionPreference.cs`| Preference của user cho phép thay thế (vd không ăn hành → tự động swap)   |
| `MealTemplate`               | `MealTemplate.cs`             | Template bữa ăn dùng lại được (vd "Bữa sáng healthy mẫu")                  |
| `MealTemplateItem`           | `MealTemplateItem.cs`         | Item trong meal template                                                     |

### 1.5 Giao dịch & Gói thành viên (Subscriptions & Payments)

| Entity                    | File                            | Mô tả                                                              |
|---------------------------|---------------------------------|---------------------------------------------------------------------|
| `SubscriptionPlan`        | `SubscriptionPlan.cs`           | Các gói dịch vụ (Free, Casual, Gym/PT, Office) — gói Pro đã ngừng phát hành |
| `UserSubscription`        | `UserSubscription.cs`           | Gói hiện tại của user + thời hạn                                   |
| `SubscriptionTransaction` | `SubscriptionTransaction.cs`    | Lịch sử giao dịch nâng cấp/hạ gói                                 |
| `Subscription`            | `Subscription.cs`               | Bảng subscription cũ (legacy, có thể trùng với UserSubscription)   |
| `Payment`                 | `Payment.cs`                    | Payment record tổng quát                                          |
| `SepayTransaction`        | `SepayTransaction.cs`           | Giao dịch đồng bộ từ cổng SePay VN                                |

### 1.6 AI & Recommendation

| Entity                    | File                              | Mô tả                                                              |
|---------------------------|-----------------------------------|---------------------------------------------------------------------|
| `AiConversation`         | `AiConversation.cs`               | Conversation giữa user và AI Nutrition Assistant                   |
| `AiMessage`               | `AiMessage.cs`                    | Message trong conversation (user/assistant role)                   |
| `UserAiProfile`           | `UserAiProfile.cs`                | Profile AI riêng cho user (preferences, restrictions learned)      |
| `RecommendationHistory`   | `RecommendationHistory.cs`        | Lịch sử recommendation đã gửi cho user                            |
| `RecommendationFeedback`  | `RecommendationFeedback.cs`        | User feedback (like/dislike) cho từng recommendation               |

### 1.7 Coach (Huấn luyện viên cá nhân)

| Entity             | File                  | Mô tả                                                                       |
|--------------------|-----------------------|------------------------------------------------------------------------------|
| `CoachProfile`     | `CoachProfile.cs`     | Hồ sơ coach — `UserId`, `Specialty`, `Bio`, `ExperienceYears`, `CertificateUrl`, `PriceVnd`, `IsActive` |
| `CoachConnection`  | `CoachConnection.cs`  | Quan hệ Client ↔ Coach — `Status` (Pending/Connected/Rejected/Disconnected), `IsAccessGranted` |
| `CoachFeedback`    | `CoachFeedback.cs`    | Coach feedback cho client (theo Meal/Daily/General)                          |
| `PtReviewRequest`  | `PtReviewRequest.cs`  | User yêu cầu PT review (personal training review)                          |

### 1.8 Premium Programs (Khóa học/chương trình premium)

| Entity                  | File                       | Mô tả                                                              |
|-------------------------|----------------------------|---------------------------------------------------------------------|
| `PremiumProgram`        | `PremiumProgram.cs`        | Template chương trình premium (vd "Giảm 5kg trong 30 ngày")        |
| `UserPremiumProgram`    | `UserPremiumProgram.cs`    | User đăng ký chương trình nào                                      |
| `UserProgramMilestone`  | `UserProgramMilestone.cs`  | Tiến độ user đạt được các milestone trong chương trình             |

### 1.9 Notifications, Reminders, Campaigns

| Entity                  | File                       | Mô tả                                                                              |
|-------------------------|----------------------------|------------------------------------------------------------------------------------|
| `Notification`          | `Notification.cs`          | Push notification — `UserId`, `Title`, `Body`, `Type`, `IsRead`, `ScheduledAt?`, `SentAt?`, `ReadAt?`, `ClickedAt?`, `ActionCompletedAt?`, `IsDismissed?` |
| `NotificationSetting`   | `NotificationSetting.cs`   | User setting cho từng loại notification (bật/tắt, quiet hours)                    |
| `Campaign`              | `Campaign.cs`              | Marketing campaign (gửi notification hàng loạt cho segment)                      |
| `ReminderProfile`       | `ReminderProfile.cs`       | Adaptive reminder pattern cho từng user (sau này optimize theo behavior)         |
| `GoalDriftAlert`        | `GoalDriftAlert.cs`        | Alert khi user drift khỏi goal (vd 3 ngày không log meal)                        |

### 1.10 Micro Learning & Engagement

| Entity                    | File                            | Mô tả                                                                       |
|---------------------------|---------------------------------|------------------------------------------------------------------------------|
| `MicroLearningCard`       | `MicroLearningCard.cs`          | Thẻ học nhanh (vd "Tip: Uống nước trước bữa 30 phút")                      |
| `UserCardInteraction`     | `UserCardInteraction.cs`        | User tương tác với card (viewed/liked/skipped)                               |

### 1.11 Activity & Budget

| Entity             | File                  | Mô tả                                                                       |
|--------------------|-----------------------|------------------------------------------------------------------------------|
| `ActivityLog`      | `ActivityLog.cs`      | Log mọi action của user (audit trail)                                        |
| `BudgetRequest`    | `BudgetRequest.cs`    | User yêu cầu support về budget cho meal plan                                 |

---

## 2. Business Logic DTOs (MenuGreen.BusinessLogicLayer)

Data Transfer Objects định nghĩa cấu trúc data truyền nhận qua API, phân tách Request/Response.

### 2.1 Response DTOs nổi bật

| DTO                            | Mô tả                                                                            |
|--------------------------------|----------------------------------------------------------------------------------|
| `CvInferenceResponse`          | Response từ phân tích ảnh AI (food recognition)                                  |
| `CvSuggestedDish`              | Món ăn gợi ý + cờ `IsSafeForUser`, `MatchedAllergens`                         |
| `MealDaySummaryResponse`       | Báo cáo tổng quan dinh dưỡng tiêu thụ trong ngày                               |
| `DashboardMetricsResponse`     | Số liệu analytics hiển thị trên Dashboard                                      |
| `AllergenRiskResult`          | Mức độ rủi ro dị ứng của món ăn đối với user cụ thể                          |
| `SepayOrderResponse`           | Dữ liệu hóa đơn thanh toán qua cổng SePay                                      |
| `RecommendationResponse`       | Kết quả recommendation engine (rule-based)                                      |
| `AiChatResponse`               | Response từ AI Nutrition Assistant                                              |

### 2.2 Request DTOs

| DTO                       | Mô tả                                              |
|---------------------------|-----------------------------------------------------|
| `RegisterRequest`         | Email, password, fullName                          |
| `LoginRequest`            | Email, password                                     |
| `MealLogCreateRequest`    | FoodId, gramsConsumed, mealType, logDate           |
| `HealthProfileUpdateRequest` | Height, weight, goal, activity level            |

Chi tiết từng DTO: xem `MenuGreen.BusinessLogicLayer/Dtos/`.

---

## 3. Pydantic Schemas (Python CV Service)

Model trong `cv-service/app/schemas/cv_schemas.py` (Pydantic v2) cho dịch vụ FastAPI xử lý ảnh AI.

| Schema                | Mô tả                                                                       |
|-----------------------|------------------------------------------------------------------------------|
| `BoundingBox`         | Tọa độ pixel phát hiện đối tượng trên ảnh — `x1`, `y1`, `x2`, `y2`        |
| `DetectedFood`         | Món ăn / nguyên liệu được nhận diện bởi mô hình thị giác máy tính         |
| `MacroNutrients`      | Lượng dinh dưỡng đa lượng tiêu chuẩn — `calories_kcal`, `protein_g`, `carbs_g`, `fat_g`, `fiber_g` |
| `FoodNutrition`       | Thông tin dinh dưỡng đầy đủ của một món ăn được định lượng                  |
| `AnalysisResult`      | Output của luồng xử lý ảnh cục bộ (Local Object Detection)                 |
| `AIInferenceResponse` | Output của Generative AI (Gemini) cho hội thoại / phân tích                  |
| `JobStatusResponse`   | Trạng thái hàng đợi bất đồng bộ Celery — `queued` / `processing` / `done` / `failed` |

---

## 4. Sơ đồ quan hệ tổng quan (rút gọn)

```
User ──┬── Profile (1:1)
       ├── HealthProfile (1:1)
       ├── UserAllergy (M:N Allergy)
       ├── WeightLog (1:M)
       ├── MealLog (1:M) ──── Food (N:1)
       ├── UserSubscription (1:M) ──── SubscriptionPlan (N:1)
       ├── SepayTransaction (1:M)
       ├── AiConversation (1:M) ──── AiMessage (1:M)
       ├── CoachConnection (1:M) ──── CoachProfile (1:M, qua User)
       ├── Notification (1:M)
       ├── Session (1:M)
       ├── FavoriteFood (1:M) ──── Food
       └── UserPremiumProgram (1:M) ──── PremiumProgram

Recipe ── RecipeIngredient (M:N Ingredient)
Food ──── FoodAllergenTag (1:M) ──── Allergy
Food ──── FoodPortionMapping (1:M) ──── DefaultPortionUnit
```

---

## 5. Index & Performance

Một số index quan trọng đã được config trong `ApplicationDbContext` / `IEntityTypeConfiguration<T>`:

- `User.Email` — unique
- `User.RoleId` — FK index
- `Session.RefreshToken` — unique + index
- `Session.UserId` — FK index
- `MealLog.UserId` + `LogDate` — composite index (query daily tracking)
- `Notification.UserId` + `CreatedAt` — composite index (query recent notifications)
- `EmailVerification.Email` + `ExpiresAt` — composite index (validate OTP)
- `PasswordResetToken.UserId` + `ExpiresAt` — composite index

Khi thêm entity mới, **đảm bảo** config index cho mọi FK và cột thường được query (WHERE/ORDER BY).

---

## 6. Conventions

- **Primary key:** `Guid Id` cho mọi entity (không dùng int auto-increment).
- **Timestamp:** `CreatedAt` (DateTime UTC), `UpdatedAt` (DateTime UTC), set qua SaveChanges interceptor.
- **Soft delete:** KHÔNG dùng (chỉ hard delete qua service).
- **Audit:** `ActivityLog` ghi lại các action quan trọng (login, payment, profile update...).
- **Naming:** PascalCase cho C# property, snake_case cho PostgreSQL column (config qua `HasColumnName`).

---

## 7. Liên quan

- `MenuGreen.DataAccessLayer/Entities/*.cs` — 57 entity files
- `MenuGreen.BusinessLogicLayer/Dtos/` — Request/Response DTOs
- `cv-service/app/schemas/cv_schemas.py` — Pydantic schemas
- [`../01-deployment/CI_CD.md`](../01-deployment/CI_CD.md#database-migration) — Cách migration chạy tự động
- [`README_BACKEND_OVERVIEW.md`](./README_BACKEND_OVERVIEW.md) — Tổng quan backend (architecture, security, business logic)
