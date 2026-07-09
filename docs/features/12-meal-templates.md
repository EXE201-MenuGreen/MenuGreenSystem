# 12. Meal Templates

**Status:** API Done · UI Not Done
**Last updated:** 2026-07-09

**Related controller:** `backend/MenuGreen.API/Controllers/MealTemplateController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/MealTemplateService.cs`

**Related Flutter features:** Chưa có

---

## 1. Overview

Meal Templates cho phép user **lưu nhanh bữa ăn lặp lại** (breakfast cố định mỗi ngày, bữa trưa văn phòng...) để log nhanh mà không cần tìm kiếm lại từ đầu.

Khác với `MealPlan`: MealPlan = kế hoạch nhiều bữa theo ngày, có items với date/slot; MealTemplate = 1 bữa riêng lẻ, có thể gắn với meal type, không gắn date.

---

## 2. Business Rules

- Template thuộc về 1 user, chỉ user đó thấy.
- Tạo template từ meal log đã ghi (`POST /from-log/{mealLogId}`) — giữ nguyên food, quantity, nutrition.
- Template có thể duplicate, có thể xem usage count (đếm số lần log từ template).
- Khi log từ template (`POST /{id}/log`), chọn date + meal type + có thể điều chỉnh quantity.
- Template không có ngày cụ thể — user chọn khi log.

---

## 3. API Endpoints

### 3.1 Template CRUD

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/MealTemplates` | Danh sách templates của user |
| `GET` | `/api/MealTemplates/{id}` | Chi tiết template |
| `POST` | `/api/MealTemplates` | Tạo template mới |
| `PUT` | `/api/MealTemplates/{id}` | Cập nhật template |
| `DELETE` | `/api/MealTemplates/{id}` | Xóa template |

### 3.2 Template Actions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/MealTemplates/{id}/log` | Log nhanh từ template (tạo MealLog) |
| `POST` | `/api/MealTemplates/{id}/duplicate` | Nhân bản template |
| `GET` | `/api/MealTemplates/{id}/usage` | Số lần đã log từ template |
| `POST` | `/api/MealTemplates/from-log/{mealLogId}` | Tạo template từ meal log đã ghi |

**Tổng: 9 endpoint.**

---

## 4. UI Components

Chưa có Flutter UI. Cần phát triển:

- Template list screen
- Create/edit template screen
- Log from template modal
- Create from existing meal log option

---

## 5. Relationship with Other Modules

- `log` → ghi vào `MealLog` (NutritionTrackingController).
- Template food data lấy từ `Food` entity (FoodController).
- Usage count tính từ `MealLog` records.

---

## 6. Notes

- MealTemplate vs MealPlan: template là bữa đơn lẻ lặp lại; plan là kế hoạch nhiều bữa theo date range.
- Template có thể dùng trong AI Coach / Daily Starter làm quick-add options.
