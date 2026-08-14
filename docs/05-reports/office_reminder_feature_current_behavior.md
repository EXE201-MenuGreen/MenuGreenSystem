# Tính năng nhắc nhở của gói Office — Hoạt động hiện tại

## 1. Mục đích tài liệu

Tài liệu mô tả đúng hành vi đang được triển khai trong source code của MenuGreen tại thời điểm kiểm tra. Nội dung phân biệt rõ:

- Điểm truy cập từ gói Office.
- Hồ sơ giờ ăn thông minh.
- Lịch nhắc tùy chỉnh.
- Hai preset dành cho môi trường văn phòng.
- Cách backend phát và lặp lại thông báo.
- Những giới hạn hoặc chênh lệch giữa tên gọi sản phẩm và hành vi thực tế.

## 2. Tóm tắt hoạt động

Từ “Không gian Office”, người dùng chọn **Nhắc nhở** hoặc **Nhắc nhở văn phòng** để mở màn hình dùng chung `AdaptiveRemindersScreen` có tiêu đề **Nhắc nhở thông minh**.

Màn hình gồm hai phần độc lập:

1. **Giờ ăn ưu tiên:** lưu giờ ăn sáng, trưa và tối; có thể nhập thủ công hoặc tính lại từ lịch sử nhật ký ăn uống.
2. **Lịch nhắc tùy chỉnh:** tạo, sửa, bật/tắt, hoãn và xóa lịch thông báo. Office cung cấp thêm hai nút tạo nhanh: uống nước mỗi 2 giờ và vận động/giãn cơ mỗi 1 giờ.

Backend kiểm tra lịch đến hạn mỗi phút. Khi đến giờ, hệ thống có thể gửi notification trong ứng dụng qua SignalR và push notification qua FCM tùy cài đặt người dùng. Lịch lặp tạo một bản ghi lịch kế tiếp sau khi bản hiện tại được xử lý.

## 3. Điểm truy cập trên frontend

Tính năng được mở từ hai vị trí của Office:

- `OfficeHomePanel`: shortcut **Nhắc nhở**.
- `OfficeWorkspaceScreen`: mục **Nhắc nhở văn phòng**, mô tả “Nhắc uống nước, giãn cơ và giờ ăn”.

Cả hai đều điều hướng đến cùng một `AdaptiveRemindersScreen`.

Màn hình này cũng đang được liên kết từ trang Profile. Vì vậy, trong trạng thái code hiện tại, đây chưa phải màn hình dành riêng cho Office.

## 4. Khi màn hình được mở

Frontend gửi song song hai request:

```http
GET /api/Reminder/profile
GET /api/Reminder/scheduled
```

- Request thứ nhất lấy hồ sơ giờ ăn tối ưu.
- Request thứ hai lấy các notification của người dùng có `ScheduledAt` trong tương lai và chưa được gửi (`SentAt == null`).
- Màn hình hiển thị loading trong lúc chờ cả hai request.
- Nếu một trong hai request lỗi, toàn bộ lần tải được xem là thất bại và giao diện cho phép thử lại hoặc kéo để refresh.

Khi người dùng chưa có `ReminderProfile`, backend tự tạo hồ sơ mặc định:

| Bữa ăn | Giờ mặc định |
|---|---:|
| Sáng | 08:00 |
| Trưa | 12:00 |
| Tối | 19:00 |

## 5. Hồ sơ giờ ăn ưu tiên

### 5.1 Chỉnh thủ công

Người dùng chọn giờ cho từng bữa bằng time picker rồi bấm **Lưu giờ ăn**.

Frontend gửi:

```http
PUT /api/Reminder/profile
```

Payload:

```json
{
  "optimalBreakfastTime": "08:00",
  "optimalLunchTime": "12:00",
  "optimalDinnerTime": "19:00"
}
```

Backend yêu cầu định dạng `HH:mm`, lưu vào bảng `reminder_profiles` và cập nhật `LastRecalculatedAt` bằng thời gian UTC hiện tại.

### 5.2 Tự tính từ nhật ký

Khi bấm **Tự tính từ nhật ký**, frontend gọi:

```http
POST /api/Reminder/profile/recalculate
```

Backendếu
1. Lấy toàn bộ meal log của người dùng.
2. Chia log theo `MealType`: `Breakfast`, `Lunch`, `Dinner`.
3. Với từng nhóm có `LoggedAt`, tính trung bình thời gian trong ngày.
4. Nếu một nhóm không có dữ liệu, dùng giờ mặc định 08:00, 12:00 hoặc 19:00.
5. Lưu kết quả vào `reminder_profiles`.

### 5.3 Ý nghĩa thực tế

Ba giờ này hiện chỉ là **hồ sơ thời điểm ăn ưu tiên**. Việc lưu hoặc tính lại hồ sơ **không tự tạo ba notification nhắc ăn**. Nếu muốn nhận thông báo vào các giờ đó, người dùng vẫn phải tạo lịch nhắc riêng.

## 6. Lịch nhắc tùy chỉnh

### 6.1 Tạo lịch

Người dùng bấm nút `+`, nhập:

- Tiêu đề.
- Nội dung.
- Ngày nhắc.
- Giờ nhắc.

Giá trị mặc định của form là:

- Tiêu đề: “Nhắc giờ ăn”.
- Nội dung: “Đến giờ ghi nhật ký bữa ăn.”
- Thời gian: sau thời điểm hiện tại một giờ.

Frontend chỉ cho lưu khi tiêu đề và nội dung không rỗng, đồng thời thời gian phải ở tương lai. Thời gian local được đổi sang UTC trước khi gửi backend.

```http
POST /api/Reminder/scheduled
```

Lịch mới được lưu vào bảng `notifications` với:

- `Type = CUSTOM_REMINDER` nếu không phải lịch lặp.
- `SentAt = null`.
- `IsRead = false`.
- `ScheduledAt` là thời điểm sẽ phát.

Backend cũng kiểm tra `ScheduledAt` phải lớn hơn thời gian UTC hiện tại.

### 6.2 Chỉnh sửa

Chạm vào một lịch mở lại editor. Người dùng có thể đổi tiêu đề, nội dung và thời gian.

```http
PATCH /api/Reminder/scheduled/{id}
```

Frontend hiện không cung cấp trường thay đổi chu kỳ lặp trong editor. Nếu sửa một preset lặp, chu kỳ cũ vẫn được giữ vì request không gửi `repeatIntervalMinutes`.

### 6.3 Bật hoặc tắt

Switch trên từng lịch gửi `isEnabled` đến API update.

- Khi tắt, backend thêm prefix `DISABLED_` vào `Notification.Type`.
- Background dispatcher bỏ qua các notification có type bắt đầu bằng `DISABLED_`.
- Khi bật lại, backend loại prefix này và lịch tiếp tục được xét khi đến hạn.

Việc tắt không xóa lịch khỏi database. API danh sách vẫn có thể trả lịch đã tắt nếu nó còn ở tương lai và chưa gửi, vì truy vấn danh sách không loại `DISABLED_`.

### 6.4 Nhắc lại sau

Menu của mỗi lịch cho phép:

- Nhắc lại sau 15 phút.
- Nhắc lại sau 30 phút.

```http
POST /api/Reminder/scheduled/{id}/snooze?minutes=15
```

Backend cộng số phút vào `ScheduledAt` hiện tại. API chấp nhận từ 1 đến 1.440 phút.

### 6.5 Xóa

Sau bước xác nhận, frontend gọi:

```http
DELETE /api/Reminder/scheduled/{id}
```

Backend kiểm tra lịch thuộc đúng người dùng rồi xóa vĩnh viễn bản ghi notification.

## 7. Hai preset Office

### 7.1 Uống nước mỗi 2 giờ

Khi bấm **Nước / 2 giờ**, frontend tạo ngay lịch:

```json
{
  "title": "Uống nước",
  "body": "Uống một cốc nước để duy trì tập trung.",
  "scheduledAt": "thời điểm hiện tại + 2 giờ",
  "type": "CUSTOM_REMINDER",
  "repeatIntervalMinutes": 120
}
```

### 7.2 Vận động mỗi giờ

Khi bấm **Giãn cơ / 1 giờ**, frontend tạo ngay lịch:

```json
{
  "title": "Vận động giãn cơ",
  "body": "Đứng dậy và đi bộ hoặc giãn cơ 5 phút.",
  "scheduledAt": "thời điểm hiện tại + 1 giờ",
  "type": "CUSTOM_REMINDER",
  "repeatIntervalMinutes": 60
}
```

Backend mã hóa lịch lặp vào `Notification.Type`:

```text
RECURRING:<số-phút>:<loại-gốc>
```

Ví dụ:

```text
RECURRING:120:CUSTOM_REMINDER
RECURRING:60:CUSTOM_REMINDER
```

Mỗi lần bấm preset tạo một lịch mới. Hiện chưa có bước kiểm tra trùng, nên người dùng có thể vô tình tạo nhiều lịch uống nước hoặc giãn cơ giống nhau.

## 8. Cơ chế phát thông báo

`NotificationDispatchBackgroundService` chạy liên tục trong backend với chu kỳ một phút.

Mỗi vòng chạy, dispatcher lấy các notification thỏa mãn:

- Chưa gửi: `SentAt == null`.
- Có lịch: `ScheduledAt != null`.
- Đã đến giờ: `ScheduledAt <= now`.
- Chưa dismiss.
- Không bị tắt bằng prefix `DISABLED_`.

Với mỗi notification:

1. Đọc `NotificationSetting` của người dùng.
2. Nếu `InAppEnabled`, gửi realtime qua SignalR và cập nhật unread count.
3. Nếu `PushEnabled`, gửi push qua Firebase Cloud Messaging.
4. Đánh dấu bản hiện tại đã gửi bằng `SentAt = UtcNow`.
5. Nếu là lịch lặp, tạo một notification mới cho lần kế tiếp.

Nếu server xử lý chậm hoặc bỏ lỡ nhiều chu kỳ, lần kế tiếp được cộng dồn cho tới khi nằm sau thời gian hiện tại. Hệ thống không phát bù mọi lần đã bỏ lỡ.

### Kênh mặc định

Theo entity hiện tại:

- `InAppEnabled` mặc định là `true`.
- `PushEnabled` mặc định là `false`.

Vì vậy người dùng có thể chỉ nhận notification trong ứng dụng nếu chưa bật push ở phần cài đặt và chưa cấp quyền notification cho thiết bị.

Dispatcher vẫn đánh dấu notification là đã gửi sau khi xử lý, kể cả khi push bị tắt; kênh in-app được xử lý độc lập.

## 9. Chuỗi hoạt động tổng quát

```text
Người dùng Office
    ↓
Không gian Office → Nhắc nhở
    ↓
Tải hồ sơ giờ ăn + lịch chưa gửi
    ↓
Chọn một trong ba cách
    ├─ Lưu/tự tính giờ ăn ưu tiên
    ├─ Tạo lịch tùy chỉnh
    └─ Tạo preset nước 120 phút / giãn cơ 60 phút
                           ↓
                 Lưu vào notifications
                           ↓
            Background job kiểm tra mỗi phút
                           ↓
           SignalR in-app và/hoặc FCM push
                           ↓
       Đánh dấu đã gửi; tạo kỳ sau nếu lặp
```

## 10. API đang sử dụng

| Method | Endpoint | Hoạt động |
|---|---|---|
| `GET` | `/api/Reminder/profile` | Lấy hoặc tự tạo hồ sơ giờ ăn |
| `PUT` | `/api/Reminder/profile` | Lưu giờ ăn thủ công |
| `POST` | `/api/Reminder/profile/recalculate` | Tính giờ ăn từ meal log |
| `GET` | `/api/Reminder/scheduled` | Lấy lịch tương lai chưa gửi |
| `POST` | `/api/Reminder/scheduled` | Tạo lịch mới hoặc preset Office |
| `PATCH` | `/api/Reminder/scheduled/{id}` | Sửa hoặc bật/tắt lịch |
| `POST` | `/api/Reminder/scheduled/{id}/snooze` | Dời lịch thêm một khoảng phút |
| `DELETE` | `/api/Reminder/scheduled/{id}` | Xóa lịch |

Tất cả endpoint yêu cầu đăng nhập và policy `UserOnly`.

## 11. Dữ liệu được lưu

### Bảng `reminder_profiles`

- `Id`
- `UserId`
- `OptimalBreakfastTime`
- `OptimalLunchTime`
- `OptimalDinnerTime`
- `LastRecalculatedAt`

Quan hệ với user có `ON DELETE CASCADE`. Hiện configuration chỉ tạo index cho `UserId`, chưa thể hiện unique constraint một hồ sơ trên mỗi user.

### Bảng `notifications`

Lịch nhắc tái sử dụng entity notification chung. Các trường quan trọng gồm `UserId`, `Title`, `Body`, `Type`, `ScheduledAt`, `SentAt`, `IsRead` và trạng thái dismiss.

Chu kỳ lặp không có cột riêng mà được mã hóa trong chuỗi `Type`.

## 12. Phân quyền thực tế hiện tại

Mặc dù UI Office gọi tính năng này là **Nhắc nhở văn phòng**, `ReminderController` hiện dùng:

```csharp
[Authorize]
[Authorize(Policy = "UserOnly")]
```

Điều đó có nghĩa API nhắc nhở dùng được cho các role người dùng thông thường thuộc `UserOnly`, không yêu cầu `OfficeOnly` hoặc entitlement `office_features`.

Ngoài ra, `AdaptiveRemindersScreen` còn xuất hiện trong Profile. Do đó tính năng hiện tại nên được hiểu là:

- Module nhắc nhở thông minh dùng chung.
- Office thêm điểm truy cập và hai preset công sở.
- Chưa phải tính năng được khóa độc quyền bởi subscription Office.

Nếu sản phẩm quyết định đây là quyền lợi trả phí, cần bảo vệ endpoint hoặc tách endpoint preset Office bằng policy Office; chỉ ẩn shortcut trên frontend là chưa đủ.

## 13. Giới hạn cần lưu ý

1. **Giờ ăn ưu tiên chưa tự sinh lịch:** lưu hoặc tính lại giờ ăn không làm người dùng nhận nhắc bữa ăn.
2. **Không giới hạn theo ngày làm việc:** preset nước/giãn cơ lặp cả ngày và qua các ngày, không có khung giờ làm việc hoặc lựa chọn thứ Hai–thứ Sáu.
3. **Có thể tạo lịch trùng:** bấm preset nhiều lần tạo nhiều chuỗi lặp độc lập.
4. **Không có chỉnh chu kỳ trên UI:** editor chỉ sửa nội dung và thời gian.
5. **Chu kỳ nằm trong chuỗi `Type`:** hoạt động được nhưng khó truy vấn, validate và mở rộng hơn một cột riêng.
6. **Sai số phát tối đa khoảng một phút:** background job quét mỗi phút, chưa tính thêm độ trễ FCM hoặc mạng.
7. **Tính trung bình giờ ăn đơn giản:** backend lấy toàn bộ log theo bữa và trung bình `TimeOfDay`, chưa lọc giai đoạn gần đây, loại ngoại lệ hoặc xử lý đặc biệt quanh nửa đêm.
8. **Profile time không có múi giờ:** ba giá trị dùng `time without time zone`; lịch notification riêng được gửi dưới dạng UTC và frontend đổi về local.
9. **Push mặc định tắt:** người dùng cần bật push và cấp quyền thiết bị để nhận ngoài ứng dụng.
10. **Chưa khóa theo gói Office:** cả UI Profile và API `UserOnly` cho phép người dùng thường truy cập.

## 14. Tệp nguồn liên quan

### Frontend

- `frontend/lib/features/office/widgets/office_home_panel.dart`
- `frontend/lib/features/office/views/office_workspace_screen.dart`
- `frontend/lib/features/adaptive_reminders/views/adaptive_reminders_screen.dart`
- `frontend/lib/features/adaptive_reminders/views/adaptive_reminder_widgets_part.dart`
- `frontend/lib/features/adaptive_reminders/models/reminder_models.dart`
- `frontend/lib/features/adaptive_reminders/repositories/reminder_repository.dart`
- `frontend/lib/core/network/api_endpoints.dart`

### Backend

- `backend/MenuGreen.API/Controllers/ReminderController.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/ReminderService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/NotificationDispatcherService.cs`
- `backend/MenuGreen.BusinessLogicLayer/BackgroundJobs/NotificationDispatchBackgroundService.cs`
- `backend/MenuGreen.DataAccessLayer/Entities/ReminderProfile.cs`
- `backend/MenuGreen.DataAccessLayer/Entities/Notification.cs`
- `backend/MenuGreen.DataAccessLayer/Entities/NotificationSetting.cs`
- `backend/MenuGreen.DataAccessLayer/Configurations/ReminderProfileConfiguration.cs`
- `backend/database/40_reminder_profiles.sql`

