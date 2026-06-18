# README: WORKFLOW API STATUS

**Cập nhật:** 2026-06-17

Tài liệu này ghi nhận chi tiết trạng thái API và UI của từng workflow, so sánh **API cần có** (theo thiết kế) với **API đã có** (trong codebase) và liệt kê **API còn thiếu** cần triển khai thêm.

---

## Mục lục

1. [2.5 Meal Plan](#25-meal-plan) - ✅ HOÀN THÀNH
2. [2.6 Recommendation](#26-recommendation) - ✅ HOÀN THÀNH
3. [2.7 AI Assistant](#27-ai-assistant)
4. [2.9 Notification](#29-notification)
5. [2.10 Analytics](#210-analytics)

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

## Tổng kết

| Workflow | API Status | UI Status | Ưu tiên |
|----------|:----------:|:---------:|---------|
| **2.5 Meal Plan** | ✅ Hoàn chỉnh | ✅ **Hoàn thành** | ✅ **DONE** |
| 2.6 Recommendation | ✅ Hoàn chỉnh | 🟡 Một phần | **P2** |
| 2.7 AI Assistant | ✅ Hoàn chỉnh | 🟡 Placeholder | **P3** |
| 2.9 Notification | ✅ Hoàn chỉnh | ❌ Chưa có | **P2** |
| 2.10 Analytics | ✅ Hoàn chỉnh | ❌ Chưa có | **P3** |

### Thứ tự ưu tiên triển khai

1. ~~**P1 - Meal Plan:**~~ ✅ **HOÀN THÀNH**
2. ~~**P2 - Recommendation UI:**~~ ✅ **HOÀN THÀNH**
3. **P3 - Notification UI:** Triển khai settings/inbox screens.
4. **P3 - AI Assistant UI:** Kết nối chat interface với các API.
5. **P3 - Analytics Admin UI:** Build admin dashboard.

---

## Related Documents

- [README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md](./README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md)
- [README_USER_WORKFLOW.md](./README_USER_WORKFLOW.md)
- [README_SEPAY_PAYMENT_WORKFLOW.md](./README_SEPAY_PAYMENT_WORKFLOW.md)
