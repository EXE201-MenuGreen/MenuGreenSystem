# 11. Premium Programs

**Status:** API Done · UI Not Done
**Last updated:** 2026-07-09

**Related controller:** `backend/MenuGreen.API/Controllers/PremiumProgramsController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/PremiumProgramService.cs`

**Related Flutter features:** Chưa có

---

## 1. Overview

Chương trình Premium có cấu trúc (structured Premium programs) — khác với `SubscriptionPlan` chỉ là gói thuê bao, `PremiumPrograms` là các chương trình có **lộ trình theo tuần** với milestone, check-in, và graduation.

Mục tiêu: tạo động lực cho user cam kết theo chương trình dài hạn (ví dụ: "Giảm 5kg trong 8 tuần"), thay vì chỉ subscribe để unlock tính năng.

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
