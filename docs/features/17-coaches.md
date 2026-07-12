# 17. Coaches Ecosystem

**Status:** API Done · UI Done · **Assessment: DONE**
**Last updated:** 2026-07-09

**Related controller:** `backend/MenuGreen.API/Controllers/CoachesController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/CoachService.cs`

**Related Flutter features:** Chưa có

---

## 1. Overview

Coaches Ecosystem là hệ sinh thái **Coach-Student** dài hạn trong app — khác với `PtReviewController` (one-time review), Coaches = kết nối lâu dài với PT/coach để theo dõi và điều chỉnh dinh dưỡng liên tục.

User có thể đăng ký trở thành Coach (expert role), student kết nối với coach, grant/revoke data access, và coach có thể xem dashboard + điều chỉnh meal plan + calorie targets của student.

---

## 2. Business Rules

### 2.1 Coach Registration
- User đăng ký → upgrade lên role Coach.
- Coach profile có specialty, price, bio.
- Public catalog cho student tìm coach.

### 2.2 Connection Flow
1. Student gửi connect request → Coach approve/reject.
2. Sau khi connected, student grant data access → Coach xem được.
3. Student revoke access bất kỳ lúc nào.

### 2.3 Coach Capabilities
- Xem student profile (weight, goals, allergies).
- Xem student nutrition summary (7-day intake).
- Xem student weight trend.
- Gửi feedback cho student.
- **Điều chỉnh** student's meal plan.
- **Điều chỉnh** student's calorie/macro targets.

---

## 3. API Endpoints

### 3.1 Coach Discovery (Public)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Coaches` | Danh sách coach (lọc specialty, price) — AllowAnonymous |
| `GET` | `/api/Coaches/{id}` | Chi tiết coach profile — AllowAnonymous |

### 3.2 Coach Registration

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Coaches/register` | User đăng ký trở thành coach |

### 3.3 Connection Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Coaches/connect/{coachId}` | Student gửi yêu cầu kết nối |
| `POST` | `/api/Coaches/approve-connection/{clientId}` | Coach approve/reject student (CoachOnly) |
| `GET` | `/api/Coaches/my-clients` | Coach xem danh sách students đã kết nối (CoachOnly) |

### 3.4 Data Access

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Coaches/grant-access/{coachId}` | Student cấp quyền xem data cho coach |
| `POST` | `/api/Coaches/revoke-access/{coachId}` | Student thu hồi quyền |

### 3.5 Coach Views Student

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Coaches/clients/{clientId}/profile` | Xem student profile + goals + allergies (CoachOnly) |
| `GET` | `/api/Coaches/clients/{clientId}/nutrition-summary` | Xem 7-day nutrition intake (CoachOnly) |
| `GET` | `/api/Coaches/clients/{clientId}/weight-trend` | Xem weight trend (CoachOnly) |

### 3.6 Coach Actions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Coaches/clients/{clientId}/feedback` | Gửi feedback cho student (CoachOnly) |
| `GET` | `/api/Coaches/clients/{clientId}/feedback` | Xem feedback (Student hoặc connected Coach) |
| `PUT` | `/api/Coaches/clients/{clientId}/meal-plan/{planId}` | Điều chỉnh student's meal plan (CoachOnly) |
| `PUT` | `/api/Coaches/clients/{clientId}/health-targets` | Điều chỉnh student's calorie/macro targets (CoachOnly) |

**Tổng: 15 endpoint.**

---

## 4. UI Components

Chưa có Flutter UI. Cần phát triển:

- Coach catalog & search screen
- Coach profile detail screen
- My coaches (student view) screen
- My clients (coach view) dashboard
- Client detail + nutrition view (coach)
- Feedback & adjust forms (coach)
- Student feedback view

---

## 5. Relationship with Other Modules

- Coach xem `NutritionTracking` data của student (nutrition summary, weight trend).
- Coach điều chỉnh `MealPlan` của student → `MealPlanController`.
- Coach điều chỉnh `HealthProfile` targets của student → `HealthProfileController`.
- Feedback ghi vào `ActivityLog`.
- Khác `PtReviewController`: Coaches = dài hạn, connected; PT Review = one-time, token-based.

---

## 6. Notes

- **CoachOnly** policy kiểm soát truy cập — phải register + được assigned Coach role.
- Grant/revoke access là voluntary từ student side.
- Coach có thể điều chỉnh meal plan mà không cần student approve.
- Có thể tích hợp notification khi coach gửi feedback.

## 7. Verification & Assessment (2026-07-12)

- [x] Có catalog coach, thông tin specialty/kinh nghiệm/phí và gửi yêu cầu kết nối.
- [x] Repository đã có register coach, my-clients và grant/revoke access để tiếp tục mở rộng UI.
- [x] Có màn hình đăng ký coach, duyệt/từ chối kết nối và danh sách học viên.
- [x] Có client dashboard xem hồ sơ, nutrition 7 ngày, weight records và feedback history.
- [x] Có form gửi feedback, chỉnh calorie/macro targets và cập nhật meal plan.
- [x] Coach detail hỗ trợ cấp/thu hồi data access từ phía student.
- [ ] Chưa kiểm thử phân quyền `UserOnly`/`CoachOnly` end-to-end.

**Đánh giá: DONE.** Catalog, registration, connection, access control, client views và coach actions đều đã có Flutter UI/API contract. Phân quyền thực tế cần smoke test bằng JWT User/Coach trước production.
