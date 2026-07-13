# 18. Ingredient Catalog

**Status:** API Done · UI Done · **Assessment: DONE**
**Last updated:** 2026-07-13

**Related controller:** `backend/MenuGreen.API/Controllers/IngredientController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/IngredientService.cs`

**Related Flutter features:** `frontend/lib/features/advanced/` — search/allergy-safe, detail/recipes và Admin CRUD.

---

## 1. Overview

Ingredient Catalog cung cấp **CRUD nguyên liệu thô** (không phải Food — đã qua chế biến) và tìm kiếm nguyên liệu theo keyword/category. Đây là tầng dữ liệu nguyên liệu gốc, phục vụ cho Recipe và Meal Planning.

Khác với `FoodController`: Food = thực phẩm đã đóng gói/qua chế biến (có barcode, brand, nutrition label); Ingredient = nguyên liệu thô trong nấu ăn (gia vị, rau củ, thịt cá...).

Khác với `IngredientSubstitutionController`: Substitution = tìm thay thế cho nguyên liệu cụ thể; Ingredient = CRUD + search nguyên liệu gốc.

---

## 2. Business Rules

- User tìm kiếm nguyên liệu theo keyword, category, allergy-safe mode.
- Xem danh sách recipes sử dụng nguyên liệu.
- Admin CRUD nguyên liệu trong catalog.
- Allergy-aware search mode: lọc nguyên liệu an toàn cho user.

---

## 3. API Endpoints

### 3.1 User — Search & Browse

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Ingredient/search` | Tìm kiếm nguyên liệu (keyword, category, allergyMode) |
| `GET` | `/api/Ingredient/{id}` | Chi tiết nguyên liệu |
| `GET` | `/api/Ingredient/{id}/recipes` | Danh sách recipes dùng nguyên liệu này |
| `GET` | `/api/Ingredient/catalog` | Catalog đầy đủ (cho browse) |

### 3.2 Admin — CRUD

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Ingredient` | Tạo nguyên liệu mới (Admin) |
| `PUT` | `/api/Ingredient/{id}` | Cập nhật nguyên liệu (Admin) |
| `DELETE` | `/api/Ingredient/{id}` | Xóa nguyên liệu (Admin) |

**Tổng: 7 endpoint.**

---

## 4. UI Components

Flutter UI đã triển khai trong feature `advanced` và liên kết với:

- Discover/Ingredient search screen
- Recipe creation/editing screen
- Ingredient detail/recipes và Admin create/edit/delete

---

## 5. Relationship with Other Modules

- Ingredient search dùng allergy info từ `AllergyController`.
- Recipes chứa `RecipeIngredient` → link đến `Ingredient`.
- `IngredientSubstitutionController` dùng Ingredient data để tìm substitutes.
- `RecipeController` trả về ingredient list cho recipe.

---

## 6. Notes

- Đây là data layer — user thường không tương tác trực tiếp mà qua Recipe/Food screens.
- Admin CRUD có thể tích hợp vào Admin Panel.

## 7. Verification & Assessment (2026-07-12)

- [x] Có UI tìm kiếm catalog và chế độ chỉ hiện nguyên liệu an toàn dị ứng.
- [x] Có bộ lọc category gửi đúng query `category` cho backend.
- [x] Đã sửa route tài liệu từ `/api/Ingredients` sang route controller thực tế `/api/Ingredient`.
- [x] Có ingredient detail và danh sách recipes sử dụng nguyên liệu.
- [x] Có form Admin tạo/sửa/xóa với các trường nutrition, giá, đơn vị và ảnh.

**Đánh giá: DONE.** Search/allergy mode, detail/recipes và Admin CRUD đều đã có UI nối đúng route `/api/Ingredient`. Cần smoke test thêm bằng JWT Admin thật trước production.
