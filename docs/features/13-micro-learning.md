# 13. Micro-Learning

**Status:** API Done · UI Not Done
**Last updated:** 2026-07-09

**Related controller:** `backend/MenuGreen.API/Controllers/MicroLearningController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/MicroLearningService.cs`

**Related admin controller:** `backend/MenuGreen.API/Controllers/AdminMicroLearningController.cs`

**Related Flutter features:** Chưa có

---

## 1. Overview

Micro-Learning cung cấp các **thẻ kiến thức dinh dưỡng ngắn** (cards) giúp user học lý thuyết trong lúc rảnh (ví dụ: "Tại sao protein quan trọng?", "Cách đọc nhãn thực phẩm"). Mỗi card có nội dung tóm tắt, quick tips, và **quiz** để kiểm tra hiểu biết.

Mục tiêu: gamification + giáo dục dinh dưỡng, tăng engagement.

---

## 2. Business Rules

- Cards được **cá nhân hóa** dựa trên health profile và nutrition issues của user (recommendation engine).
- User có thể **save, dismiss, read** cards.
- Quiz submit trả về feedback + bonus points.
- Points system khuyến khích user hoàn thành cards.
- Categories: Protein, Sodium, Allergy, Hydration, General.

---

## 3. API Endpoints

### 3.1 Card Discovery & Browse

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/MicroLearnings/cards/recommended` | Cards được cá nhân hóa cho user |
| `GET` | `/api/MicroLearnings/cards/{id}` | Chi tiết card (nội dung + quiz) |
| `GET` | `/api/MicroLearnings/categories` | Danh mục topics (cho browse) |

### 3.2 User Card Actions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/MicroLearnings/cards/{id}/action` | Ghi nhận action (read, save, unsave, dismiss) |
| `GET` | `/api/MicroLearnings/cards/saved` | Danh sách cards đã lưu |

### 3.3 Quiz

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/MicroLearnings/cards/{id}/quiz/submit` | Submit đáp án quiz, nhận feedback + points |

**Tổng user-facing: 6 endpoint.**

### 3.3 Admin Micro-Learning (AdminMicroLearningController — AdminOnly)

|| Method | Endpoint | Description |
||--------|----------|-------------|
|| `GET` | `/api/admin/micro-learning/cards` | List all cards (paginated) |
|| `GET` | `/api/admin/micro-learning/cards/{id}` | Get card by id |
|| `POST` | `/api/admin/micro-learning/cards` | Create card |
|| `PUT` | `/api/admin/micro-learning/cards/{id}` | Update card |
|| `DELETE` | `/api/admin/micro-learning/cards/{id}` | Delete card |
|| `GET` | `/api/admin/micro-learning/categories` | List categories |

**Tổng system: 13 endpoint** (6 user-facing + 7 admin).

---

## 4. UI Components

Chưa có Flutter UI. Cần phát triển:

- Recommended cards feed
- Card detail view (content + tips + quiz)
- Saved cards screen
- Category browse screen
- Quiz interaction UI
- Points/progress display

---

## 5. Relationship with Other Modules

- `recommended` dùng `HealthProfile` và `NutritionTracking` để cá nhân hóa.
- Points ghi vào `UserAiProfile` hoặc bảng riêng.
- Admin CRUD của cards qua `AdminMicroLearningController` (đã có).

---

## 6. Notes

- Micro-Learning là gamification layer cho user engagement.
- AdminMicroLearningController cho phép CRUD cards (Admin only).
- Có thể tích hợp vào Home tab như một feed nhỏ.
