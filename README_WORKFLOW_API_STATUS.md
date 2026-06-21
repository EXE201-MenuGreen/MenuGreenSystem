# README: WORKFLOW API STATUS

**Cập nhật:** 2026-06-17

Tài liệu này ghi nhận chi tiết trạng thái API và UI của từng workflow, so sánh **API cần có** (theo thiết kế) với **API đã có** (trong codebase) và liệt kê **API còn thiếu** cần triển khai thêm.

---

## Mục lục

1. [2.5 Meal Plan](#25-meal-plan) - ✅ HOÀN THÀNH
2. [2.6 Recommendation](#26-recommendation) - ✅ HOÀN THÀNH
3. [2.7 AI Assistant](#27-ai-assistant)
4. [2.8 Subscription & Payment](#28-subscription--payment) - ✅ HOÀN THÀNH
5. [2.9 Notification](#29-notification)
6. [2.10 Analytics](#210-analytics)
7. [2.11 Vietnam-first Local Nutrition](#211-vietnam-first-local-nutrition) - ✅ HOÀN THÀNH
8. [2.12 Beginner quick-start workflow](#212-beginner-quick-start-workflow-hôm-nay-ăn-gì) - ✅ HOÀN THÀNH
9. [2.13 Gym/PT goal-based workflow](#213-gympt-goal-based-workflow) - ✅ HOÀN THÀNH
10. [2.14 Real-world food data capture](#214-real-world-food-data-capture) - ✅ HOÀN THÀNH
11. [2.15 Safety, trust, and compliance](#215-safety-trust-and-compliance) - ✅ HOÀN THÀNH

---

## 2.5 Meal Plan

**File Controller:** `backend/MenuGreen.API/Controllers/MealPlanController.cs`

**File Flutter:** `frontend/lib/features/meal_plan/`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Meal plan header CRUD | ✅ Hoàn tất | |
| B. Meal plan item CRUD | ✅ Hoàn tất | |
| C. Quick actions (convert/commit/duplicate) | ✅ Hoàn tất | |
| D. Routine / reminder | ✅ Hoàn tất | `NotificationController` |
| E. Báo cáo planned vs actual | ✅ Hoàn tất | |

| Nhóm UI | Trạng thái | Ghi chú |
|---------|:----------:|---------|
| A. Models & Requests | ✅ Hoàn tất | |
| B. Provider & Repository | ✅ Hoàn tất | |
| C. Screens (5 screens) | ✅ Hoàn tất | |
| D. Widgets (4 widgets) | ✅ Hoàn tất | |
| E. Navigation integration | ✅ Hoàn tất | |

### Backend API đã có

```
GET    /api/MealPlan                              # GetAll (lọc isActive)
GET    /api/MealPlan/{id}                         # GetById
POST   /api/MealPlan                              # Create
PUT    /api/MealPlan/{id}                         # Update
DELETE /api/MealPlan/{id}                         # Delete
PATCH  /api/MealPlan/{id}/status                  # UpdateStatus

POST   /api/MealPlan/{planId}/items               # AddItem
PUT    /api/MealPlan/{planId}/items/{itemId}     # UpdateItem
DELETE /api/MealPlan/{planId}/items/{itemId}     # DeleteItem
PATCH  /api/MealPlan/{planId}/items/{itemId}/status

POST   /api/MealPlan/{planId}/items/{itemId}/convert-to-log
POST   /api/MealPlan/{planId}/commit
POST   /api/MealPlan/{planId}/duplicate

GET    /api/MealPlan/dashboard?date=              # Dashboard ngày
GET    /api/MealPlan/compare?from=&to=           # Compare planned vs actual
GET    /api/MealPlan/streaks                     # Streaks

# Từ NotificationController
POST   /api/Notification/meal-plan-remind
GET    /api/Notification/settings
PUT    /api/Notification/settings
```

### Flutter Components đã có

| Component | File | Trạng thái |
|-----------|------|:-----------:|
| **Models** | | |
| MealPlanListItem | `models/meal_plan_models.dart` | ✅ |
| MealPlanDetail | `models/meal_plan_responses.dart` | ✅ |
| MealPlanItemDetail | `models/meal_plan_responses.dart` | ✅ |
| MealPlanDayDashboard | `models/meal_plan_responses.dart` | ✅ |
| MealPlanCompare | `models/meal_plan_responses.dart` | ✅ |
| MealPlanStreak | `models/meal_plan_responses.dart` | ✅ |
| **Requests** | | |
| CreatePlanRequest | `models/meal_plan_requests.dart` | ✅ |
| CreateEmptyPlanRequest | `models/meal_plan_requests.dart` | ✅ |
| DuplicatePlanRequest | `models/meal_plan_requests.dart` | ✅ |
| AddItemRequest | `models/meal_plan_requests.dart` | ✅ |
| ConvertToLogRequest | `models/meal_plan_requests.dart` | ✅ |
| **Provider** | | |
| MealPlanProvider | `providers/meal_plan_provider.dart` | ✅ |
| **Repository** | | |
| MealPlanRepository | `repositories/meal_plan_repository.dart` | ✅ |
| **Views** | | |
| MealPlanScreen | `views/meal_plan_screen.dart` | ✅ |
| MealPlanDetailScreen | `views/meal_plan_detail_screen.dart` | ✅ |
| CreateMealPlanScreen | `views/create_meal_plan_screen.dart` | ✅ |
| MealPlanStatsScreen | `views/meal_plan_stats_screen.dart` | ✅ |
| MealPlanCalendarScreen | `views/meal_plan_calendar_screen.dart` | ✅ |
| **Widgets** | | |
| CalorieProgressRing | `widgets/calorie_progress_ring.dart` | ✅ |
| MealItemTile | `widgets/meal_item_tile.dart` | ✅ |
| AddItemSheet | `widgets/add_item_sheet.dart` | ✅ |
| EditItemSheet | `widgets/edit_item_sheet.dart` | ✅ |

### Navigation Flow

```
MainScreen (Tab index 2)
    └── MealPlanScreen
        ├── Today Tab
        ├── All Plans Tab
        └── History Tab

MealPlanDetailScreen (từ list)
    ├── AddItemSheet (thêm món)
    ├── EditItemSheet (sửa món)
    ├── FoodDetailScreen (tap food item)
    ├── RecipeDetailScreen (tap recipe item)
    └── MealPlanStatsScreen (_setReminders, _comparePlan)

CreateMealPlanScreen
    └── MealPlanDetailScreen (sau khi tạo)
```

### Kết luận

**Meal Plan Workflow: ✅ HOÀN THÀNH 100%**

- Backend API: ✅ Hoàn chỉnh (26 endpoints)
- Flutter Models: ✅ Hoàn chỉnh
- Flutter Provider: ✅ Hoàn chỉnh
- Flutter Repository: ✅ Hoàn chỉnh
- Flutter Views: ✅ Hoàn chỉnh (5 screens)
- Flutter Widgets: ✅ Hoàn chỉnh (4 widgets)
- Navigation: ✅ Tích hợp trong MainScreen
- Barrel Export: ✅ Hoàn chỉnh

---

## 2.6 Recommendation

**File Controller:** `backend/MenuGreen.API/Controllers/RecommendationController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Sinh recommendation | ✅ Hoàn tất | `generate`, `generate/safe`, `generate/weekly-plan`, `generate/budget-aware` |
| B. Lưu lịch sử và truy vấn | ✅ Hoàn tất | `history`, `preview` |
| C. Feedback loop | ✅ Hoàn tất | `POST feedback`, `PUT feedback/{id}`, `GET feedback/summary` |
| D. Giải thích recommendation | ✅ Hoàn tất | `explain/{id}` |
| E. Tối ưu cá nhân hóa | ✅ Hoàn tất | `scores`, `retrain` |

| Nhóm UI | Trạng thái | Ghi chú |
|---------|:----------:|---------|
| A. Screens & Widgets | ✅ Hoàn thành | |

### API đã có

```
GET    /api/Recommendation/calories
GET    /api/Recommendation/eco
GET    /api/Recommendation/lunch
GET    /api/Recommendation/daily-menu
POST   /api/Recommendation/smart-schedule
GET    /api/Recommendation/history
GET    /api/Recommendation/{id}
POST   /api/Recommendation/preview
POST   /api/Recommendation/feedback
GET    /api/Recommendation/explain/{id}
GET    /api/Recommendation/scores
POST   /api/Recommendation/retrain
POST   /api/Recommendation/generate
POST   /api/Recommendation/generate/safe
POST   /api/Recommendation/generate/weekly-plan
POST   /api/Recommendation/generate/budget-aware
PUT    /api/Recommendation/feedback/{id}
GET    /api/Recommendation/feedback/summary
```

### Kết luận

**Recommendation Workflow: ✅ HOÀN THÀNH 100%**

- Backend API: ✅ Hoàn chỉnh (19 endpoints)
- Flutter Models: ✅ Hoàn chỉnh
- Flutter Repository: ✅ Hoàn chỉnh
- Flutter Provider: ✅ Hoàn chỉnh
- Flutter Views: ✅ Hoàn thành (5 screens)
- Flutter Widgets: ✅ Hoàn thành (5 widgets)
- Navigation: ✅ Tích hợp trong DiscoverView

---

## 2.7 AI Assistant

**File Controller:** `backend/MenuGreen.API/Controllers/AiAssistantController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Conversation lifecycle | ✅ Hoàn tất | CRUD conversations |
| B. Message workflow | ✅ Hoàn tất | Send/regenerate/feedback |
| C. Context & profile | ✅ Hoàn tất | |
| D. Action suggestions | ✅ Hoàn tất | |
| E. History/analytics | ✅ Hoàn tất | |

| Nhóm UI | Trạng thái | Ghi chú |
|---------|:----------:|---------|
| A. Chat screen | 🟡 Placeholder | Cần nối với API |

### API đã có

```
POST   /api/AiAssistant/conversations
GET    /api/AiAssistant/conversations
GET    /api/AiAssistant/conversations/{id}
DELETE /api/AiAssistant/conversations/{id}
PATCH  /api/AiAssistant/conversations/{id}/title

POST   /api/AiAssistant/conversations/{id}/messages
GET    /api/AiAssistant/conversations/{id}/messages
POST   /api/AiAssistant/conversations/{id}/messages/{msgId}/regenerate
PATCH  /api/AiAssistant/conversations/{id}/messages/{msgId}/feedback

GET    /api/AiAssistant/context
PUT    /api/AiAssistant/context
GET    /api/AiAssistant/profile
PUT    /api/AiAssistant/profile

GET    /api/AiAssistant/suggestions
POST   /api/AiAssistant/actions/meal-plan
POST   /api/AiAssistant/actions/replace-food
POST   /api/AiAssistant/actions/budget-optimize

GET    /api/AiAssistant/insights
GET    /api/AiAssistant/conversations/{id}/summary
GET    /api/AiAssistant/usage
```

### Kết luận

**AI Assistant API: ✅ HOÀN CHỈNH**

Cần triển khai UI Flutter (chat screen) để kết nối với các API.

---

## 2.8 Subscription & Payment

**File Controllers:** 
- `backend/MenuGreen.API/Controllers/UserSubscriptionController.cs`
- `backend/MenuGreen.API/Controllers/SepayController.cs`
- `backend/MenuGreen.API/Controllers/SubscriptionPlanController.cs` (Admin CRUD)

**File Flutter:** `frontend/lib/features/subscription/`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. SubscriptionPlan CRUD (Admin) | ✅ Hoàn tất | |
| B. UserSubscription Workflow | ✅ Hoàn tất | subscribe/renew/cancel (gia hạn gói miễn phí trực tiếp) |
| C. SePay Payment QR & Webhook | ✅ Hoàn tất | create-order/create-renew-order/webhook |
| D. Subscription History & Metrics | ✅ Hoàn tất | |

| Nhóm UI | Trạng thái | Ghi chú |
|---------|:----------:|---------|
| A. Upgrade Screen | ✅ Hoàn tất | Màn hình chọn gói & lịch sử |
| B. SePay Payment Screen | ✅ Hoàn tất | Màn hiển thị QR thanh toán |

### API đã có

```
# SubscriptionPlan (Admin)
GET    /api/SubscriptionPlan                     # GetAll
GET    /api/SubscriptionPlan/{id}                # GetById
GET    /api/SubscriptionPlan/{id}/features       # GetFeatures
GET    /api/SubscriptionPlan/{id}/status         # GetStatus
POST   /api/SubscriptionPlan                     # Create
PUT    /api/SubscriptionPlan/{id}                # Update
DELETE /api/SubscriptionPlan/{id}                # Delete
PATCH  /api/SubscriptionPlan/{id}/status         # UpdateStatus

# UserSubscription (User)
GET    /api/UserSubscription/plans               # GetAvailablePlans (Lấy gói active)
POST   /api/UserSubscription/subscribe           # Subscribe (Gói miễn phí)
POST   /api/UserSubscription/renew               # Renew (Gói miễn phí)
POST   /api/UserSubscription/cancel              # Cancel
GET    /api/UserSubscription/me                  # GetCurrent
GET    /api/UserSubscription/{id}                # GetById
GET    /api/UserSubscription/me/history          # GetHistory

# SePay Payments
POST   /api/payments/sepay/create-order          # Tạo đơn mới
POST   /api/payments/sepay/create-renew-order    # Tạo đơn gia hạn
GET    /api/payments/sepay/pending               # Đơn hàng đang chờ
GET    /api/payments/sepay/{paymentId}           # Trạng thái đơn hàng
POST   /api/payments/sepay/webhook               # Webhook xác thực SePay
```

---

## 2.9 Notification

**File Controller:** `backend/MenuGreen.API/Controllers/NotificationController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Notification setting | ✅ Hoàn tất | |
| B. Notification inbox | ✅ Hoàn tất | |
| C. Gửi notification | ✅ Hoàn tất | |
| D. Re-engagement campaign | ✅ Hoàn tất | |
| E. Tracking open/click | ✅ Hoàn tất | |
| F. Analytics | ✅ Hoàn tất | |

| Nhóm UI | Trạng thái | Ghi chú |
|---------|:----------:|---------|
| A. Settings screen | ✅ Hoàn tất | Card-based UI với toggle & slider |
| B. Inbox screen | ✅ Hoàn tất | Swipe actions, pagination, badge |

### API đã có

```
GET    /api/Notification/settings
PUT    /api/Notification/settings
POST   /api/Notification/settings/reset
GET    /api/Notification/channels

GET    /api/Notification
GET    /api/Notification/{id}
GET    /api/Notification/unread-count
PATCH  /api/Notification/{id}/read
PATCH  /api/Notification/{id}/open
PATCH  /api/Notification/{id}/dismiss
PATCH  /api/Notification/read-all
DELETE /api/Notification/{id}
DELETE /api/Notification/batch
DELETE /api/Notification/range

POST   /api/Notification/meal-plan-remind
POST   /api/Notification/schedule-prep-reminder
POST   /api/Notification/send

POST   /api/Notification/{id}/track/open
POST   /api/Notification/{id}/track/click
POST   /api/Notification/{id}/track/action-complete

GET    /api/Notification/analytics
```

### Kết luận

**Notification API: ✅ HOÀN CHỈNH**
**Notification UI: ✅ HOÀN TẤT**

Đã triển khai đầy đủ UI Flutter (settings, inbox screens) với:
- Settings: Card-based UI, toggle meal reminder, prep reminder, push/in-app channels
- Inbox: Danh sách notification với swipe actions, pagination, badge count, tracking

---

## 2.10 Analytics

**File Controller:** `backend/MenuGreen.API/Controllers/AnalyticsController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Activity log | ✅ Hoàn tất | |
| B. Dashboard & metrics | ✅ Hoàn tất | |
| C. Funnel analysis | ✅ Hoàn tất | |
| D. Cohort analysis | ✅ Hoàn tất | |
| E. Churn & retention | ✅ Hoàn tất | |
| F. Export | ✅ Hoàn tất | |

| Nhóm UI | Trạng thái | Ghi chú |
|---------|:----------:|---------|
| A. Admin dashboard | ❌ Chưa có | |

### API đã có

```
POST   /api/Analytics/activity-log
POST   /api/Analytics/activity-log/bulk
GET    /api/Analytics/activity-log
GET    /api/Analytics/activity-log/{id}

GET    /api/Analytics/dashboard
GET    /api/Analytics/summary
GET    /api/Analytics/metrics
GET    /api/Analytics/top-events

GET    /api/Analytics/funnel
POST   /api/Analytics/funnel/preview
GET    /api/Analytics/funnel/meal-onboarding
GET    /api/Analytics/funnel/subscription

GET    /api/Analytics/cohort
GET    /api/Analytics/cohort/retention
GET    /api/Analytics/cohort/by-signup-date
GET    /api/Analytics/cohort/by-first-meal-log
GET    /api/Analytics/cohort/by-subscription

GET    /api/Analytics/drop-off
GET    /api/Analytics/churn-risk
GET    /api/Analytics/inactive-users
GET    /api/Analytics/reactivation-opportunities

GET    /api/Analytics/export/activity-log
GET    /api/Analytics/export/funnel
GET    /api/Analytics/export/cohort
```

### Kết luận

**Analytics API: ✅ HOÀN CHỈNH**

Cần triển khai Admin UI Flutter để hiển thị dashboard và báo cáo.

---

## 2.11 Vietnam-first Local Nutrition

**File Controller:** `backend/MenuGreen.API/Controllers/VietnamNutritionController.cs` và `backend/MenuGreen.API/Controllers/PortionConverterController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Local preference onboarding | ✅ Hoàn tất | `GET/POST/PUT /api/Nutrition/local-preferences` |
| B. Localized food discovery | ✅ Hoàn tất | `/api/Nutrition/discovery/local/...` |
| C. Portion / unit conversion | ✅ Hoàn tất | `/api/PortionConverter/...` |
| D. Vietnamese meal logging | ✅ Hoàn tất | `/api/Nutrition/meal-log/vn/...` |
| E. Budget-aware recommendations | ✅ Hoàn tất | `/api/Nutrition/recommendations/...` |

### API đã có

```
# VietnamNutritionController
GET    /api/Nutrition/local-preferences
POST   /api/Nutrition/local-preferences
PUT    /api/Nutrition/local-preferences

GET    /api/Nutrition/discovery/local
GET    /api/Nutrition/discovery/local/by-region/{region}
GET    /api/Nutrition/discovery/local/by-budget

GET    /api/Nutrition/meal-log/vn/suggestions
POST   /api/Nutrition/meal-log/vn
POST   /api/Nutrition/meal-log/vn/quick-add
GET    /api/Nutrition/meal-log/vn/history

GET    /api/Nutrition/recommendations/budget-aware
GET    /api/Nutrition/recommendations/local-friendly
POST   /api/Nutrition/recommendations/feedback

# PortionConverterController
GET    /api/PortionConverter/units
GET    /api/PortionConverter/units/food/{foodId}
POST   /api/PortionConverter/convert
GET    /api/PortionConverter/custom-units
POST   /api/PortionConverter/custom-units
PUT    /api/PortionConverter/custom-units/{id}
DELETE /api/PortionConverter/custom-units/{id}
```

### Kết luận

**Vietnam-first Local Nutrition API: ✅ HOÀN CHỈNH**

---

## 2.12 Beginner quick-start workflow (Hôm nay ăn gì?)

**File Controller:** `backend/MenuGreen.API/Controllers/DailyStarterController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Quick-start suggestion | ✅ Hoàn tất | `GET /api/DailyStarter/today` và `GET /api/DailyStarter/recommendations` |
| B. One-tap refresh / Food capture | ✅ Hoàn tất | `GET /api/DailyStarter/featured-meals` và `POST /api/DailyStarter/start-log` |
| C. Create meal plan from quick-start | ✅ Hoàn tất | `POST /api/DailyStarter/select-meal` (uỷ thác cho `IMealPlanService`) |
| D. Quick personalization | ✅ Hoàn tất | `GET/PUT /api/DailyStarter/personalization` |

### API đã có

```
# DailyStarterController
GET    /api/DailyStarter/today
GET    /api/DailyStarter/recommendations
GET    /api/DailyStarter/featured-meals
POST   /api/DailyStarter/select-meal
POST   /api/DailyStarter/start-log
GET    /api/DailyStarter/personalization
PUT    /api/DailyStarter/personalization
```

### Kết luận

**Beginner quick-start workflow (Hôm nay ăn gì?) API: ✅ HOÀN CHỈNH (Trùng lặp logic được refactor triệt để về các service gốc)**

## 2.13 Gym/PT goal-based workflow

**File Controller:** `backend/MenuGreen.API/Controllers/GymGoalsController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Goal mode / recommendation | ✅ Hoàn tất | `GET /api/GymGoals/me` và `POST/PUT /api/GymGoals` |
| B. Tracking planned vs actual | ✅ Hoàn tất | `GET /api/GymGoals/alerts` và `GET /api/GymGoals/plan` |
| C. Smart Recalibration | ✅ Hoàn tất | `POST /api/GymGoals/recalibrate` (tự động điều chỉnh calo theo cân nặng) |
| D. Advanced PT/Coach report | ✅ Hoàn tất | `GET /api/GymGoals/coach-report` |

### API đã có

```
# GymGoalsController
GET    /api/GymGoals/me
POST   /api/GymGoals
PUT    /api/GymGoals
GET    /api/GymGoals/plan
POST   /api/GymGoals/recalibrate
GET    /api/GymGoals/alerts
GET    /api/GymGoals/coach-report
```

### Kết luận

**Gym/PT goal-based workflow API: ✅ HOÀN CHỈNH (Tích hợp logic tự động đổi calo theo ngày tập/ngày nghỉ, áp dụng guardrail và tự động recalibrate calo theo tuần)**

---

## 2.14 Real-world food data capture

**File Controller:** `backend/MenuGreen.API/Controllers/FoodCaptureController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Quick template | ✅ Hoàn tất | `POST /api/Nutrition/food-capture/quick-template` |
| B. Template from plan | ✅ Hoàn tất | `GET /api/Nutrition/food-capture/template-from-plan` |
| C. Fallback estimate manual entry | ✅ Hoàn tất | `POST /api/Nutrition/food-capture/fallback-estimate` |
| D. Save as quick-add | ✅ Hoàn tất | `POST /api/Nutrition/food-capture/save-as-quick-add` |

### API đã có

```
# FoodCaptureController
POST   /api/Nutrition/food-capture/quick-template
GET    /api/Nutrition/food-capture/template-from-plan
POST   /api/Nutrition/food-capture/fallback-estimate
POST   /api/Nutrition/food-capture/save-as-quick-add
```

### Kết luận

**Real-world Food Data Capture API: ✅ HOÀN CHỈNH**

---

## 2.15 Safety, trust, and compliance

**File Controller:** `backend/MenuGreen.API/Controllers/SafetyController.cs`

### Trạng thái hiện tại

| Nhóm API | Trạng thái | Ghi chú |
|----------|:----------:|---------|
| A. Disclaimer | ✅ Hoàn tất | `GET /api/Safety/disclaimer` |
| B. Consent management | ✅ Hoàn tất | `GET /api/Safety/consent` và `PUT /api/Safety/consent` (Lưu trữ thực tế trong AI Profile preferences) |
| C. Cảnh báo y khoa tự động | ✅ Hoàn tất | `GET /api/Safety/alerts` (Tính toán BMI y khoa và quét chất dị ứng) |
| D. Export data | ✅ Hoàn tất | `POST /api/Safety/export-data` (Đóng gói Profile, Health Profile, AI preferences và Dị ứng) |
| E. Delete data / account | ✅ Hoàn tất | `DELETE /api/Safety/delete-data` (Vô hiệu hóa IsActive = false) |
| F. Report issue / support | ✅ Hoàn tất | `POST /api/Safety/report-issue` (Ghi nhận trực tiếp sự cố vào Activity Logs) |

### API đã có

```
# SafetyController
GET    /api/Safety/disclaimer
GET    /api/Safety/consent
PUT    /api/Safety/consent
GET    /api/Safety/alerts
POST   /api/Safety/export-data
DELETE /api/Safety/delete-data
POST   /api/Safety/report-issue
```

### Kết luận

**Safety, trust, and compliance API: ✅ HOÀN CHỈNH (Tích hợp thực tế vào Database/Services, loại bỏ hoàn toàn mã mock)**

---

## Tổng kết

| Workflow | API Status | UI Status | Ưu tiên |
|----------|:----------:|:---------:|---------|
| **2.5 Meal Plan** | ✅ Hoàn chỉnh | ✅ **Hoàn thành** | ✅ **DONE** |
| 2.6 Recommendation | ✅ Hoàn chỉnh | 🟡 Một phần | **P2** |
| 2.7 AI Assistant | ✅ Hoàn chỉnh | 🟡 Placeholder | **P3** |
| **2.8 Subscription & Payment** | ✅ Hoàn chỉnh | ✅ **Hoàn thành** | ✅ **DONE** |
| 2.9 Notification | ✅ Hoàn chỉnh | ❌ Chưa có | **P2** |
| 2.10 Analytics | ✅ Hoàn chỉnh | ❌ Chưa có | **P3** |
| **2.11 Vietnam-first Local Nutrition** | ✅ Hoàn chỉnh | ❌ Chưa có | **P3** |
| **2.12 Beginner quick-start workflow** | ✅ Hoàn chỉnh | ❌ Chưa có | **P3** |
| **2.13 Gym/PT goal-based workflow** | ✅ Hoàn chỉnh | ❌ Chưa có | **P3** |
| **2.14 Real-world Food Data Capture** | ✅ Hoàn chỉnh | ❌ Chưa có | **P3** |
| **2.15 Safety, trust, and compliance** | ✅ Hoàn chỉnh | ❌ Chưa có | **P3** |

### Thứ tự ưu tiên triển khai

1. ~~**P1 - Meal Plan:**~~ ✅ **HOÀN THÀNH**
2. ~~**P2 - Recommendation UI:**~~ ✅ **HOÀN THÀNH**
3. ~~**P2 - Subscription & Payment:**~~ ✅ **HOÀN THÀNH**
4. **P3 - Notification UI:** Triển khai settings/inbox screens.
5. **P3 - AI Assistant UI:** Kết nối chat interface với các API.
6. **P3 - Analytics Admin UI:** Build admin dashboard.

---

## Related Documents

- [README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md](./README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md)
- [README_USER_WORKFLOW.md](./README_USER_WORKFLOW.md)
- [README_SEPAY_PAYMENT_WORKFLOW.md](./README_SEPAY_PAYMENT_WORKFLOW.md)
