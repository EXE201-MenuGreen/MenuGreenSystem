# 05. Recommendation Engine

**Status:** API Done · UI Done (100%)
**Last updated:** 2026-07-08

**Related controller:** `backend/MenuGreen.API/Controllers/RecommendationController.cs`

**Related Flutter feature:** `frontend/lib/features/discover/views/recommendation_*.dart` (gộp với Discover — xem ghi chú)

---

## 1. Overview

Recommendation Engine cung cấp gợi ý món ăn/công thức cá nhân hóa:

- **Rule-based foundation** — gợi ý theo profile (calories target, macros, dị ứng).
- **AI-enhanced** — gợi ý theo ngân sách, thời gian nấu, lịch sử feedback.
- **Smart-schedule** — gợi ý kèm giờ ăn phù hợp.
- **History & feedback loop** — lưu lịch sử, thu thập feedback để retrain model cá nhân hóa.

---

## 2. Business Rules

### 2.1 Personalization Rules

- Recommendation phải trả về **lý do gợi ý** (explain endpoint) để user tin và hiểu vì sao món đó xuất hiện.
- Rule-based là nền an toàn tối thiểu; AI là lớp nâng cao để cá nhân hóa theo ngữ cảnh.
- Exclude user allergies mặc định trên mọi gợi ý (trừ khi `allergyMode=warn`).
- Kết hợp profile data: `HealthProfile.TargetCalories`, `TargetProteinG/CarbsG/FatG`, `DietaryGoal`.

### 2.2 Scoring (chi tiết formula tại [`10-vietnam-local-features.md` → Appendix A.14](./10-vietnam-local-features.md#14-recommendation-scoring))

- **Calorie Score:** `|ActualCalories - TargetCalories|` (thấp = tốt hơn).
- **Eco Score:** `(Budget - Price) + LimitMinutes` (thấp = tốt hơn).
- **Lunch Score:** `|Calories - Target| + max(0, Price - Budget) + max(0, Time - 20min)`.

### 2.3 Retrain (Personalization)

- `POST /api/Recommendation/retrain`:
  - Đọc feedback của user hiện tại.
  - Tính trọng số theo mode (lose weight, gain weight, maintain).
  - Lưu vào `UserAiProfile.Preferences.recommendationTuning`.
  - Ghi audit log.

### 2.4 History & Feedback

- Mỗi lần `generate` sẽ lưu `RecommendationHistory`.
- User có thể xóa lịch sử không cần thiết (`DELETE /history/{id}`).
- Feedback: like/dislike + comment; có thể update sau.
- `GET /feedback/summary` trả về tỷ lệ thích/không thích để user xem.

---

## 3. API Endpoints

### 3.1 Generate Recommendations

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Recommendation/generate` | Generate recommendation theo context |
| `POST` | `/api/Recommendation/generate/safe` | Safe — loại trừ dị ứng |
| `POST` | `/api/Recommendation/generate/daily-menu` | Menu trong ngày (4 bữa 25/35/30/10) |
| `POST` | `/api/Recommendation/generate/weekly-plan` | Plan theo tuần |
| `POST` | `/api/Recommendation/generate/budget-aware` | Theo ngân sách |
| `POST` | `/api/Recommendation/generate/smart-schedule` | Có giờ ăn gợi ý |
| `POST` | `/api/Recommendation/preview` | Preview không lưu history |

### 3.2 History & Feedback

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Recommendation/history` | Lịch sử recommendations |
| `GET` | `/api/Recommendation/{id}` | Chi tiết recommendation |
| `DELETE` | `/api/Recommendation/history/{id}` | Xóa lịch sử |
| `POST` | `/api/Recommendation/feedback` | Gửi feedback |
| `PUT` | `/api/Recommendation/feedback/{id}` | Cập nhật feedback |
| `GET` | `/api/Recommendation/feedback/summary` | Tổng hợp feedback |

### 3.3 Explain & Optimize

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Recommendation/explain/{id}` | Giải thích tại sao gợi ý |
| `GET` | `/api/Recommendation/scores?mealType=&targetCalories=` | Điểm phù hợp theo tiêu chí |
| `POST` | `/api/Recommendation/retrain` | Tối ưu cá nhân hóa từ feedback |

**Tổng: 16 endpoint.**

---

## 4. UI Components

UI Recommendation được tích hợp trong feature `discover/`:

| Component | File | Status |
|-----------|------|--------|
| RecommendationScreen | `features/discover/views/recommendation_screen.dart` | Done |
| SafeRecommendationsScreen | `features/discover/views/safe_recommendations_screen.dart` | Done |
| BudgetAwareScreen | `features/discover/views/budget_aware_screen.dart` | Done |
| WeeklyPlanScreen | `features/discover/views/weekly_plan_screen.dart` | Done |
| RecommendationDetailScreen | `features/discover/views/recommendation_detail_screen.dart` | Done |
| RecommendationHistoryScreen | `features/discover/views/recommendation_history_screen.dart` | Done |
| RecommendationCard | `features/discover/widgets/recommendation_card.dart` | Done |
| QuickRecommendationCard | `features/discover/widgets/quick_recommendation_card.dart` | Done |
| RecommendationItemTile | `features/discover/widgets/recommendation_item_tile.dart` | Done |
| ExplainBadge | `features/discover/widgets/explain_badge.dart` | Done |
| FeedbackButtons | `features/discover/widgets/feedback_buttons.dart` | Done |
| ScoreBreakdownWidget | `features/discover/widgets/score_breakdown_widget.dart` | Done |
| WeeklyPlanDayCard | `features/discover/widgets/weekly_plan_day_card.dart` | Done |
| RecommendationProvider | `features/discover/providers/recommendation_provider.dart` | Done |
| RecommendationRepository | `features/discover/repositories/recommendation_repository.dart` | Done |

**Tổng: 5 screens + 5 widgets, navigation trong DiscoverView.**

---

## 5. Navigation Flow

```
DiscoverView
└── RecommendationScreen
        ├── SafeRecommendationsScreen (mặc định, exclude allergies)
        ├── BudgetAwareScreen (lọc theo ngân sách)
        ├── WeeklyPlanScreen (plan 7 ngày)
        ├── RecommendationHistoryScreen (lịch sử)
        │       └── RecommendationDetailScreen
        │               ├── ExplainBadge (lý do gợi ý)
        │               ├── ScoreBreakdownWidget (điểm chi tiết)
        │               └── FeedbackButtons (like/dislike)
        └── Tap "Tạo plan" → MealPlanScreen (xem 03-meal-plan.md)
        └── Tap món → FoodDetailScreen / RecipeDetailScreen (xem 04-discover-and-allergy.md)
```

---

## 6. Data Models (rút gọn)

```
RecommendationHistory
├── Id, UserId, GeneratedAt
├── Context (calorie target, budget, meal type, ...)
├── Recommendations[] (items + scores)
└── Source (rule-based / ai-hybrid)

RecommendationFeedback
├── Id, RecommendationHistoryId
├── UserId, IsPositive (bool)
├── Reason (Helpful / NotRelevant / IncorrectInformation / ...)
└── Comment

UserAiProfile.Preferences.recommendationTuning (JSON)
├── ModeWeights (loseWeight/gainWeight/maintain)
├── PreferredCategories[]
├── AvoidedIngredients[]
└── TimePreferences
```

Backend models đầy đủ: [`../02-backend/backend_models_documentation.md`](../02-backend/backend_models_documentation.md) (mục 1.5 + Recommendation entities).

---

## 7. Related Documents

- Discover + safe alternatives: [`04-discover-and-allergy.md`](./04-discover-and-allergy.md)
- AI tạo meal plan: [`06-ai-assistant-and-coach.md`](./06-ai-assistant-and-coach.md)
- User profile (calorie target): [`01-auth-and-account.md`](./01-auth-and-account.md)
- Scoring formulas: [`10-vietnam-local-features.md` → Appendix A.14](./10-vietnam-local-features.md#14-recommendation-scoring)
- File cũ (archive): [`../_archive/features/RECOMMENDATION.md`](../_archive/features/RECOMMENDATION.md)

---

## 8. Thay đổi so với file cũ

File cũ `features/RECOMMENDATION.md` ghi status **"UI Partial"**, nhưng kiểm tra thực tế:

- `frontend/lib/features/discover/` đã có 5 screens + 5 widgets + provider/repository hoàn chỉnh.
- `README_WORKFLOW_API_STATUS.md` (mục 2.6) ghi **"UI Hoàn thành 100%"** và liệt kê đầy đủ.

→ Status canonical được đồng bộ thành **"UI Done 100%"** theo nguồn có nhiều evidence hơn. File `PROJECT_STATUS.md` đã được cập nhật để tham chiếu file canonical này.