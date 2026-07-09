# 14. Adaptive Reminders

**Status:** API Done · UI Not Done
**Last updated:** 2026-07-09

**Related controller:** `backend/MenuGreen.API/Controllers/ReminderController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/ReminderService.cs`

**Related Flutter features:** Chưa có

---

## 1. Overview

Adaptive Reminders quản lý **reminder thông minh** cho việc ăn uống — khác với `NotificationController` (gửi notification), `ReminderController` quản lý **cấu hình reminder** và **optimal meal time** của user.

Hệ thống phân tích lịch sử meal log để tự động tính giờ ăn tối ưu của user (ví dụ: thường ăn sáng 7h30, trưa 12h15). Sau đó gửi reminder đúng thời điểm.

---

## 2. Business Rules

- **Reminder Profile**: lưu preferred meal times (breakfast, lunch, dinner, snack windows).
- **Auto-recalculate**: phân tích meal log history → cập nhật preferred times tự động.
- **Scheduled Reminders**: user tạo custom reminder (time, message, enabled/disabled).
- **Snooze**: nhắc lại sau N phút (default 15).
- Khác `NotificationController`: Reminder = cấu hình thời gian + logic; Notification = gửi push.

---

## 3. API Endpoints

### 3.1 Reminder Profile

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Reminders/profile` | Lấy cấu hình reminder profile hiện tại |
| `PUT` | `/api/Reminders/profile` | Cập nhật thủ công preferred meal times |
| `POST` | `/api/Reminders/profile/recalculate` | Tự động tính optimal meal times từ meal log history |

### 3.2 Scheduled Reminders CRUD

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Reminders/scheduled` | Danh sách reminders đã lên lịch |
| `POST` | `/api/Reminders/scheduled` | Tạo reminder mới |
| `PATCH` | `/api/Reminders/scheduled/{id}` | Cập nhật reminder (time, message, enabled) |
| `DELETE` | `/api/Reminders/scheduled/{id}` | Xóa reminder |

### 3.3 Reminder Actions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Reminders/scheduled/{id}/snooze` | Snooze reminder N phút (default 15) |

**Tổng: 8 endpoint.** *(Update 2026-07-09: sửa count 7 -> 8, xác nhận 8 HTTP methods trong code)*

---

## 4. UI Components

Chưa có Flutter UI. Cần phát triển:

- Reminder profile screen (preferred meal times)
- Scheduled reminders list
- Create/edit reminder modal
- Auto-recalculate trigger button

---

## 5. Relationship with Other Modules

- `recalculate` đọc từ `NutritionTracking` (meal logs) để phân tích.
- Reminders gửi notification thông qua `NotificationController`.
- Có thể tích hợp với `DailyStarterController` cho "remind breakfast" workflow.

---

## 6. Notes

- Tách biệt khỏi `NotificationController`: Reminder quản lý "khi nào nhắc", Notification gửi notification.
- Snooze là temporary delay — không thay đổi lịch reminder gốc.
- Optimal meal time calculation nên chạy background job (JobTriggerController).
