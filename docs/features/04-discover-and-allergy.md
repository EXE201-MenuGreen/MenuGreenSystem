# 04. Discover & Allergy

**Status:** API Done · UI Done (100%)
**Last updated:** 2026-07-09

**Related controllers:**
- `backend/MenuGreen.API/Controllers/FoodController.cs`
- `backend/MenuGreen.API/Controllers/RecipeController.cs`
- `backend/MenuGreen.API/Controllers/AllergyController.cs`
- `backend/MenuGreen.API/Controllers/PortionConverterController.cs`

**Related Flutter feature:** `frontend/lib/features/discover/`

---

## 1. Overview

Nhóm tính năng khám phá thực phẩm, công thức, và quản lý dị ứng:

- **Discover** — tìm món/công thức/nguyên liệu theo từ khóa, lọc theo calo/đạm/giá/category; lọc theo dị ứng (allergy mode: hide/warn).
- **Allergy** — CRUD allergy profile + risk evaluation cho từng món; Allergy Risk Badge trên UI.
- **Portion Converter** — quy đổi đơn vị Việt Nam (chén, bát, đĩa, muỗng, trái) sang gram.
- **Safe Alternatives** — tìm công thức thay thế an toàn khi món có dị ứng.

---

## 2. Business Rules

### 2.1 Discover

- Tìm kiếm food/recipe/ingredient theo từ khóa.
- Filter: calories min/max, protein high/low, max price, category.
- **Allergy mode:**
  - `hide` — ẩn hoàn toàn món có dị ứng.
  - `warn` — hiển thị món nhưng có Allergy Risk Badge cảnh báo.
- Yêu thích (favorite): lưu danh sách món user thích để truy cập nhanh.
- Từ trang chi tiết food/recipe → ghi meal log trực tiếp (xem [`02-nutrition-tracking.md`](./02-nutrition-tracking.md)).

### 2.2 Allergy

- **Allergy profile:** danh sách dị ứng user khai báo (UserAllergy).
- **Catalog:** danh sách master allergies (Allergy table) — không phụ thuộc user.
- **Risk evaluation:** đánh giá rủi ro dị ứng của 1 món/công thức/meal đối với user.
  - `Low` — không chứa allergen user dị ứng.
  - `Medium` — chứa 1 allergen ở dạng derivative.
  - `High` — chứa trực tiếp allergen user dị ứng.
- **Batch evaluate:** đánh giá nhiều meal cùng lúc.
- **Badge:** `GET /api/Allergy/meal/{mealId}/badge` trả badge info cho UI.
- **Recommendations:** `GET /api/Allergy/recommendations` — gợi ý món phù hợp với allergy profile.

### 2.3 Portion Converter

- Hỗ trợ 3 tầng: user custom units → food-specific mapping → default units.
- Default unit nếu không tìm thấy mapping: coi là gram (factor = 1.0).
- Custom units cho phép user tự định nghĩa (VD: "bát nhỏ", "muỗng canh").
- Công thức quy đổi: `Giá trị dinh dưỡng = Giá trị per 100g × (Khối lượng thực tế / 100)` (xem [`10-vietnam-local-features.md` → Appendix A.12](./10-vietnam-local-features.md#12-portion-conversion)).

### 2.4 Safe Alternatives

- `GET /api/Recipe/{recipeId}/safe-alternatives` — tìm công thức thay thế khi món hiện tại không an toàn.
- Logic: tìm recipe cùng category + calorie range + không chứa allergen user dị ứng.

---

## 3. API Endpoints

### 3.1 Food & Recipe

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Food?keyword=&category=&calorieMin=&calorieMax=&proteinLevel=&maxPrice=&allergyMode=` | Tìm food (root endpoint, cũng dùng cho create) |
| `POST` | `/api/Food` | Tạo food (Admin — cùng route với search, phân biệt bởi body) |
| `GET` | `/api/Food/{id}` | Chi tiết food |
| `GET` | `/api/Food/{id}/recipes` | Recipe dùng food này |
| `GET` | `/api/Food/favorites` | Danh sách yêu thích |
| `POST` | `/api/Food/{id}/favorite` | Thêm vào yêu thích |
| `DELETE` | `/api/Food/{id}/favorite` | Bỏ khỏi yêu thích |
| `PUT` | `/api/Food/{id}` | Sửa food (Admin) |
| `DELETE` | `/api/Food/{id}` | Xóa food (Admin) |
| `PUT` | `/api/Food/{id}/allergies` | Cập nhật nhãn allergen (Admin) |
| `GET` | `/api/Recipe/search?keyword=` | Tìm recipe |
| `GET` | `/api/Recipe/{id}` | Chi tiết recipe |
| `GET` | `/api/Recipe/{id}/ingredients` | Danh sách nguyên liệu |
| `GET` | `/api/Recipe/{id}/nutrition` | Nutrition tổng hợp |
| `GET` | `/api/Recipe/{id}/related` | Recipe liên quan |
| `PUT` | `/api/Recipe/{id}` | Sửa recipe (Admin) |
| `DELETE` | `/api/Recipe/{id}` | Xóa recipe (Admin) |

### 3.2 Allergy

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Allergy` | Lấy allergy profile user |
| `POST` | `/api/Allergy` | Thêm dị ứng |
| `PUT` | `/api/Allergy/{allergyId}` | Sửa dị ứng |
| `DELETE` | `/api/Allergy/{allergyId}` | Xóa dị ứng |
| `PUT` | `/api/Allergy/profile` | Cập nhật profile allergy (bulk) |
| `GET` | `/api/Allergy/catalog` | Master danh sách allergies |
| `POST` | `/api/Allergy/evaluate` | Đánh giá risk cho 1 meal |
| `POST` | `/api/Allergy/evaluate/batch` | Đánh giá batch |
| `GET` | `/api/Allergy/meal/{mealId}/badge` | Lấy badge cho meal |
| `GET` | `/api/Allergy/recommendations` | Gợi ý món phù hợp |

### 3.3 Portion Converter

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/PortionConverter/units` | Default units |
| `GET` | `/api/PortionConverter/units/food/{foodId}` | Units cho 1 food |
| `POST` | `/api/PortionConverter/convert` | Convert quantity → grams + nutrition |
| `GET` | `/api/PortionConverter/custom-units` | Custom units của user |
| `POST` | `/api/PortionConverter/custom-units` | Tạo custom unit |
| `PUT` | `/api/PortionConverter/custom-units/{id}` | Sửa custom unit |
| `DELETE` | `/api/PortionConverter/custom-units/{id}` | Xóa custom unit |

### 3.4 Vietnam Discovery (Nutrition)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Nutrition/discovery/local` | Discovery local (VN foods) |
| `GET` | `/api/Nutrition/discovery/local/by-region/{region}` | Theo vùng miền |
| `GET` | `/api/Nutrition/discovery/local/by-budget` | Theo ngân sách |

### 3.5 Ingredient Substitution (`IngredientSubstitutionController`)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Ingredient/{id}/substitutes` | Gợi ý nguyên liệu thay thế |
| `POST` | `/api/Ingredient/substitutes/batch` | Batch gợi ý thay thế |
| `GET` | `/api/Ingredient/preferences/substitutes` | Preference thay thế của user |
| `POST` | `/api/Ingredient/preferences/substitutes` | Lưu preference thay thế |
| `DELETE` | `/api/Ingredient/preferences/substitutes/{id}` | Xóa preference thay thế |
| `GET` | `/api/Recipe/{recipeId}/substitute-ingredient/{ingredientId}` | Gợi ý thay thế 1 nguyên liệu trong recipe |
| `GET` | `/api/Recipe/{recipeId}/safe-alternatives` | Tìm recipe thay thế an toàn (cùng category, không chứa allergen) |
| `POST` | `/api/MealPlan/{planId}/items/{itemId}/substitute-ingredient` | Thay thế nguyên liệu trong meal plan item |
| `POST` | `/api/NutritionTracking/meal-logs/{mealLogId}/substitute-ingredient` | Thay thế nguyên liệu trong meal log |

**Tổng: 44 endpoint** (10 Food + 8 Recipe + 10 Allergy + 7 Portion + 3 Vietnam Discovery + 9 Ingredient Substitution). Endpoint `categories` đã gộp vào response của `Food/search`.

---

## 4. UI Components

### 4.1 Discover

| Component | File | Status |
|-----------|------|--------|
| DiscoverView | `features/discover/views/discover_view.dart` | Done |
| FoodDetailScreen | `features/discover/views/food_detail_screen.dart` | Done |
| RecipeDetailScreen | `features/discover/views/recipe_detail_screen.dart` | Done |
| IngredientDetailScreen | `features/discover/views/ingredient_detail_screen.dart` | Done |
| FavoritesScreen | `features/discover/views/favorites_screen.dart` | Done |
| SafeRecommendationsScreen | `features/discover/views/safe_recommendations_screen.dart` | Done |
| BudgetAwareScreen | `features/discover/views/budget_aware_screen.dart` | Done |
| DiscoverFoodFiltersSheet | `features/discover/widgets/discover_food_filters_sheet.dart` | Done |
| AllergyRiskBadge | `features/discover/widgets/allergy_risk_badge.dart` | Done |

### 4.2 Recommendation (UI riêng cho Discover)

| Component | File | Status |
|-----------|------|--------|
| RecommendationScreen | `features/discover/views/recommendation_screen.dart` | Done |
| RecommendationDetailScreen | `features/discover/views/recommendation_detail_screen.dart` | Done |
| RecommendationHistoryScreen | `features/discover/views/recommendation_history_screen.dart` | Done |
| WeeklyPlanScreen | `features/discover/views/weekly_plan_screen.dart` | Done |
| RecommendationCard | `features/discover/widgets/recommendation_card.dart` | Done |
| QuickRecommendationCard | `features/discover/widgets/quick_recommendation_card.dart` | Done |
| RecommendationItemTile | `features/discover/widgets/recommendation_item_tile.dart` | Done |
| ExplainBadge | `features/discover/widgets/explain_badge.dart` | Done |
| FeedbackButtons | `features/discover/widgets/feedback_buttons.dart` | Done |
| ScoreBreakdownWidget | `features/discover/widgets/score_breakdown_widget.dart` | Done |
| WeeklyPlanDayCard | `features/discover/widgets/weekly_plan_day_card.dart` | Done |

> Lưu ý: Recommendation API/UI là phần "gợi ý an toàn" (UI đã làm 100%) trong Discover. Workflow Recommendation đầy đủ xem [`05-recommendation-engine.md`](./05-recommendation-engine.md).

### 4.3 Providers & Repositories

| Component | File | Status |
|-----------|------|--------|
| RecommendationProvider | `features/discover/providers/recommendation_provider.dart` | Done |
| RecommendationRepository | `features/discover/repositories/recommendation_repository.dart` | Done |
| FoodDiscoveryRepository | `features/discover/repositories/food_discovery_repository.dart` | Done |
| FoodModels | `features/discover/models/food_models.dart` | Done |

---

## 5. Navigation Flow

```
MainScreen
└── Tab Khám phá → DiscoverView
        ├── Search + Filters (DiscoverFoodFiltersSheet)
        │       ├── Calories min/max, protein high/low
        │       ├── Max price, category
        │       └── Allergy mode: hide/warn
        ├── Tap food → FoodDetailScreen
        │       ├── AllergyRiskBadge
        │       ├── Recipes liên quan
        │       ├── Favorite toggle
        │       └── "Ghi nhật ký" → MealLogSheet (xem 02-nutrition-tracking.md)
        ├── Tap recipe → RecipeDetailScreen
        │       ├── Ingredients, instructions
        │       ├── Safe Alternatives button
        │       └── "Ghi nhật ký" → MealLogSheet
        ├── Tap ingredient → IngredientDetailScreen
        │       └── Recipes dùng ingredient
        ├── Favorites → FavoritesScreen
        └── RecommendationScreen (an toàn)
                ├── SafeRecommendationsScreen
                ├── BudgetAwareScreen
                ├── WeeklyPlanScreen
                └── RecommendationHistoryScreen
                        └── RecommendationDetailScreen
```

---

## 6. Data Models (rút gọn)

```
Food
├── Id, Name, NameEn?, NameVi?, Barcode, Brand
├── ServingSize, CaloriesKcal (per 100g)
├── ProteinG, CarbsG, FatG, FiberG
├── Category, PriceVnd
├── IsVerified
└── AllergenTags[] (FoodAllergenTag)

Recipe
├── Id, Title, Description, Instructions
├── PrepTimeMinutes, CookTimeMinutes
├── Difficulty, Servings
├── TotalCalories, TotalProtein, TotalCarbs, TotalFat
├── Ingredients[] (RecipeIngredient)
└── ImageUrl

Allergy
├── Id, Name, AllergenKey (peanut/seafood/...)
└── Severity

UserAllergy
├── UserId, AllergyId
└── SeverityOverride?

AllergenRiskResult
├── MealId, RiskLevel (Low/Medium/High)
└── MatchedAllergens[]

PortionUnit
├── Id, Name (chén/bát/...)
├── FoodId? (nullable = default unit)
├── FactorToGram (1 chén = 200g, ...)
└── IsCustom, UserId?
```

Backend models đầy đủ: [`../02-backend/backend_models_documentation.md`](../02-backend/backend_models_documentation.md) (mục 1.3 Allergy, Foods & Recipes).

---

## 7. Related Documents

- Allergy profile (onboarding): [`01-auth-and-account.md`](./01-auth-and-account.md)
- Ghi meal log từ discovery: [`02-nutrition-tracking.md`](./02-nutrition-tracking.md)
- Recommendation engine: [`05-recommendation-engine.md`](./05-recommendation-engine.md)
- AI tạo safe-alternatives: [`06-ai-assistant-and-coach.md`](./06-ai-assistant-and-coach.md)
- Portion converter formula: [`10-vietnam-local-features.md` → Appendix A.12](./10-vietnam-local-features.md#12-portion-conversion)
- User workflow cũ (mục 4.5, 4.6): [`../_archive/root-readmes/README_USER_WORKFLOW.md`](../_archive/root-readmes/README_USER_WORKFLOW.md)