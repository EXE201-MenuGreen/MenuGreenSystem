# 10. Vietnam Local Features

**Status:** API Done · UI Partial
**Last updated:** 2026-07-09

**Related controllers:**
- `backend/MenuGreen.API/Controllers/VietnamNutritionController.cs`
- `backend/MenuGreen.API/Controllers/PortionConverterController.cs` (xem [`04-discover-and-allergy.md`](./04-discover-and-allergy.md))
- `backend/MenuGreen.API/Controllers/DailyStarterController.cs`
- `backend/MenuGreen.API/Controllers/GymGoalsController.cs`
- `backend/MenuGreen.API/Controllers/FoodCaptureController.cs`
- `backend/MenuGreen.API/Controllers/SafetyController.cs`
- `backend/MenuGreen.API/Controllers/AllergyController.cs` (Allergy Badge)

**Related Flutter feature:** Đa phần backend-only hoặc tích hợp trong các feature khác (Discover, Tracking, Meal Plan, AI).

---

## 1. Overview

Nhóm tính năng **Vietnam-first** và các workflow đặc thù cho người dùng Việt Nam:

| Workflow | Mô tả | Trạng thái UI |
|----------|-------|---------------|
| 2.11 Vietnam-first Local Nutrition | Local preferences, discovery local, portion, meal log VN | Partial |
| 2.12 Beginner Quick-Start ("Hôm nay ăn gì?") | Gợi ý 1-tap cho user mới | Chưa có |
| 2.13 Gym/PT Goal-Based Workflow | Calo tự đổi theo ngày tập/ngày nghỉ, recalibrate | Chưa có |
| 2.14 Real-world Food Data Capture | Quick template, fallback estimate | Chưa có |
| 2.15 Safety, Trust, Compliance | Disclaimer, consent, BMI y tế, export data, delete | Chưa có |
| 2.16 Allergy Risk Badge | Badge UI cho meal (xem [`04-discover-and-allergy.md`](./04-discover-and-allergy.md)) | Done |

> **Ghi chú:** Phần lớn workflows này là **backend infrastructure** phục vụ các tính năng user-facing khác. UI riêng chưa ưu tiên (P3), chỉ Allergy Risk Badge đã có UI.

---

## 2. Business Rules chung

- Tất cả workflow thiết kế **Vietnam-first**: đơn vị đo (chén, bát, muỗng, trái), ngân sách VND, region (Bắc/Trung/Nam), meal pattern Việt.
- Refactor triệt để về các service gốc (không duplicate logic).
- Tích hợp thực tế vào Database/Services (không mock).
- Ghi audit log cho mọi action quan trọng (compliance).

---

## 3. Workflows & API Endpoints

### 3.1 2.11 Vietnam-first Local Nutrition (VietnamNutritionController + PortionConverter)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Nutrition/local-preferences` | Lấy local preferences (region, dietary style) |
| `POST` | `/api/Nutrition/local-preferences` | Tạo preferences |
| `PUT` | `/api/Nutrition/local-preferences` | Cập nhật preferences |
| `GET` | `/api/Nutrition/discovery/local` | Discovery local foods |
| `GET` | `/api/Nutrition/discovery/local/by-region/{region}` | Theo vùng miền |
| `GET` | `/api/Nutrition/discovery/local/by-budget` | Theo ngân sách |
| `GET` | `/api/Nutrition/meal-log/vn/suggestions` | Gợi ý món VN |
| `POST` | `/api/Nutrition/meal-log/vn` | Ghi meal log VN |
| `POST` | `/api/Nutrition/meal-log/vn/quick-add` | Quick-add từ template |
| `GET` | `/api/Nutrition/meal-log/vn/history` | Lịch sử meal log VN |
| `GET` | `/api/Nutrition/recommendations/budget-aware` | Gợi ý theo ngân sách |
| `GET` | `/api/Nutrition/recommendations/local-friendly` | Gợi ý món dễ ăn VN |
| `POST` | `/api/Nutrition/recommendations/feedback` | Feedback cho local rec |

**Portion Converter endpoints:** xem [`04-discover-and-allergy.md` § 3.3](./04-discover-and-allergy.md#33-portion-converter).

### 3.2 2.12 Beginner Quick-Start "Hôm nay ăn gì?" (DailyStarterController)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/DailyStarter/today` | Gợi ý hôm nay (1-tap) |
| `GET` | `/api/DailyStarter/featured-meals` | Featured meals |
| `POST` | `/api/DailyStarter/select-meal` | User chọn món (uỷ thác MealPlanService) |
| `POST` | `/api/DailyStarter/start-log` | Bắt đầu log nhanh |
| `GET` | `/api/DailyStarter/recommendations` | Gợi ý chi tiết |
| `GET` | `/api/DailyStarter/personalization` | Lấy personalization |
| `PUT` | `/api/DailyStarter/personalization` | Cập nhật personalization |
| `POST` | `/api/DailyStarter/save-preference` | Lưu preference lựa chọn của user |

**Tổng DailyStarter: 8 endpoint.**

**Workflow:** user mới mở app → Home → "Hôm nay ăn gì?" → chọn món → ghi log nhanh.

### 3.3 2.13 Gym/PT Goal-Based Workflow (GymGoalsController)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/GymGoals/me` | Lấy goal mode hiện tại |
| `POST` | `/api/GymGoals` | Tạo gym goal |
| `PUT` | `/api/GymGoals` | Cập nhật gym goal |
| `GET` | `/api/GymGoals/plan` | Plan cho gym/PT user |
| `POST` | `/api/GymGoals/recalibrate` | Tự động đổi calo theo cân nặng |
| `GET` | `/api/GymGoals/alerts` | Alerts (ngày tập/ngày nghỉ) |
| `GET` | `/api/GymGoals/coach-report` | Báo cáo cho PT/coach |

**Workflow:** Tự động đổi calo theo ngày tập (TDEE + training bonus) vs ngày nghỉ (TDEE base); recalibrate theo tuần; guardrail an toàn (min 1200 kcal).

### 3.4 2.14 Real-world Food Data Capture (FoodCaptureController)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Nutrition/food-capture/quick-template` | Tạo quick template |
| `GET` | `/api/Nutrition/food-capture/template-from-plan` | Template từ meal plan |
| `POST` | `/api/Nutrition/food-capture/fallback-estimate` | Fallback estimate (không rõ calo) |
| `POST` | `/api/Nutrition/food-capture/save-as-quick-add` | Lưu thành quick-add |

**Workflow:** user ăn ngoài không rõ calo → dùng fallback estimate để ghi log gần đúng.

### 3.5 2.15 Safety, Trust, Compliance (SafetyController)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Safety/disclaimer` | Lấy disclaimer y tế |
| `GET` | `/api/Safety/consent` | Lấy trạng thái consent |
| `PUT` | `/api/Safety/consent` | Cập nhật consent |
| `GET` | `/api/Safety/alerts` | Cảnh báo y khoa (BMI, allergens) |
| `POST` | `/api/Safety/export-data` | Export toàn bộ data user |
| `DELETE` | `/api/Safety/delete-data` | Xóa data (soft delete IsActive=false) |
| `POST` | `/api/Safety/report-issue` | Báo cáo sự cố (ghi vào ActivityLog) |

**Compliance:** Tích hợp vào `UserAiProfile.Preferences` cho consent; soft-delete để có thể recover.

### 3.6 2.16 Allergy Risk Badge + CRUD (AllergyController)

Full API AllergyController (xem chi tiết tại [`04-discover-and-allergy.md`](./04-discover-and-allergy.md#32-allergy)).

|| Method | Endpoint | Description |
||--------|----------|-------------|
|| `GET` | `/api/Allergy` | Lấy allergy profile user |
|| `POST` | `/api/Allergy` | Thêm dị ứng |
|| `PUT` | `/api/Allergy/{allergyId}` | Sửa dị ứng |
|| `DELETE` | `/api/Allergy/{allergyId}` | Xóa dị ứng |
|| `PUT` | `/api/Allergy/profile` | Cập nhật profile allergy (bulk) |
|| `GET` | `/api/Allergy/catalog` | Master danh sách allergies |
|| `POST` | `/api/Allergy/evaluate` | Đánh giá risk cho 1 meal |
|| `POST` | `/api/Allergy/evaluate/batch` | Batch evaluate |
|| `GET` | `/api/Allergy/meal/{mealId}/badge` | Badge cho UI |
|| `GET` | `/api/Allergy/recommendations` | Gợi ý món phù hợp allergy profile |

**Tổng AllergyController: 11 endpoint** (đã bao gồm trong [`04-discover-and-allergy.md`](./04-discover-and-allergy.md#32-allergy)).

### 3.7 2.17 Planned vs Actual Insights — PlannedVsActualController (RIÊNG BIỆT)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Analytics/planned-vs-actual` | So sánh tổng |
| `GET` | `/api/Analytics/planned-vs-actual/adherence-score` | Điểm bám sát (0-100) |
| `GET` | `/api/Analytics/planned-vs-actual/drift-analysis` | Phân tích lệch |
| `GET` | `/api/Analytics/planned-vs-actual/recommendations` | Gợi ý khắc phục |
| `GET` | `/api/Analytics/planned-vs-actual/monthly-report` | Báo cáo tháng |
| `POST` | `/api/Analytics/planned-vs-actual/recalibrate` | Recalibrate calo/macro |

**Formulas chi tiết:** xem Appendix A.8 & A.9 dưới đây.

### 3.8 2.18 Ingredient Substitution Preference (`IngredientSubstitutionController`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Ingredient/preferences/substitutes` | Lấy preference thay thế của user |
| `POST` | `/api/Ingredient/preferences/substitutes` | Lưu preference thay thế |
| `DELETE` | `/api/Ingredient/preferences/substitutes/{id}` | Xóa preference thay thế |

**Workflow:** User ăn món có nguyên liệu không thích → bật bảng substitution → lưu preference để dùng lại. Backend ưu tiên thay thế theo preference, sau đó mới theo nutrition score. Các EP thay thế nguyên liệu theo ngữ cảnh (trong recipe/mealPlan/mealLog/safe-alternatives) xem [`04-discover-and-allergy.md` §3.5](./04-discover-and-allergy.md#35-ingredient-substitution-ingredientsubstitutioncontroller).

---

## 4. UI Components

| Component | File | Status |
|-----------|------|--------|
| AllergyRiskBadge | `features/discover/widgets/allergy_risk_badge.dart` | Done |

> **Trạng thái UI:**
> - **Allergy Risk Badge:** Done (xem [`04-discover-and-allergy.md`](./04-discover-and-allergy.md)).
> - **Vietnam Meal Log UI:** Partial (qua `MealLogSheet` trong [`02-nutrition-tracking.md`](./02-nutrition-tracking.md)).
> - **Daily Starter screen, Gym/PT screen, Safety screen, Food Capture UI:** Chưa có (P3).
> - **Planned vs Actual report UI:** Backend trả HTML monthly report; user app chưa có UI riêng.

---

## 5. Navigation Flow

Vietnam-local workflows phân tán theo ngữ cảnh:

```
Home (Tab)
├── "Hôm nay ăn gì?" → Daily Starter flow
│       └── GET /DailyStarter/today → list món → chọn → POST /select-meal
│       └── POST /start-log → MealLogSheet (xem 02-nutrition-tracking.md)
├── "Gym mode" badge → Gym Goals (nếu user là gym/PT)
│       └── GET /GymGoals/me → hiển thị alert/plan
│       └── POST /GymGoals/recalibrate (background)
└── "Ăn ngoài?" → Food Capture
        └── POST /food-capture/fallback-estimate → MealLogSheet

Profile
└── "Bảo mật & Tuân thủ"
        ├── DisclaimerScreen
        ├── ConsentScreen
        ├── ExportDataButton
        └── DeleteAccountButton
```

---

## 6. Data Models (rút gọn)

```
LocalPreferences
├── UserId, Region (North/Central/South)
├── DietaryStyle (Traditional/Vegetarian/...)
├── CookingPreference
└── SpiceLevel

DailyStarterRecommendation
├── Date, Meals[] (breakfast/lunch/dinner/snack)
├── Reasoning
└── PersonalizationScore

GymGoal
├── UserId, Mode (Bulk/Cut/Maintain/Performance)
├── TrainingDays[] (Mon/Wed/Fri)
├── RestingDays[]
├── TrainingDayCalorieBonus
└── RecalibrationHistory[]

SafetyConsent
├── UserId, DisclaimerAcceptedAt
├── DataProcessingConsent (bool)
├── MarketingConsent (bool)
└── LastUpdated

AllergenRiskBadge
├── MealId, RiskLevel (Low/Medium/High)
├── MatchedAllergens[]
├── WarningText (tiếng Anh)
└── BadgeColor
```

---

## 7. Related Documents

- Discover + Allergy + Portion: [`04-discover-and-allergy.md`](./04-discover-and-allergy.md)
- Tracking + Meal log VN: [`02-nutrition-tracking.md`](./02-nutrition-tracking.md)
- Meal Plan (Daily Starter select-meal uỷ thác): [`03-meal-plan.md`](./03-meal-plan.md)
- AI tạo local recommendations: [`06-ai-assistant-and-coach.md`](./06-ai-assistant-and-coach.md)
- Planned vs Actual Analytics: [`09-analytics.md`](./09-analytics.md)
- User workflow cũ: [`../_archive/root-readmes/README_USER_WORKFLOW.md`](../_archive/root-readmes/README_USER_WORKFLOW.md)
- API status cũ (mục 2.11-2.17): [`../_archive/root-readmes/README_WORKFLOW_API_STATUS.md`](../_archive/root-readmes/README_WORKFLOW_API_STATUS.md)

---

## Appendix A. Nutrition Calculation Formulas

Phần này di chuyển từ `NUTRITION_CALCULATIONS_README.md` (đã archive). 15 formulas được dùng trong toàn bộ hệ thống MenuGreen, có nguồn khoa học đính kèm.

### A.1 BMR — Mifflin-St Jeor Equation

**Nguồn:** [Mifflin et al. (1990)](https://pmc.ncbi.nlm.nih.gov/articles/PMC1375232/) · [Frankenfield et al. (2005)](https://pubmed.ncbi.nlm.nih.gov/15919902/) · [Medscape Calculator](https://reference.medscape.com/calculator/846/mifflin-st-jeor)

**File:** `HealthProfileMetricsCalculator.cs:45-49`

```
BMR (nam) = (10 × cân nặng kg) + (6.25 × chiều cao cm) − (5 × tuổi) + 5
BMR (nữ)  = (10 × cân nặng kg) + (6.25 × chiều cao cm) − (5 × tuổi) − 161
```

```csharp
var baseBmr = (10 * (double)weightKg) + (6.25 * (double)heightCm) - (5 * age);
var genderBonus = gender?.Trim().ToLower() is "male" or "nam" ? 5 : -161;
return baseBmr + genderBonus;
```

**Đánh giá:** CHÍNH XÁC (chuẩn Academy of Nutrition and Dietetics 2005).

**API kiểm tra:** `POST /api/HealthProfile/me/calculate` → trả `bmrKcal`.

### A.2 TDEE — Total Daily Energy Expenditure

**Nguồn:** [TDEEcal — Activity Multipliers](https://tdeecal.com/sources/)

**File:** `HealthProfileMetricsCalculator.cs:52-61`

```
TDEE = BMR × Activity Multiplier
```

| Activity Level | Multiplier |
|---|---|
| Sedentary | 1.2 |
| Lightly Active | 1.375 |
| Moderately Active | 1.55 |
| Very Active | 1.725 |

```csharp
public static double GetActivityMultiplier(string? activityLevel)
{
    return activityLevel?.Trim().ToLower() switch
    {
        "sedentary" => 1.2,
        "light" or "lightlyactive" or "lightly active" => 1.375,
        "moderate" or "moderatelyactive" or "moderately active" => 1.55,
        "active" or "veryactive" or "very active" => 1.725,
        _ => 1.2
    };
}
```

**Đánh giá:** CHÍNH XÁC.

### A.3 BMI — Body Mass Index

**Nguồn:** [WHO — BMI](https://www.who.int/news-room/fact-sheets/detail/a-healthy-lifestyle---body-mass-index-bmi)

```
BMI = cân nặng (kg) / chiều cao² (m²)
```

Phân loại: `<18.5` thiếu cân, `18.5-24.9` bình thường, `25-29.9` thừa cân, `≥30` béo phì.

**Đánh giá:** CHÍNH XÁC (chuẩn WHO từ 1995).

### A.4 Target Calories từ TDEE theo mục tiêu

**Nguồn:** [NHS — Calorie Counting](https://www.nhs.uk/better-health/lose-weight/calorie-counting/) · [Harvard — Calorie Deficit](https://www.health.harvard.edu/weight-loss/calorie-deficit-explained-is-it-a-safe-sustainable-approach-to-weight-loss)

| Mục tiêu | Điều chỉnh | Nguồn chuẩn |
|---|---|---|
| Lose Weight | -500 kcal | NHS/Harvard khuyến nghị deficit 500 kcal/ngày |
| Gain Weight | +300 kcal | An toàn cho tăng cân từ từ |
| Build Muscle | +200 kcal | ISSN: tùy mức độ vận động |
| Maintenance | 0 | Giữ nguyên |

**Minimum:** 1200 kcal (NHS safety floor).

**Đánh giá:** ĐÚNG về hướng, an toàn.

### A.5 Macro Targets (Protein / Carbs / Fat)

**Nguồn:** [IOM/NIH — AMDR](https://www.ncbi.nlm.nih.gov/books/NBK610333/) · [StatPearls](https://www.ncbi.nlm.nih.gov/books/NBK594226/)

| Mục tiêu | Protein | Carbs | Fat |
|---|---|---|---|
| Build Muscle | 35% | **45%** | **20%** |
| Các mục tiêu khác | 30% | 40% | 30% |

```
Protein (g) = (TargetCalories × Protein%) / 4
Carbs   (g) = (TargetCalories × Carbs%)   / 4
Fat     (g) = (TargetCalories × Fat%)     / 9
```

| Ngưỡng | Giá trị |
|---|---|
| Minimum protein theo cân nặng | 0.8 g/kg |
| Maximum protein theo cân nặng | 2.2 g/kg |
| Floor protein khi tính ra < min | nâng lên min (0.8 g/kg) |

**Công thức code thật** tại `HealthProfileMetricsCalculator.cs:82-107`:
- `proteinRatio = 0.35` nếu Build Muscle, ngược lại `0.30`
- `fatRatio = 0.20` nếu Build Muscle, ngược lại `0.30`
- `carbsRatio = 0.45` nếu Build Muscle, ngược lại `0.40`
- Sau khi tính `proteinG`, ép về khoảng `[weight × 0.8, weight × 2.2]` (IOM/kg-of-bodyweight).

**Đánh giá:** PHÙ HỢP — carbs Build Muscle 45% đã theo ISSN. Protein clamp theo cân nặng đảm bảo không thiếu đạm.

### A.6 Nutrition Snapshot & Goal Completion

```
GoalCompletionPercent = (TotalCalories thực tế / TargetCalories) × 100%
```

**Đánh giá:** CHÍNH XÁC (có thể vượt 100%).

**API kiểm tra:** `GET /api/NutritionTracking/summary?date=` → trả `goalCompletionPercent`.

### A.7 Goal Drift Detection

**Nguồn:** [Dietary Assessment Initiative (2026)](https://dietaryassessmentinitiative.org/publications/clinical-thresholds-self-monitoring-2026/) · [Nutrition Research Review (2024)](https://nutrition-research-review.com/articles/impact-tracking-accuracy-weight-management-2024/)

**File:** `GoalDriftService.cs:93-101`

```
Deviation% = (Giá trị trung bình 7 ngày - Target) / Target × 100%

Drift nếu:
  |Calorie Deviation| > 8%   →  Calorie Drift Alert
  |Macro Deviation|  > 15% →  Macro Drift Alert
```

**Ghi chú:** Ngưỡng Calorie thực tế trong code `GoalDriftService.cs:98` là **8%** (không phải 10%) — đã chọn 8% để cảnh báo sớm với user có nguy cơ metabolic cao; đồng bộ với Dietary Assessment Initiative 2026.

**Đánh giá:** HỢP LÝ — threshold thận trọng, sớm hơn 10% chuẩn chung.

### A.8 Planned vs Actual Nutrition

Phép SUM đơn giản:
```
TotalPlanned = SUM(plans trong khoảng from-to)
TotalActual  = SUM(meal logs trong khoảng from-to)
Difference   = TotalActual - TotalPlanned
```

**Đánh giá:** CHÍNH XÁC.

### A.9 Adherence Score (Điểm bám sát)

**File:** `PlannedVsActualService.cs:227-286`

```
MealCompletionRate    = (Số bữa hoàn thành / Tổng bữa kế hoạch) × 100
CalorieDeviationScore = max(0, 100 - |Actual - Planned| / Planned × 100)
MacroDeviationScore   = avg(ProteinScore, CarbsScore, FatScore)
UnplannedPenaltyScore = max(0, 100 - (Số bữa ngoài kế hoạch / Tổng bữa) × 100)

OverallScore = MealCompletion×0.4 + CalorieDev×0.3 + MacroDev×0.2 + Unplanned×0.1
```

| Rating | Threshold |
|---|---|
| EXCELLENT | ≥ 85 |
| GOOD | ≥ 70 |
| FAIR | ≥ 50 |
| POOR | < 50 |

**Đánh giá:** HỢP LÝ, proprietary formula. Cần A/B testing với data thực.

### A.10 Recalibration (Hiệu chỉnh mục tiêu)

**File:** `PlannedVsActualService.cs:547-690`

So sánh trung bình cân nặng tuần này vs tuần trước:

```
Lose weight: cân không giảm → giảm thêm 100 kcal (tối thiểu 1200)
Gain weight: cân không tăng → tăng thêm 150 kcal
Maintenance: thay đổi > 0.8kg/tuần → điều chỉnh ±100 kcal
```

**Đánh giá:** TỐT — conservative, an toàn, NHS-compliant.

### A.11 Meal Plan — Meal Plan Calorie Distribution

**Nguồn:** [HealthcareOnTime](https://www.healthcareontime.com/health-tips/how-many-calories-should-i-eat-for-breakfast-lunch-dinner-its-not-one-size-fits-all/) · [PMC 2024 Meta-Analysis](https://pmc.ncbi.nlm.nih.gov/articles/PMC11530941/)

**File:** `RecommendationService.cs:99-102`

| Bữa ăn | Tỷ lệ |
|---|---|
| Breakfast | 25% |
| Lunch | 35% |
| Dinner | 30% |
| Snack | 10% |

**Đánh giá:** HỢP LÝ — phù hợp thói quen Việt (lunch là bữa chính). Cân nhắc tăng breakfast 30%, giảm dinner 25% theo PMC 2024 front-loading research.

### A.12 Portion Conversion

**File:** `PortionConverterService.cs:173-185`

```
Giá trị dinh dưỡng = Giá trị per 100g × (Khối lượng thực tế / 100)
```

Ví dụ: 1 chén cơm = 200g → calories = `CaloriesPer100g × 200/100 = CaloriesPer100g × 2`.

**Đánh giá:** CHÍNH XÁC (chuẩn USDA FoodData Central).

### A.13 Macro Distribution (Analytics)

**File:** `AnalyticsService.cs:351-355`

```
% Protein = (Protein(g) × 4) / Tổng macro kcal × 100
% Carbs   = (Carbs(g)   × 4) / Tổng macro kcal × 100
% Fat     = (Fat(g)     × 9) / Tổng macro kcal × 100
```

So sánh với AMDR: Protein 10-35%, Carbs 45-65%, Fat 20-35%.

**Đánh giá:** CHÍNH XÁC.

### A.14 Recommendation Scoring

**File:** `RecommendationService.cs:163-211` (method `GetScoresAsync`)

Code thật tính 4 sub-score 0-100 trên tập 20 candidate foods/recipes, sau đó average thành overall:

```
CaloriesScore = avg(100 - min(100, |c - target| / target × 100))   // 0-100, cao = sát target
BudgetScore   = avg(100 - max(0, p - budget) / budget × 100)        // 0-100, cao = dưới budget
MacroScore    = max(40, 100 - (avgTime / limit) × 100)              // cao = nấu nhanh
                  // fallback 70 nếu timeCandidates rỗng
AllergyScore  = 100 nếu ExcludeUserAllergies=true, ngược lại 80
OverallScore  = (Calories + Macro + Allergy + Budget) / 4            // 0-100
```

**Score càng cao = càng phù hợp.** Mỗi sub-score clamp 0-100, Overall = arithmetic mean.

**Lưu ý:** Đây là score tổng hợp trên **candidate set** (20 item đầu), không phải per-item score. Từng food/recipe sẽ có overall score riêng khi gọi `POST /api/Recommendation/generate`.

**Đánh giá:** HỢP LÝ (proprietary heuristics, scale dễ đọc). Cần track hit rate ở `RecommendationFeedback` để calibrate weights ở `rec.retrain`.

### A.15 Streak

**File:** `UserDashboardService.cs:151-194`

```
if (lastLogDate != today && lastLogDate != yesterday) return 0;
// Đếm chuỗi ngày liên tiếp giảm dần từ lastLogDate
```

**Đánh giá:** CHÍNH XÁC (chuẩn habit-tracking pattern Duolingo/Habitica).

### Khuyến nghị cải thiện (cập nhật 2026-07-08, các item đã thực hiện được đánh dấu ✅)

1. ✅ **Giảm ngưỡng Calorie Drift từ 10% xuống 8%** — đã apply tại `GoalDriftService.cs:98`.
2. ⏳ **Tăng breakfast lên 30%, giảm dinner xuống 25%** — chưa thực hiện (cần A/B test).
3. ✅ **Tăng Carbs cho build muscle từ 40% lên 45%** — đã apply tại `HealthProfileMetricsCalculator.cs:87`.
4. ✅ **Thêm g/kg protein validation (0.8-2.2 g/kg)** — đã apply tại `HealthProfileMetricsCalculator.cs:92-100`.
5. ⏳ **Calibrate Adherence Score weights** bằng A/B testing.
6. ✅ **Thêm minimum TDEE ~1200 kcal** — đã apply tại `HealthProfileMetricsCalculator.cs:23` (TDEE floor).

---

## Nguồn tham khảo khoa học đầy đủ

| # | Nguồn | Link |
|---|---|---|
| 1 | Mifflin MD et al. (1990) | [PMC1375232](https://pmc.ncbi.nlm.nih.gov/articles/PMC1375232/) |
| 2 | Frankenfield D et al. (2005) | [PubMed](https://pubmed.ncbi.nlm.nih.gov/15919902/) |
| 3 | IOM/NIH AMDR (2002/2005) | [NBK610333](https://www.ncbi.nlm.nih.gov/books/NBK610333/) |
| 4 | NHS Calorie Counting (2026) | [NHS Better Health](https://www.nhs.uk/better-health/lose-weight/calorie-counting/) |
| 5 | Harvard Calorie Deficit | [Harvard Health](https://www.health.harvard.edu/weight-loss/calorie-deficit-explained-is-it-a-safe-sustainable-approach-to-weight-loss) |
| 6 | PMC Meal Timing Meta-Analysis (2024) | [PMC11530941](https://pmc.ncbi.nlm.nih.gov/articles/PMC11530941/) |
| 7 | Dietary Assessment Initiative (2026) | [Link](https://dietaryassessmentinitiative.org/publications/clinical-thresholds-self-monitoring-2026/) |
| 8 | Nutrition Research Review (2024) | [Link](https://nutrition-research-review.com/articles/impact-tracking-accuracy-weight-management-2024/) |
| 9 | USDA Dietary Guidelines 2020-2025 | [dietaryguidelines.gov](https://www.dietaryguidelines.gov/) |
| 10 | TDEEcal.net | [TDEEcal Sources](https://tdeecal.com/sources/) |
| 11 | Precision Nutrition | [Link](https://www.precisionnutrition.com/macros-vs-calories) |
| 12 | StatPearls Macronutrient Intake | [NBK594226](https://www.ncbi.nlm.nih.gov/books/NBK594226/) |
| 13 | HealthcareOnTime Calorie Distribution | [Link](https://www.healthcareontime.com/health-tips/how-many-calories-should-i-eat-for-breakfast-lunch-dinner-its-not-one-size-fits-all/) |
| 14 | Medscape Mifflin-St Jeor | [Link](https://reference.medscape.com/calculator/846/mifflin-st-jeor) |
| 15 | LoseIt Calorie Distribution | [Link](https://www.loseit.com/articles/calorie-distribution-in-a-meal-plan/) |