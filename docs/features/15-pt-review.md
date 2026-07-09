# 15. PT Review

**Status:** API Done · UI Not Done
**Last updated:** 2026-07-09

**Related controller:** `backend/MenuGreen.API/Controllers/PtReviewController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/PtReviewService.cs`

**Related Flutter features:** Chưa có

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

Chưa có Flutter UI. Cần phát triển:

- Create review request screen
- My requests list screen
- Review result view
- PT-facing report page (web-friendly, mobile-responsive — vì PT không cần login)

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
