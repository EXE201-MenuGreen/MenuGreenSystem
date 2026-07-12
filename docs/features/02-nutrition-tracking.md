# 02. Nutrition Tracking

**Status:** API Done · UI Done (Core 100%)
**Last updated:** 2026-07-09

**Related controller:** `backend/MenuGreen.API/Controllers/NutritionTrackingController.cs`

**Related Flutter feature:** `frontend/lib/features/tracking/`

---

## 1. Overview

Nhóm tính năng **cốt lõi** của MenuGreen — ghi nhật ký ăn uống và theo dõi dinh dưỡng hàng ngày:

- **Meal logging** — ghi bữa ăn (food hoặc recipe) với khối lượng thực tế.
- **Weight tracking** — ghi cân nặng theo thời gian, vẽ biểu đồ xu hướng.
- **Dashboard** — calo/macro hôm nay/tuần/tháng, biểu đồ calo, heatmap % mục tiêu.
- **Cảnh báo dinh dưỡng** — calorie drift ±8%, macro drift ±15% (warning messages từ backend).
- **Vietnam meal log** — ghi nhật ký meal theo ngân sách/đơn vị Việt Nam (chén, bát, muỗng).

---

## 2. Business Rules

### 2.1 Meal Log

- **Food log:** `quantityG` là gram thực tế của food.
- **Recipe log:** `quantityG / 100 = số khẩu phần` (100g = 1 serving).
- Mỗi meal log gắn với `MealType` ∈ {`Breakfast`, `Lunch`, `Dinner`, `Snack`} và `LogDate`.
- Sau khi ghi/sửa/xóa meal log, dashboard và history phải refresh (qua `MainScreen.onTrackingUpdated`).
- Goal completion % = `totalCalories / targetCalories × 100` (có thể vượt 100%).
- Cảnh báo: calorie drift >8% (ngưỡng thực tế tại `GoalDriftService.cs:98`) hoặc macro drift >15% so với target → backend trả `WarningMessages` (tiếng Anh); UI dịch qua `ApiMessageTranslator`.

### 2.2 Weight Log

- Cân nặng ghi nhận theo ngày; cho phép nhiều bản ghi/ngày (lấy bản mới nhất).
- Biểu đồ xu hướng hiển thị song song với calorie trend trong tab Lịch sử.

### 2.3 Dashboard

- Range: `day` / `week` / `month` qua `range` param, hỗ trợ `startDate` / `endDate` tuỳ chỉnh.
- Heatmap: 1 ô/ngày, màu theo % mục tiêu (đỏ <80%, vàng 80-110%, xanh >110%).

### 2.4 Vietnam Meal Log (Nutrition/meal-log/vn)

- `POST /api/Nutrition/meal-log/vn` — ghi meal log với portion converter (chén, bát, ...).
- `POST /api/Nutrition/meal-log/vn/quick-add` — quick-add từ template có sẵn.
- `GET /api/Nutrition/meal-log/vn/suggestions` — gợi ý món local phù hợp.
- `GET /api/Nutrition/meal-log/vn/history` — lịch sử meal log VN.

### 2.5 Cảnh báo (WarningMessages)

- API response kèm `WarningMessages: string[]` (tiếng Anh) và `HasWarning: bool`.
- UI dịch qua `NutritionWarningMessages` + `ApiMessageTranslator` trước khi hiển thị tiếng Việt.

---

## 3. API Endpoints

### 3.1 Meal Log

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/NutritionTracking/meal-logs?page=&pageSize=` | Danh sách meal log (paginated) |
| `GET` | `/api/NutritionTracking/meal-logs/{id}` | Chi tiết meal log |
| `GET` | `/api/NutritionTracking/meal-logs/range?startDate=&endDate=` | Meal logs theo khoảng ngày |
| `POST` | `/api/NutritionTracking/meal-logs` | Tạo meal log (food hoặc recipe) |
| `PUT` | `/api/NutritionTracking/meal-logs/{id}` | Sửa meal log |
| `DELETE` | `/api/NutritionTracking/meal-logs/{id}` | Xóa meal log |
| `POST` | `/api/NutritionTracking/meal-logs/{mealLogId}/substitute-ingredient` | Thay thế nguyên liệu trong log |

### 3.2 Weight Log

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/NutritionTracking/weight-logs?page=&pageSize=` | Danh sách weight log (paginated) |
| `GET` | `/api/NutritionTracking/weight-logs/{id}` | Chi tiết weight log |
| `GET` | `/api/NutritionTracking/weight-logs/trend?startDate=&endDate=` | Weight trend cho biểu đồ |
| `POST` | `/api/NutritionTracking/weight-logs` | Tạo weight log |
| `PUT` | `/api/NutritionTracking/weight-logs/{id}` | Sửa weight log |
| `DELETE` | `/api/NutritionTracking/weight-logs/{id}` | Xóa weight log |

### 3.3 Summary & Dashboard

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/NutritionTracking/summary?period=day\|week\|month&date=` | Tổng quan calo/macro theo period |
| `GET` | `/api/NutritionTracking/trends?startDate=&endDate=` | Nutrition trends (cho chart nhiều ngày) |
| `GET` | `/api/NutritionTracking/daily?date=` | Daily summary chi tiết |
| `GET` | `/api/NutritionTracking/dashboard?range=day\|week\|month&startDate=&endDate=` | Dashboard tổng hợp |

### 3.4 User Dashboard (`UserDashboardController`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Dashboard/user-summary` | Streak + totalDaysTracked + totalMealLogsCount |
| `GET` | `/api/Dashboard/nutrition-trend` | Nutrition trend tổng hợp cho Dashboard tab |
| `GET` | `/api/Dashboard/weight-trend` | Weight trend cho Dashboard tab |
| `GET` | `/api/Dashboard/recommendation-summary` | Tóm tắt recommendation gần đây |

### 3.5 Vietnam Nutrition (`VietnamNutritionController`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Nutrition/local-preferences` | Lấy VN preferences (region, budget, ...) |
| `POST` | `/api/Nutrition/local-preferences` | Tạo preferences |
| `PUT` | `/api/Nutrition/local-preferences` | Cập nhật preferences |
| `GET` | `/api/Nutrition/discovery/local` | Discovery VN foods |
| `GET` | `/api/Nutrition/discovery/local/by-region/{region}` | Theo vùng miền |
| `GET` | `/api/Nutrition/discovery/local/by-budget` | Theo ngân sách |
| `GET` | `/api/Nutrition/meal-log/vn/suggestions` | Gợi ý món local |
| `POST` | `/api/Nutrition/meal-log/vn` | Ghi meal log VN |
| `POST` | `/api/Nutrition/meal-log/vn/quick-add` | Quick-add từ template |
| `GET` | `/api/Nutrition/meal-log/vn/history` | Lịch sử meal log VN |
| `GET` | `/api/Nutrition/recommendations/budget-aware` | Recommendations theo ngân sách *(cùng handler với local-friendly — 1 endpoint thực tế)* |
| `GET` | `/api/Nutrition/recommendations/local-friendly` | Recommendations món VN *(cùng handler với budget-aware — 1 endpoint thực tế)* |
| `POST` | `/api/Nutrition/recommendations/feedback` | Feedback (alias cho `/api/Recommendation/feedback`) |

**Tổng: 33 endpoint** (16 NutritionTracking + 4 UserDashboard + 13 Vietnam Nutrition). EP `substitute-ingredient` thuộc `IngredientSubstitutionController` (xem [`04-discover-and-allergy.md` §3.5](./04-discover-and-allergy.md#35-ingredient-substitution-ingredientsubstitutioncontroller)). Lưu ý: `/api/Nutrition/recommendations/feedback` là alias cho `/api/Recommendation/feedback` (xem [`05-recommendation-engine.md` §3.2](./05-recommendation-engine.md#32-history--feedback)).

---

## 4. UI Components

| Component | File | Status |
|-----------|------|--------|
| NutritionTrackingRepository | `features/tracking/repositories/nutrition_tracking_repository.dart` | Done |
| MealLogSheet (Thêm bữa ăn) | `features/tracking/widgets/meal_log_sheet.dart` | Done |
| MealLogEditSheet | `features/tracking/widgets/meal_log_edit_sheet.dart` | Done |
| WeightLogSheet | `features/tracking/widgets/weight_log_sheet.dart` | Done |
| DailySummaryCard | `features/tracking/widgets/daily_summary_card.dart` | Done |
| CalorieTrendChart | `features/tracking/widgets/calorie_trend_chart.dart` | Done |
| WeightTrendChart | `features/tracking/widgets/weight_trend_chart.dart` | Done |
| CalendarHeatmapLegend | `features/tracking/widgets/calendar_heatmap_legend.dart` | Done |
| DashboardRangeSelector | `features/tracking/widgets/dashboard_range_selector.dart` | Done |
| SearchAndLogModal | `features/tracking/widgets/search_and_log_modal.dart` | Done |
| IngredientScanScreen (CV) | `features/tracking/views/ingredient_scan_screen.dart` | Done |
| ScanResultSheet (CV) | `features/tracking/widgets/scan_result_sheet.dart` | Done |
| SuggestedDishCard (CV) | `features/tracking/widgets/suggested_dish_card.dart` | Done |
| NutritionWarningUtils | `features/tracking/utils/nutrition_warning_utils.dart` | Done |

Models: `meal_log_item.dart`, `weight_log_item.dart`, `nutrition_dashboard.dart`, `meal_day_summary.dart`, `nutrition_models.dart`, `cv_inference_response.dart`, `cv_suggested_dish.dart`, `cv_nutrition_info.dart`, `cv_recipe_ingredient.dart`, `cv_ingredient_item.dart`, `catalog_item.dart`.

---

## 5. Navigation Flow

```
MainScreen
├── Tab Home
│   ├── DailySummaryCard (calories/macro hôm nay)
│   ├── Danh sách meal hôm nay
│   └── Nút "Thêm bữa ăn" → MealLogSheet
│                                 ├── SearchAndLogModal
│                                 ├── IngredientScanScreen (CV)
│                                 └── ScanResultSheet → log meal
│
└── Tab Lịch sử (History)
    ├── DashboardRangeSelector (day/week/month)
    ├── DailySummaryCard
    ├── CalorieTrendChart
    ├── WeightTrendChart
    ├── CalendarHeatmapLegend
    ├── Nhật ký meal hôm nay
    │       └── Tap row → MealLogEditSheet
    └── Nhật ký cân nặng
            └── Tap → WeightLogSheet
```

---

## 6. Data Models (rút gọn)

```
MealLog
├── Id, UserId, MealType (Breakfast/Lunch/Dinner/Snack)
├── LogDate, FoodId? (nullable), RecipeId? (nullable)
├── GramsConsumed, CaloriesKcal, ProteinG, CarbsG, FatG, FiberG
└── Notes?

WeightLog
├── Id, UserId, RecordedAt, WeightKg
└── Notes?

NutritionSnapshot (daily aggregate)
├── UserId, Date
├── TotalCalories, TotalProtein, TotalCarbs, TotalFat
├── GoalCompletionPercent
└── WarningMessages[]

Dashboard (range aggregate)
├── RangeType, StartDate, EndDate
├── AvgCalories, AvgProtein, AvgCarbs, AvgFat
├── WeightTrend[]
├── MealLogs[]
├── CalorieHistory[] (chart data)
└── Heatmap[] (calendar cells)
```

Backend models đầy đủ: [`../02-backend/backend_models_documentation.md`](../02-backend/backend_models_documentation.md) (mục 1.4 Meal Tracking).

---

## 7. Related Documents

- Health Profile (target calories): [`01-auth-and-account.md`](./01-auth-and-account.md)
- Recipe/Food discovery (chọn món để log): [`04-discover-and-allergy.md`](./04-discover-and-allergy.md)
- Streak / Goal Completion: [`10-vietnam-local-features.md` → Appendix A](./10-vietnam-local-features.md#appendix-a-nutrition-calculation-formulas)
- Goal drift alerts / recalibration: [`09-analytics.md`](./09-analytics.md)
- Meal plan → convert-to-log: [`03-meal-plan.md`](./03-meal-plan.md)
- User workflow cũ (mục 4.9, 4.10): [`../_archive/root-readmes/README_USER_WORKFLOW.md`](../_archive/root-readmes/README_USER_WORKFLOW.md)