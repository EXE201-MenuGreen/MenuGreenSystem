# Meal Plan Workflow

**Status:** ✅ Complete (API + Flutter UI)

---

## Overview

Meal Plan giúp user lên kế hoạch ăn uống theo ngày/tuần:
- Tạo meal plan với món ăn/công thức
- Đặt lịch nhắc bữa ăn
- Convert plan sang log
- Theo dõi streaks

---

## API Endpoints

### Plan CRUD

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/MealPlan` | Danh sách plans (lọc isActive) |
| `GET` | `/api/MealPlan/{id}` | Chi tiết plan |
| `POST` | `/api/MealPlan` | Tạo plan mới |
| `PUT` | `/api/MealPlan/{id}` | Cập nhật plan |
| `DELETE` | `/api/MealPlan/{id}` | Xóa plan |
| `PATCH` | `/api/MealPlan/{id}/status` | Cập nhật status |

### Plan Items

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/MealPlan/{planId}/items` | Thêm item |
| `PUT` | `/api/MealPlan/{planId}/items/{itemId}` | Cập nhật item |
| `DELETE` | `/api/MealPlan/{planId}/items/{itemId}` | Xóa item |
| `PATCH` | `/api/MealPlan/{planId}/items/{itemId}/status` | Cập nhật status item |

### Quick Actions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/MealPlan/{planId}/items/{itemId}/convert-to-log` | Convert sang meal log |
| `POST` | `/api/MealPlan/{planId}/commit` | Commit entire plan |
| `POST` | `/api/MealPlan/{planId}/duplicate` | Duplicate plan |

### Dashboard & Stats

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/MealPlan/dashboard?date=` | Dashboard ngày |
| `GET` | `/api/MealPlan/compare?from=&to=` | So sánh planned vs actual |
| `GET` | `/api/MealPlan/streaks` | Streaks |

### Reminders (Notification)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Notification/meal-plan-remind` | Nhắc meal plan |
| `GET` | `/api/Notification/settings` | Lấy settings |
| `PUT` | `/api/Notification/settings` | Cập nhật settings |

---

## Flutter Components

| Component | File | Status |
|-----------|------|--------|
| Models | `meal_plan_models.dart` | ✅ |
| Requests | `meal_plan_requests.dart` | ✅ |
| Provider | `meal_plan_provider.dart` | ✅ |
| Repository | `meal_plan_repository.dart` | ✅ |
| MealPlanScreen | `meal_plan_screen.dart` | ✅ |
| MealPlanDetailScreen | `meal_plan_detail_screen.dart` | ✅ |
| CreateMealPlanScreen | `create_meal_plan_screen.dart` | ✅ |
| MealPlanStatsScreen | `meal_plan_stats_screen.dart` | ✅ |
| MealPlanCalendarScreen | `meal_plan_calendar_screen.dart` | ✅ |
| CalorieProgressRing | `calorie_progress_ring.dart` | ✅ |
| MealItemTile | `meal_item_tile.dart` | ✅ |
| AddItemSheet | `add_item_sheet.dart` | ✅ |
| EditItemSheet | `edit_item_sheet.dart` | ✅ |

---

## Navigation Flow

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

---

## Calorie Distribution

| Bữa ăn | Tỷ lệ | Ví dụ (2000 kcal) |
|---------|--------|-------------------|
| Breakfast | 25% | 500 kcal |
| Lunch | 35% | 700 kcal |
| Dinner | 30% | 600 kcal |
| Snack | 10% | 200 kcal |

---

## Streak Logic

- Streak tăng khi user log ít nhất 1 bữa/ngày
- Streak reset nếu bỏ log 2 ngày liên tiếp
- Công thức: đếm ngày log liên tiếp, bắt đầu từ hôm nay/hôm qua

---

## Related Documents

- [User Workflow - Meal Plan](../README_USER_WORKFLOW.md)
- [Workflow API Status](../README_WORKFLOW_API_STATUS.md)

---

*Last updated: 2026-07-05*
