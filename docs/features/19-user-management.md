# 19. User Management

**Status:** API Done · UI Done · **Assessment: DONE**
**Last updated:** 2026-07-09

**Related controller:** `backend/MenuGreen.API/Controllers/UserController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/UserService.cs`

**Related Flutter features:** Chưa có (User-facing part nằm trong Profile feature)

---

## 1. Overview

User Management cung cấp:

1. **User-facing**: Đổi mật khẩu cho authenticated user.
2. **Admin-facing**: CRUD users trong hệ thống (list, view, toggle status, lock, unlock, assign role).

Khác với `ProfileController`: Profile = thông tin hiển thị (name, avatar, health data); UserController = quản lý account + security (password, role, status).

---

## 2. Business Rules

- `change-password` là endpoint duy nhất cho user thường — yêu cầu mật khẩu hiện tại.
- Admin có thể list all users, toggle active/locked status.
- Locked user không thể đăng nhập.
- Role assignment (Admin, User, Coach) kiểm soát policy.

---

## 3. API Endpoints

### 3.1 User (Authenticated)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `PUT` | `/api/User/change-password` | Đổi mật khẩu (yêu cầu current password) |

### 3.2 Admin

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/User` | Danh sách tất cả users |
| `GET` | `/api/User/{id}` | Chi tiết user |
| `PUT` | `/api/User/{id}/toggle-status` | Toggle active/inactive *(code: cả PATCH và PUT variants)* |
| `PUT` | `/api/User/{id}/lock` | Lock user (không đăng nhập được) *(code: cả PATCH và PUT variants)* |
| `PUT` | `/api/User/{id}/unlock` | Unlock user *(code: cả PATCH và PUT variants)* |
| `PUT` | `/api/User/{id}/assign-role` | Gán role cho user (Admin/User/Coach) *(code: cả PATCH và PUT variants)* |

> **Ghi chú:** Controller đăng ký cả `PATCH` và `PUT` cho 4 admin endpoints (toggle-status, lock, unlock, assign-role). Cả 2 HTTP methods cùng handler. Doc liệt kê PUT cho đơn giản.

**Tổng: 7 endpoint** (1 user + 6 admin — PATCH variants là superset, không tăng count).

---

## 4. UI Components

- User-facing: `ChangePasswordScreen` trong Profile feature (đã có).
- Admin-facing: User management trong Admin Panel (chưa có).

---

## 5. Relationship with Other Modules

- Role assignment quyết định policy (`UserOnly`, `CoachOnly`, `AdminOnly`).
- Lock/unlock affects JWT authentication.
- User data cơ bản (email, role) nằm trong `User` entity.

---

## 6. Notes

- Change password có thể gọi từ Profile screen (hiện đã có Flutter UI).
- Admin user management có thể tích hợp vào existing Admin Panel nếu có.

## 7. Verification & Assessment (2026-07-12)

- [x] User có màn hình đổi mật khẩu hiện hữu.
- [x] Admin có danh sách user, bật/tắt, lock/unlock và gán role User/Coach/Admin.
- [x] Non-admin nhận màn hình giải thích quyền truy cập thay vì crash.
- [x] Đã sửa route tài liệu từ `/api/Users` sang route controller thực tế `/api/User`.
- [x] Flutter analyzer không có error/warning cho feature.

**Đánh giá: DONE** về UI/API contract. Cần smoke test thêm với JWT Admin thật trước khi phát hành production.
