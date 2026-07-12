# 14. Adaptive Reminders

**Status:** API Done · UI Done
**Last updated:** 2026-07-12

**Related controller:** `backend/MenuGreen.API/Controllers/ReminderController.cs`
**Related service:** `backend/MenuGreen.BusinessLogicLayer/Services/ReminderService.cs`
**Related dispatcher:** `backend/MenuGreen.BusinessLogicLayer/Services/NotificationDispatcherService.cs`

**Related Flutter features:** **UI DONE**

- `frontend/lib/features/adaptive_reminders/views/adaptive_reminders_screen.dart` - profile giờ ăn, lịch reminder, tạo/sửa/bật-tắt/xóa/snooze.
- `frontend/lib/features/adaptive_reminders/repositories/reminder_repository.dart` - kết nối toàn bộ 8 endpoint Reminder.
- `frontend/lib/features/adaptive_reminders/models/reminder_models.dart` - model profile và scheduled reminder.
- `frontend/lib/features/profile/views/profile_view.dart` - entry point `Nhắc nhở thông minh`.

---

## 1. Overview

Adaptive Reminders quản lý thời điểm nhắc ăn và lịch nhắc tùy chỉnh. Khác với `NotificationController`, feature này quản lý **khi nào nhắc** và cấu hình giờ ăn tối ưu; notification dispatcher chịu trách nhiệm gửi in-app/push khi reminder đến hạn.

Hệ thống có thể phân tích meal log để xác định giờ ăn thường dùng của user, sau đó user vẫn có thể chỉnh thủ công.

---

## 2. Business Rules

- Reminder profile lưu giờ Sáng, Trưa và Tối của user.
- Recalculate tính trung bình thời gian của `MealLog` theo `MealType`; không có dữ liệu thì dùng 08:00, 12:00 và 19:00.
- Scheduled reminder là notification có `ScheduledAt` trong tương lai.
- User có thể tạo, sửa nội dung/thời gian, bật/tắt, xóa và snooze reminder.
- Snooze nhận 1-1440 phút; mặc định API là 15 phút.
- Reminder bị tắt dùng tiền tố `DISABLED_` và bị notification dispatcher loại khỏi danh sách gửi.

---

## 3. API Endpoints

Base route thực tế là `/api/Reminder` (số ít, theo `[controller]`).

### 3.1 Reminder Profile

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Reminder/profile` | Lấy cấu hình giờ ăn hiện tại |
| `PUT` | `/api/Reminder/profile` | Cập nhật thủ công giờ Sáng/Trưa/Tối |
| `POST` | `/api/Reminder/profile/recalculate` | Tự tính giờ tối ưu từ meal log |

### 3.2 Scheduled Reminders CRUD

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/Reminder/scheduled` | Danh sách reminder chưa gửi và còn ở tương lai |
| `POST` | `/api/Reminder/scheduled` | Tạo reminder tùy chỉnh |
| `PATCH` | `/api/Reminder/scheduled/{id}` | Cập nhật nội dung, giờ hoặc trạng thái bật/tắt |
| `DELETE` | `/api/Reminder/scheduled/{id}` | Xóa reminder |

### 3.3 Reminder Actions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/Reminder/scheduled/{id}/snooze?minutes=15` | Dời reminder thêm N phút |

**Tổng: 8 endpoint.**

---

## 4. UI Components

### Implementation checklist

- [x] Màn hình Reminder Profile hiển thị giờ Sáng/Trưa/Tối.
- [x] Chọn giờ thủ công bằng native time picker và lưu qua `PUT /profile`.
- [x] Nút tự tính giờ từ lịch sử meal log qua `POST /profile/recalculate`.
- [x] Danh sách scheduled reminder với trạng thái bật/tắt và refresh.
- [x] Bottom sheet tạo/sửa reminder: tiêu đề, nội dung, ngày và giờ.
- [x] Toggle bật/tắt reminder qua `PATCH /scheduled/{id}`.
- [x] Snooze 15 hoặc 30 phút và xóa có confirm dialog.
- [x] Entry point từ Profile.

---

## 5. Relationship with Other Modules

- `recalculate` đọc `MealLog` từ Nutrition Tracking.
- Scheduled reminder lưu trên entity `Notification` và được `NotificationDispatchBackgroundService` xử lý mỗi phút.
- Dispatcher gửi SignalR in-app khi được bật, và gửi FCM khi `PushEnabled` cùng device token hợp lệ.
- Notification Settings vẫn quản lý channel push/in-app; Adaptive Reminders quản lý giờ và lịch nhắc.

---

## 6. Verification & Assessment

- [x] `dotnet build backend/MenuGreen.API/MenuGreen.API.csproj --no-restore` thành công, không có error.
- [x] `flutter analyze` cho adaptive reminders, Profile và API endpoints không có error.
- [x] Đã kiểm tra luồng dispatcher và sửa lỗi reminder bị tắt vẫn có thể bị gửi.
- [x] API chặn tạo/sửa reminder ở quá khứ và snooze ngoài khoảng 1-1440 phút.
- [ ] Chưa chạy end-to-end với access token user thật, database thật và thiết bị nhận push.

Đánh giá: phần cấu hình và scheduled reminder đã hoàn thành về mặt UI/API contract. Để xác nhận delivery notification ngoài production, cần kiểm thử một reminder thời điểm gần với `PushEnabled`, FCM device token và SignalR đang kết nối. Khi app không chạy hoặc không có token thiết bị, reminder vẫn được đánh dấu đã xử lý nhưng không thể xác nhận push được hiển thị trên thiết bị.

## 7. Notes

- Reminder quản lý "khi nào nhắc"; Notification quản lý kênh gửi và inbox.
- Snooze thay đổi thời gian của reminder hiện tại, không tạo lịch lặp lại.
- Recalculate hiện dùng trung bình tất cả meal log theo từng bữa; chưa loại bỏ outlier hoặc giới hạn khoảng thời gian lịch sử.
