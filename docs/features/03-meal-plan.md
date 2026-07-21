# 03. Meal Plan

**Status:** API Done · UI Done (100%)
**Last updated:** 2026-07-09

**Related controllers:**
- `backend/MenuGreen.API/Controllers/MealPlanController.cs`
- `backend/MenuGreen.API/Controllers/NotificationController.cs` (cho meal-plan-remind)

**Related Flutter feature:** `frontend/lib/features/meal_plan/`

---

## 1. Overview

Meal Plan giúp user lên kế hoạch ăn uống theo ngày/tuần:

- Tạo plan với các món/công thức theo `MealType`.
- Đặt lịch nhắc bữa ăn qua Notification.
- Convert plan item sang meal log thật.
- Theo dõi streaks và dashboard ngày.

---

## 2. Business Rules

### 2.1 Calorie Distribution (phân bổ calo theo bữa)

| Bữa ăn | Tỷ lệ | Ví dụ (2000 kcal) |
|---------|--------|-------------------|
| Breakfast | 25% | 500 kcal |
| Lunch | 35% | 700 kcal |
| Dinner | 30% | 600 kcal |
| Snack | 10% | 200 kcal |

Nguồn: HealthcareOnTime (calorie distribution) + PMC 2024 (meal timing meta-analysis). Chi tiết formula: [`10-vietnam-local-features.md` → Appendix A.11](./10-vietnam-local-features.md#11-meal-plan--meal-plan-calorie-distribution).

### 2.2 Streak Logic

- Hôm nay được tính khi user có kế hoạch cho hôm nay hoặc đã log/hoàn thành ít nhất 1 bữa.
- Với ngày đã qua, streak chỉ tính ngày đã log hoặc hoàn thành ít nhất 1 món trong kế hoạch.
- Reset = 0 nếu không có hoạt động hợp lệ trong hôm nay và hôm qua.
- Ngày được quy đổi theo múi giờ Việt Nam (UTC+7) trước khi đếm chuỗi liên tiếp.

### 2.3 Quick Actions

- **Convert-to-log:** chuyển 1 plan item thành meal log (giữ nguyên khối lượng, meal slot).
- **Commit:** ghi toàn bộ items trong plan thành meal logs theo ngày.
- **Duplicate:** tạo plan mới dựa trên plan cũ (kế hoạch tuần mới từ tuần cũ).

### 2.4 Reminder (Notification)

- Meal-plan-remind dùng `NotificationController` để gửi push notification nhắc trước giờ ăn.
- Lịch nhắc do user cấu hình trong Notification Settings (xem [`07-notification.md`](./07-notification.md)).

---

## 3. API Endpoints

### 3.1 Plan CRUD

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/MealPlan?isActive=` | Danh sách plans (lọc isActive) |
| `GET` | `/api/MealPlan/{id}` | Chi tiết plan |
| `POST` | `/api/MealPlan` | Tạo plan mới |
| `POST` | `/api/MealPlan/empty` | Tạo plan rỗng (user thêm items sau) |
| `PUT` | `/api/MealPlan/{id}` | Cập nhật plan |
| `DELETE` | `/api/MealPlan/{id}` | Xóa plan |
| `PATCH` | `/api/MealPlan/{id}/status` | Cập nhật status (active/inactive) |
| `POST` | `/api/MealPlan/{id}/distribute` | Gửi plan cho target audience |

### 3.2 Plan Items CRUD

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/MealPlan/{planId}/items` | Thêm item |
| `PUT` | `/api/MealPlan/{planId}/items/{itemId}` | Cập nhật item |
| `DELETE` | `/api/MealPlan/{planId}/items/{itemId}` | Xóa item |
| `PATCH` | `/api/MealPlan/{planId}/items/{itemId}/status` | Cập nhật status item |
| ~~| `POST` | `/api/MealPlan/{planId}/items/{itemId}/substitute-ingredient` | Thay thế nguyên liệu trong plan item |~~ *(thực tế thuộc `IngredientSubstitutionController` — xem [04-discover-and-allergy.md §3.5](./04-discover-and-allergy.md#35-ingredient-substitution-ingredientsubstitutioncontroller))* |
| `POST` | `/api/MealPlan/{planId}/items/{itemId}/convert-to-log` | Convert sang meal log |

### 3.3 Plan Actions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/MealPlan/{planId}/commit` | Commit toàn bộ plan thành logs |
| `POST` | `/api/MealPlan/{planId}/duplicate` | Duplicate plan sang date range mới |

### 3.4 Dashboard & Stats

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/MealPlan/dashboard?date=` | Dashboard ngày (planned vs actual) |
| `GET` | `/api/MealPlan/compare?from=&to=` | So sánh planned vs actual |
| `GET` | `/api/MealPlan/streaks` | Streak hiện tại |
| `GET` | `/api/MealPlan/adherence-scores` | Budget adherence scores |

### 3.5 Budget & Alternatives

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/MealPlan/generate-by-budget` | Tự động tạo weekly menu theo ngân sách |
| `GET` | `/api/MealPlan/{id}/budget-status` | So sánh chi phí plan với ngân sách user |
| `GET` | `/api/MealPlan/{planId}/alternatives/{itemId}` | Gợi ý món rẻ hơn cho item |

### 3.6 Expenses

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/MealPlan/compare-expenses?from=&to=` | So sánh chi phí thực tế (meal logs) với kế hoạch |
| `GET` | `/api/MealPlan/expense-breakdown` | Phân tích chi phí theo category + gợi ý tiết kiệm |

### 3.7 Reminder (Notification Controller)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Notification/meal-plan-remind` | Nhắc meal plan (push) |
| `POST` | `/api/Notification/schedule-prep-reminder` | Nhắc chuẩn bị bữa trước |

> **Ghi chú:** Reminder UI (settings + inbox) thuộc [`07-notification.md`](./07-notification.md); endpoint meal-plan-remind đặt tại NotificationController nhưng liên quan Meal Plan, nên liệt kê ở đây để dễ tham chiếu.

**Tổng: 30 endpoint** (24 MealPlanController + 6 PlannedVsActualController). Notification reminders đã gộp trong §3.7.

---

## 4. UI Components

### 4.1 Models & Requests

| Component | File | Status |
|-----------|------|--------|
| MealPlanListItem | `features/meal_plan/models/meal_plan_models.dart` | Done |
| MealPlanDetail | `features/meal_plan/models/meal_plan_responses.dart` | Done |
| MealPlanItemDetail | `features/meal_plan/models/meal_plan_responses.dart` | Done |
| MealPlanDayDashboard | `features/meal_plan/models/meal_plan_responses.dart` | Done |
| MealPlanCompare | `features/meal_plan/models/meal_plan_responses.dart` | Done |
| MealPlanStreak | `features/meal_plan/models/meal_plan_responses.dart` | Done |
| CreatePlanRequest | `features/meal_plan/models/meal_plan_requests.dart` | Done |
| CreateEmptyPlanRequest | `features/meal_plan/models/meal_plan_requests.dart` | Done |
| DuplicatePlanRequest | `features/meal_plan/models/meal_plan_requests.dart` | Done |
| AddItemRequest | `features/meal_plan/models/meal_plan_requests.dart` | Done |
| ConvertToLogRequest | `features/meal_plan/models/meal_plan_requests.dart` | Done |

### 4.2 Provider & Repository

| Component | File | Status |
|-----------|------|--------|
| MealPlanProvider | `features/meal_plan/providers/meal_plan_provider.dart` | Done |
| MealPlanRepository | `features/meal_plan/repositories/meal_plan_repository.dart` | Done |
| meal_plan.dart (barrel export) | `features/meal_plan/meal_plan.dart` | Done |

### 4.3 Screens

| Component | File | Status |
|-----------|------|--------|
| MealPlanScreen | `features/meal_plan/views/meal_plan_screen.dart` | Done |
| MealPlanTodayScreen | `features/meal_plan/views/meal_plan_today_screen.dart` | Done |
| MealPlanDetailScreen | `features/meal_plan/views/meal_plan_detail_screen.dart` | Done |
| CreateMealPlanScreen | `features/meal_plan/views/create_meal_plan_screen.dart` | Done |
| MealPlanStatsScreen | `features/meal_plan/views/meal_plan_stats_screen.dart` | Done |
| MealPlanCalendarScreen | `features/meal_plan/views/meal_plan_calendar_screen.dart` | Done |

### 4.4 Widgets

| Component | File | Status |
|-----------|------|--------|
| CalorieProgressRing | `features/meal_plan/widgets/calorie_progress_ring.dart` | Done |
| MealItemTile | `features/meal_plan/widgets/meal_item_tile.dart` | Done |
| AddItemSheet | `features/meal_plan/widgets/add_item_sheet.dart` | Done |
| EditItemSheet | `features/meal_plan/widgets/edit_item_sheet.dart` | Done |

**Tổng:** 30 endpoint API, 6 screens, 4 widgets.

---

## 5. Navigation Flow

```
MainScreen (Tab index 2)
    └── MealPlanScreen
        ├── Today Tab ─→ MealPlanTodayScreen
        ├── All Plans Tab
        └── History Tab ─→ MealPlanCalendarScreen

MealPlanDetailScreen (từ list)
    ├── AddItemSheet (thêm món)
    ├── EditItemSheet (sửa món)
    ├── Tap food item → FoodDetailScreen (xem 04-discover-and-allergy.md)
    ├── Tap recipe item → RecipeDetailScreen (xem 04-discover-and-allergy.md)
    └── MealPlanStatsScreen
            ├── _setReminders → NotificationController
            └── _comparePlan → so sánh planned vs actual

CreateMealPlanScreen
    └── MealPlanDetailScreen (sau khi tạo)
```

---

## 6. Data Models (rút gọn)

```
MealPlanHeader
├── Id, UserId, Title, Description
├── StartDate, EndDate
├── IsActive, Status
├── TargetCalories, TargetBudgetVnd
└── Items[] (MealPlanItem)

MealPlanItem
├── Id, PlanId, MealType (Breakfast/Lunch/Dinner/Snack)
├── PlannedDate, ScheduledTime
├── FoodId? (nullable), RecipeId? (nullable)
├── Grams, CaloriesKcal, ProteinG, CarbsG, FatG
├── Status (Planned/Completed/Skipped)
├── CompletedAt?
└── MealLogId? (sau khi convert-to-log)

MealPlanDayDashboard
├── Date, TotalPlannedCalories
├── TotalActualCalories
├── PlannedItems[], ActualItems[]
└── AdherenceScore

MealPlanCompare (range)
├── FromDate, ToDate
├── TotalPlanned{Calories, Cost}
├── TotalActual{Calories, Cost}
└── Difference

MealPlanStreak
├── CurrentStreak, LongestStreak
├── LastLogDate
└── TotalDaysTracked
```

Backend models đầy đủ: [`../02-backend/backend_models_documentation.md`](../02-backend/backend_models_documentation.md) (mục 1.4 Meal Plan).

---

## 7. Related Documents

- Convert plan → meal log: [`02-nutrition-tracking.md`](./02-nutrition-tracking.md)
- Reminder UI (settings/inbox): [`07-notification.md`](./07-notification.md)
- Calorie distribution formula: [`10-vietnam-local-features.md` → Appendix A.11](./10-vietnam-local-features.md#11-meal-plan--meal-plan-calorie-distribution)
- Streak logic: [`10-vietnam-local-features.md` → Appendix A.15](./10-vietnam-local-features.md#15-streak)
- Planned vs Actual analytics: [`09-analytics.md`](./09-analytics.md)
- AI tạo meal plan: [`06-ai-assistant-and-coach.md`](./06-ai-assistant-and-coach.md)
- File cũ (archive): [`../_archive/features/MEAL_PLAN.md`](../_archive/features/MEAL_PLAN.md)
