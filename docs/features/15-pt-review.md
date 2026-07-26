# 15. PT Review

**Status:** API Done · UI Done · **Assessment: DONE**
**Last updated:** 2026-07-24

**Related controller:** `backend/MenuGreen.API/Controllers/PtReviewController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/PtReviewService.cs`

**Related Flutter features:** `frontend/lib/features/advanced/` — user request/result/apply/reject và PT guest review bằng share token.

---

## 1. Overview

PT Review cho phép user **nhờ PT (Personal Trainer) review** bữa ăn hàng tuần của mình. User tạo weekly report → chia sẻ link cho PT → PT xem và gửi feedback + menu/calorie adjustment → user approve hoặc reject.

Khác với `CoachesController`: Coaches = hệ sinh thái kết nối dài hạn với coach; PT Review = workflow one-time/request-based cho bất kỳ PT nào (không cần kết nối trong app).

---

## 2. Business Rules

- User tạo weekly report → hệ thống tạo **shareable token link** (không cần PT đăng nhập).
- PT xem report qua link (AllowAnonymous), submit feedback + menu suggestions.
- User nhận notification khi PT gửi review.
- User có thể **apply** suggestions (cập nhật meal plan + calorie targets) hoặc **reject**.
- Mỗi request có trạng thái: pending → reviewed → applied/rejected.

---

## 3. API Endpoints

### 3.1 Student — Create & Manage Requests

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/PtReview/reports` | Tạo weekly report + shareable link |
| `GET` | `/api/PtReview/my-requests` | Danh sách requests đã tạo |
| `GET` | `/api/PtReview/requests/{requestId}/result` | Xem kết quả PT feedback |
| `POST` | `/api/PtReview/requests/{requestId}/apply` | Apply PT suggestions (cập nhật plan + targets) |
| `POST` | `/api/PtReview/requests/{requestId}/reject` | Reject và đóng request |

### 3.2 PT / Guest — View & Submit Review

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/PtReview/shared-reports/{token}` | Xem report qua shareable token (AllowAnonymous) |
| `POST` | `/api/PtReview/shared-reports/{token}/submit` | PT gửi feedback + suggestions (AllowAnonymous) |

**Tổng: 7 endpoint.**

---

## 4. UI Components

Flutter UI đã triển khai:

- Create review request screen
- My requests list screen
- Review result view
- PT-facing report page theo share token, không yêu cầu login

---

## 5. Relationship with Other Modules

- Weekly report chứa nutrition summary → từ `NutritionTrackingController`.
- `apply` → cập nhật `MealPlan` và `HealthProfile` targets.
- Feedback notification → `NotificationController`.
- PT xem student data nhưng không qua `CoachesController` (token-based, không kết nối).

---

## 6. Notes

- Token-based sharing (no login required for PT) giúp PT ngoài hệ thống cũng có thể review.
- Shared report URL nên có expiry.
- Apply review tự động recalculate calorie targets → trigger notification.

## 7. Verification & Assessment (2026-07-12)

- [x] Đã có Flutter UI tạo báo cáo tuần, tải danh sách request, apply/reject.
- [x] Repository đã nối đủ endpoint phía user và có xử lý lỗi HTTP.
- [x] Có màn hình guest mở report theo share token, xem thông tin tuần và submit feedback/calo/protein suggestion không cần đăng nhập.
- [x] PT có thể thêm nhiều menu suggestion theo ngày/bữa/action/ghi chú; user xem lại đầy đủ các thay đổi trước khi apply/reject.
- [ ] Chưa kiểm thử end-to-end với user/PT thật và database thật.

**Đánh giá: DONE.** Luồng user tạo/xem/apply/reject và luồng PT guest mở link/submit review đã khép kín theo API contract. E2E với dữ liệu production vẫn là bước smoke test trước phát hành, không còn là phần implementation thiếu.

---

## 8. PersonalProgram (PT → Gymer direction) — Phase 8

Phase 8 mở rộng cùng entity `pt_review_requests` cho hướng ngược lại: **PT chủ động gửi lộ trình cá nhân cho Gymer đã kết nối**, Gymer xem và chấp nhận/từ chối.

### 8.1 Phân biệt 2 hướng bằng `CreatedByRole`

| `CreatedByRole` | Hướng            | Tab trên UI           | Trigger                                |
|-----------------|------------------|-----------------------|----------------------------------------|
| `"Gymer"`       | Gymer → PT       | "Tôi gửi PT"          | `POST /api/PtReview/reports` (RouteApproval / WeeklyReport) |
| `"Coach"`       | PT → Gymer       | "PT gửi tôi"          | `POST /api/PtReview/coach/personal-programs` (PersonalProgram) |

### 8.2 New columns (Phase 8 migration `AddPersonalProgramSupport`)

| Column            | Type         | Purpose                                                  |
|-------------------|--------------|----------------------------------------------------------|
| `CreatedByRole`   | varchar(20)  | `"Gymer"` (default cho rows cũ) hoặc `"Coach"`           |
| `AcceptedAt`      | timestamptz? | Timestamp khi Gymer accept PersonalProgram                |
| `AcceptedByUserId`| uuid?        | Audit (luôn trùng với `UserId` của Gymer đó)              |

Partial unique index: `IX_pt_review_requests_CreatedByRole_Status_Pending`
- Đảm bảo mỗi Gymer chỉ có tối đa 1 PersonalProgram `Pending` từ Coach (cho phép
  nhiều rows đã terminal để audit).

### 8.3 API endpoints mới

| Method | Endpoint                                                       | Role          | Mục đích                                |
|--------|----------------------------------------------------------------|---------------|-----------------------------------------|
| `POST` | `/api/PtReview/coach/personal-programs`                        | `CoachOnly`   | PT tạo + gửi PersonalProgram cho Gymer |
| `GET`  | `/api/PtReview/coach/personal-programs?clientId=...`           | `CoachOnly`   | PT xem các PersonalProgram đã gửi       |
| `GET`  | `/api/PtReview/my-personal-programs`                           | Authenticated | Gymer xem các chương trình PT gửi mình |
| `POST` | `/api/PtReview/personal-programs/{requestId}/accept`           | Authenticated | Gymer chấp nhận PersonalProgram         |

### 8.4 Business rules

- PT phải có `CoachConnection` với client, status = `Connected`.
- Mỗi Gymer chỉ có **1 PersonalProgram Pending** tại một thời điểm (DB enforced).
- Khi Gymer accept:
  - `Status = "Accepted"`, `AcceptedAt = now`, `AcceptedByUserId = gymerId`.
  - Các target (`SuggestedCalorieTarget`, `SuggestedProteinTarget`, …) được apply
    vào `HealthProfile` của Gymer (nếu HealthProfile tồn tại).
  - Gửi notification cho Gymer xác nhận (handled trước đó khi PT tạo program).
- Chưa có flow tự động generate `MealPlan` từ PersonalProgram (Phase 9+).

### 8.5 Flutter UI

File: `frontend/lib/features/gymer/views/premium_programs_screen.dart`
(đã refactor thành `DefaultTabController` length=2):

- Tab "**Tôi gửi PT**" — gọi `GET /api/PtReview/my-requests`, filter
  `requestType in ["", "RouteApproval", "WeeklyReport"]` (= `CreatedByRole == "Gymer"`).
  Nút "Áp dụng gợi ý" xuất hiện khi `Status == "Reviewed"`.
- Tab "**PT gửi tôi**" — gọi `GET /api/PtReview/my-personal-programs`
  (= `CreatedByRole == "Coach"`).
  Tap card mở `PersonalProgramDetailScreen` với button "Chấp nhận lộ trình".

Widget chia sẻ: `frontend/lib/features/gymer/widgets/route_approval_card.dart`
(cùng layout cho 2 tab, khác action).

### 8.6 i18n mapping (mới thêm vào `ApiMessageTranslator`)

- `"Personal program does not exist."` → "Không tìm thấy lộ trình cá nhân."
- `"This request was not sent by your coach."` → "Yêu cầu này không được gửi từ PT của bạn."
- `"Personal program has already been processed."` → "Lộ trình cá nhân đã được xử lý."
- `"You are not connected with this client."` → "Bạn chưa kết nối với khách hàng này."
- `"Client already has a pending personal program. Please wait for them to respond before sending a new one."`
  → "Khách hàng đang có lộ trình cá nhân chờ phản hồi. Vui lòng chờ họ xử lý trước khi gửi lộ trình mới."

### 8.7 SQL migration cho production

File idempotent: `backend/database/54_pt_review_personal_program.sql`
- `ALTER TABLE pt_review_requests ADD COLUMN IF NOT EXISTS ...`
- `CREATE UNIQUE INDEX IF NOT EXISTS ...`

Áp dụng: `psql -f backend/database/54_pt_review_personal_program.sql`.

### 8.8 Out of scope (Phase 9+)

- UI PT-side để tạo PersonalProgram (hiện tại dùng API trực tiếp hoặc admin tool).
- Auto-generate MealPlan từ PersonalProgram sau khi Gymer Accept.
- Realtime notification khi nhận PersonalProgram mới (hiện đã có notification async).
