# 13. Micro-Learning

**Status:** API Done · UI Done
**Last updated:** 2026-07-11

**Related controller:** `backend/MenuGreen.API/Controllers/MicroLearningController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/MicroLearningService.cs`
**Related admin controller:** `backend/MenuGreen.API/Controllers/AdminMicroLearningController.cs`

**Related Flutter features:** **UI DONE**

- `frontend/lib/features/micro_learning/views/micro_learning_screen.dart` - feed đề xuất, filter chủ đề, chi tiết card, quiz và danh sách đã lưu.
- `frontend/lib/features/micro_learning/repositories/micro_learning_repository.dart` - kết nối 6 API user-facing.
- `frontend/lib/features/micro_learning/models/micro_learning_models.dart` - model card, category và quiz result.
- `frontend/lib/features/home/widgets/quick_action_grid.dart` - shortcut `Góc dinh dưỡng` từ Home.

---

## 1. Overview

Micro-Learning cung cấp các thẻ kiến thức dinh dưỡng ngắn để user học nhanh trong lúc rảnh, ví dụ vai trò của protein hoặc cách đọc nhãn thực phẩm. Mỗi thẻ có nội dung tóm tắt, quick tips và có thể có quiz để kiểm tra hiểu biết.

Mục tiêu là tăng engagement thông qua giáo dục dinh dưỡng, quiz và điểm thưởng khi trả lời đúng.

---

## 2. Business Rules

- Cards được cá nhân hóa dựa trên health profile, dị ứng và nutrition issues của user.
- User có thể đọc, lưu, bỏ lưu hoặc ẩn card.
- Quiz submit trả về feedback và số điểm của lần trả lời đó.
- Categories: Protein, Sodium, Allergy, Hydration và General.

---

## 3. API Endpoints

Base route thực tế là `/api/MicroLearning` (số ít, theo `[controller]`).

### 3.1 Card Discovery & Browse

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/MicroLearning/cards/recommended` | Cards được cá nhân hóa cho user |
| `GET` | `/api/MicroLearning/cards/{id}` | Chi tiết card: nội dung, tips, quiz và trạng thái user |
| `GET` | `/api/MicroLearning/categories` | Danh mục topics |

### 3.2 User Card Actions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/MicroLearning/cards/{id}/action` | Ghi nhận `read`, `save`, `unsave`, `dismiss` |
| `GET` | `/api/MicroLearning/cards/saved` | Danh sách cards đã lưu |

### 3.3 Quiz

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/MicroLearning/cards/{id}/quiz/submit` | Submit đáp án quiz, nhận feedback và điểm |

**Tổng user-facing: 6 endpoint.**

### 3.4 Admin Micro-Learning

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/admin/micro-learning/cards` | List all cards (paginated) |
| `GET` | `/api/admin/micro-learning/cards/{id}` | Get card by id |
| `POST` | `/api/admin/micro-learning/cards` | Create card |
| `PUT` | `/api/admin/micro-learning/cards/{id}` | Update card |
| `DELETE` | `/api/admin/micro-learning/cards/{id}` | Delete card |
| `GET` | `/api/admin/micro-learning/categories` | List categories |

---

## 4. UI Components

### Implementation checklist

- [x] Recommended cards feed với pull-to-refresh và trạng thái đã đọc/đã lưu/đã hoàn thành quiz.
- [x] Card detail view hiển thị summary, quick tips, điểm thưởng và hành động read/save/dismiss.
- [x] Saved cards screen với dữ liệu từ `GET /cards/saved`.
- [x] Category browse bằng chips để lọc các card trong feed đề xuất theo chủ đề.
- [x] Quiz interaction UI: chọn đáp án, submit, feedback, đáp án đã hoàn thành và điểm đạt được.
- [x] Progress display: số thẻ đã đọc và số quiz hoàn thành trong danh sách đề xuất hiện tại.
- [x] Entry point từ Home qua quick action `Góc dinh dưỡng`.

### Giới hạn hiện tại

- API categories chỉ trả metadata; do đó category browse chỉ lọc danh sách card đề xuất, chưa thể duyệt toàn bộ card theo từng category.
- Backend chỉ trả `PointsEarned` khi submit quiz, chưa có trường hoặc endpoint tổng điểm tích lũy của user.

---

## 5. Relationship with Other Modules

- `recommended` dùng `HealthProfile`, dị ứng và `MealLog` trong `NutritionTracking` để cá nhân hóa.
- Tương tác của user lưu ở `UserCardInteraction`.
- Admin CRUD cards qua `AdminMicroLearningController` với policy `AdminOnly`.
- Home Quick Action điều hướng tới `Góc dinh dưỡng`.

---

## 6. Verification

- [x] `flutter analyze` cho feature micro-learning, API endpoints và Home quick action không báo lỗi.
- [ ] Chưa có automated API/integration test riêng cho `MicroLearningController`.
- [ ] Cần seed dữ liệu từ `backend/MenuGreen_AI_SeedData/49_micro_learning_cards.sql` trước khi feed có thể trả card.

## 7. Notes

- Micro-Learning là gamification layer cho user engagement.
- Điểm quiz hiện chỉ phản hồi theo từng lần submit; chưa có ví điểm tích lũy chung cho user.
