# 12. Meal Templates

**Status:** API Done · UI Needs Correction
**Last updated:** 2026-07-11

**Related controller:** `backend/MenuGreen.API/Controllers/MealTemplateController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/MealTemplateService.cs`

**Related Flutter features:** **UI Needs Correction**

- `frontend/lib/features/meal_templates/views/meal_templates_screen.dart` - danh sách, tạo/sửa, nhân bản, xóa và ghi thực đơn đã lưu.
- `frontend/lib/features/meal_templates/repositories/meal_template_repository.dart` - kết nối đầy đủ 9 API của `MealTemplateController`.
- `frontend/lib/features/meal_templates/models/meal_template_models.dart` - model thực đơn, món và dữ liệu gửi lên API.
- `frontend/lib/features/history/views/history_view.dart` - lưu một meal log thành thực đơn.
- `frontend/lib/features/home/widgets/quick_action_grid.dart` - điểm truy cập từ Home với nhãn `Thực đơn đã lưu`.

---

## 1. Overview

Thực đơn đã lưu cho phép user lưu một **bữa ăn lặp lại** gồm nhiều món để ghi nhanh vào nhật ký sau này, không cần tìm lại từng món. User có thể bắt đầu từ một meal log đã có hoặc tự tạo thực đơn, sau đó chỉnh sửa khối lượng từng món trước khi ghi.

`MealTemplate` chỉ biểu diễn một bữa ăn, ví dụ bữa sáng quen thuộc hoặc bữa trưa văn phòng. `MealType` nằm ở `MealTemplate` để xác định đó là bữa Sáng/Trưa/Tối/Bữa phụ; các `MealTemplateItem` chỉ là các món thuộc bữa ăn đó.

Khác với `MealPlan`: `MealPlan` là kế hoạch theo ngày/khoảng ngày và là nơi phân các bữa Sáng/Trưa/Tối/Bữa phụ.

---

## 2. Business Rules

- Thực đơn thuộc về một user; controller yêu cầu authentication và policy `UserOnly`.
- User chỉ có thể lấy, sửa, xóa, nhân bản hoặc ghi thực đơn của chính mình.
- Tạo từ meal log qua `POST /from-log/{mealLogId}`; giữ `FoodId`/`RecipeId`, khối lượng và ghi chú của log nguồn.
- Thực đơn có thể nhân bản và xem `UsageCount`.
- Khi ghi từ thực đơn qua `POST /{id}/log`, user chọn ngày và có thể điều chỉnh khối lượng từng món trước khi xác nhận.
- Mỗi món được ghi thành một `MealLog` cùng `MealType` của template; `UsageCount` tăng một lần cho mỗi lần ghi thực đơn thành công.
- Xóa là soft delete: thực đơn được đánh dấu `IsActive = false` và không còn hiển thị trong UI.

---

## 3. API Endpoints

Base route thực tế là `/api/MealTemplate` (số ít, theo `[controller]`).

### 3.1 Template CRUD

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/MealTemplate` | Danh sách thực đơn của user |
| `GET` | `/api/MealTemplate/{id}` | Chi tiết thực đơn và các món |
| `POST` | `/api/MealTemplate` | Tạo thực đơn mới |
| `PUT` | `/api/MealTemplate/{id}` | Cập nhật thực đơn |
| `DELETE` | `/api/MealTemplate/{id}` | Soft delete thực đơn |

### 3.2 Template Actions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/MealTemplate/{id}/log` | Ghi thực đơn vào `MealLog`; hỗ trợ ghi đè khối lượng từng món |
| `POST` | `/api/MealTemplate/{id}/duplicate` | Nhân bản thực đơn |
| `GET` | `/api/MealTemplate/{id}/usage` | Số lần đã ghi từ thực đơn |
| `POST` | `/api/MealTemplate/from-log/{mealLogId}?title={title}` | Tạo thực đơn từ một meal log |

**Tổng: 9 endpoint.**

---

## 4. UI Components

- **Danh sách thực đơn đã lưu:** tải danh sách, refresh, tạo mới, mở chỉnh sửa, ghi nhanh, nhân bản và xóa.
- **Màn hình tạo/chỉnh sửa:** cần nhập tên, mô tả, chọn một `MealType`, thêm food/recipe, chỉnh khối lượng/ghi chú và xóa món.
- **Thực đơn có sẵn:** người dùng có thể chọn một khung thực đơn cân bằng, giảm cân hoặc tăng cơ, sau đó chỉnh sửa từng món.
- **Modal ghi thực đơn:** chọn ngày, điều chỉnh khối lượng từng món, xác nhận tạo `MealLog`.
- **Từ lịch sử:** mỗi meal log có hành động `Lưu thành thực đơn`.

---

## 5. Relationship with Other Modules

- `log` tạo dữ liệu trong `MealLog` qua `NutritionTrackingService`.
- Người dùng chọn `Food` hoặc `Recipe` từ catalog khi tạo/chỉnh sửa.
- Home Quick Action điều hướng đến màn hình thực đơn đã lưu.
- History có thể chuyển một meal log hiện hữu thành thực đơn.

---

## 6. Đánh giá

Luồng Flutter đã kết nối với toàn bộ CRUD, log, duplicate và create-from-log của backend; `flutter analyze` cũng không báo lỗi. Tuy nhiên, UI hiện tổ chức một template thành các phần Sáng/Trưa/Tối/Bữa phụ và gửi `MealType = Daily`. Cách này không đúng phạm vi nghiệp vụ của tài liệu.

Để đạt `UI Done`, cần đổi UI tạo/chỉnh sửa về một dropdown `MealType` duy nhất ở cấp `MealTemplate`; bỏ nhóm Sáng/Trưa/Tối/Bữa phụ, bỏ `MealType` khỏi `MealTemplateItem`, và khi log dùng `MealType` của template cho mọi món. Không cần tạo entity `MealTemplateSection`.

Chưa có automated API/integration test riêng cho `MealTemplateController`; cần bổ sung test authorization, ownership, log với quantity override, soft delete và create-from-log trước khi phát hành production.

## 7. Notes

- `MealTemplate` khác `MealPlan`: template là một bữa ăn tái sử dụng; meal plan quản lý nhiều bữa theo ngày.
- Có thể dùng thực đơn đã lưu làm nguồn quick-add cho AI Coach hoặc Daily Starter trong tương lai.
