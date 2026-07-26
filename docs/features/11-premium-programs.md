# 11. Premium Programs (Catalog)

**Status:** Deprecated / Removed Phase 8
**Last updated:** 2026-07-24

**Related controller:** `backend/MenuGreen.API/Controllers/PremiumProgramsController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/PremiumProgramService.cs`

**Related Flutter features:** Catalog UI đã được gỡ (Phase 8). Đi đến
`docs/features/15-pt-review.md` để xem flow **Lộ trình Gymer** mới (2 tab:
"Tôi gửi PT" và "PT gửi tôi"), thay thế hoàn toàn catalog cũ.

---

## 1. Lý do deprecated (Phase 8)

- Catalog `premium_programs` (seed file `51_premium_programs.sql`) và bảng
  enrollment `user_premium_programs` (seed file `52_user_premium_programs.sql`)
  đã được **làm trống seed**. Không còn chương trình catalog mẫu nào.
- UI mua "Chương trình Premium" đã được gỡ khỏi tab "Lộ trình Gymer".
- Personal journey giữa Gymer ↔ Coach giờ chạy qua entity chung
  `pt_review_requests` với `CreatedByRole ∈ {"Gymer", "Coach"}` — xem
  `15-pt-review.md` §8 (PersonalProgram).

## 2. Schema vẫn còn (để tương thích cũ)

Hai bảng `premium_programs` và `user_premium_programs` vẫn tồn tại trong DB.
Phase 9+ có thể drop nếu user yêu cầu, nhưng hiện không dùng cho UI mới.

---

## 3. Lịch sử

| Ngày       | Phiên bản | Ghi chú                                                                          |
|------------|-----------|----------------------------------------------------------------------------------|
| 2026-07-09 | 1.0       | API đầy đủ (CRUD + checkout/checkin/graduate).                                   |
| 2026-07-24 | 2.0       | **Deprecated.** Seed wipe, UI gỡ. Chuyển sang flow `pt_review_requests`.         |


---

## 2. Business Rules

- User mua chương trình qua SePay QR, sau đó `activate` khi thanh toán thành công.
- Mỗi chương trình có N tuần. Mỗi tuần user phải **check-in** (gửi weight + body fat).
- Milestone = goal nhỏ cuối mỗi tuần.
- Sau tuần cuối cùng, user có thể yêu cầu **graduation**.
- Progress trend theo dõi thay đổi weight/body fat trong suốt chương trình.
- Wrap-up report tổng kết toàn bộ hành trình.
- Mỗi user chỉ có **1 active program** tại một thời điểm.

---

## 3. API Endpoints

### 3.1 Public — Program Discovery

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/PremiumPrograms` | Danh sách programs active (AllowAnonymous) |
| `GET` | `/api/PremiumPrograms/{id}` | Chi tiết program (AllowAnonymous) |

### 3.2 User — Purchase & Activation

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/PremiumPrograms/{id}/checkout` | Tạo yêu cầu mua qua SePay QR |
| `POST` | `/api/PremiumPrograms/{id}/activate` | Kích hoạt program sau khi thanh toán thành công |

### 3.3 User — Active Program Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/PremiumPrograms/my-active` | Program đang active hiện tại |
| `GET` | `/api/PremiumPrograms/my-programs` | Lịch sử tất cả programs đã tham gia |
| `GET` | `/api/PremiumPrograms/my-active/milestones` | Milestones của tuần hiện tại |
| `POST` | `/api/PremiumPrograms/my-active/milestones/{weekNumber}/checkin` | Check-in weight + body fat cho tuần N |
| `GET` | `/api/PremiumPrograms/my-active/progress-trend` | Trend weight/body fat trong chương trình |
| `POST` | `/api/PremiumPrograms/my-active/graduate` | Yêu cầu graduation sau tuần cuối |
| `GET` | `/api/PremiumPrograms/my-active/wrap-up-report` | Báo cáo tổng kết hành trình |

**Tổng: 11 endpoint.**

---

## 4. UI Components

Chưa có Flutter UI. Cần phát triển:

- Program catalog screen
- Program detail + checkout screen
- My programs / active program screen
- Weekly check-in flow
- Progress dashboard
- Graduation screen

---

## 5. Relationship with Other Modules

- `checkout` tạo SePay order → tích hợp `SepayController`.
- Check-in dùng weight từ `NutritionTrackingController`.
- Graduation ghi vào `ActivityLog` (Analytics).

---

## 6. Notes

- Khác `SubscriptionPlan` (08): Subscription = thuê bao tính năng; Premium Programs = chương trình có lộ trình, milestone, graduation.
- Program check-in data độc lập với daily weight log — user có thể check-in nhiều lần/tuần.
