# 16. Budget Management

**Status:** API Done · UI Not Done
**Last updated:** 2026-07-09

**Related controller:** `backend/MenuGreen.API/Controllers/BudgetRequestController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/BudgetRequestService.cs`

**Related Flutter features:** Chưa có

---

## 1. Overview

Budget Management cho phép user thiết lập **ngân sách ăn uống hàng ngày/tuần** và **giới hạn thời gian nấu** để hệ thống gợi ý món phù hợp với khả năng chi trả.

Khác với `MealPlanController.generate-by-budget`: generate-by-budget tạo meal plan từ budget đã lưu; BudgetRequestController quản lý chính budget configuration.

---

## 2. Business Rules

- Mỗi user chỉ có **1 active budget** tại một thời điểm.
- Tạo budget mới sẽ deactivate budget cũ.
- Budget bao gồm: daily/weekly spending limit, cooking time preference.
- Budget được dùng bởi `MealPlanController` (generate-by-budget) và `RecommendationController` (budget-aware).
- Có thể xóa budget (quay về không giới hạn).

---

## 3. API Endpoints

### 3.1 Budget CRUD

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/BudgetRequest/me` | Lấy active budget hiện tại *(route prefix: `[Route("api/[controller]")]` = `/api/BudgetRequest`, singular)* |
| `POST` | `/api/BudgetRequest` | Tạo budget mới (deactivate cũ) |
| `PUT` | `/api/BudgetRequest/{id}` | Cập nhật budget |
| `DELETE` | `/api/BudgetRequest/{id}` | Xóa budget |

**Tổng: 4 endpoint.**

---

## 4. UI Components

Chưa có Flutter UI. Cần phát triển:

- Budget setup/edit screen
- Budget display on home/dashboard

---

## 5. Relationship with Other Modules

- `MealPlanController.generate-by-budget` đọc active budget.
- `RecommendationController.generate/budget-aware` đọc active budget.
- Budget data có thể hiển thị trên `UserDashboardController`.

---

## 6. Notes

- Đây là configuration layer đơn giản — không có analytics chi tiêu riêng.
- MealPlanController có `compare-expenses` và `expense-breakdown` cho chi tiết chi phí thực tế vs kế hoạch.
