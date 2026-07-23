# Kiểm tra hoạt động Reminder và kế hoạch sửa

## 1. Phạm vi kiểm tra

Kiểm tra được thực hiện theo luồng đã thống nhất cho người dùng Office:

1. Người dùng tự tạo reminder và tự chọn ngày/giờ.
2. Người dùng chọn loại reminder như mua nguyên liệu, nấu bữa ngày mai hoặc mang cơm.
3. Người dùng có thể giữ thời gian hệ thống đề xuất hoặc đổi sang thời gian khác.
4. Reminder được lưu, phát đúng thời điểm, có thể lặp, tắt, snooze, sửa và xóa.
5. Chức năng Office phải được phân quyền phù hợp.

Tài liệu này là báo cáo chẩn đoán và kế hoạch sửa, chưa bao gồm thay đổi implementation.

## 2. Kết luận

Luồng reminder hiện tại **chỉ hoạt động một phần**.

- CRUD reminder tùy chỉnh đã có đầy đủ code frontend và backend.
- Hai preset uống nước/giãn cơ đã có cơ chế tạo lịch lặp.
- Background job phát notification đã được đăng ký và chạy mỗi phút.
- Luồng “mua nguyên liệu”, “nấu bữa ngày mai”, “mang cơm” với thời gian đề xuất **chưa được triển khai**.
- Giờ ăn thông minh chỉ được lưu vào profile, **không tự sinh reminder**.
- Module mang tên Office nhưng API và một điểm truy cập UI vẫn mở cho người dùng thường.
- Chưa có automated test chuyên biệt cho reminder để chứng minh toàn bộ vòng đời chạy đúng.

Vì vậy chưa thể đánh dấu tính năng là hoàn thành theo luồng sản phẩm đã bàn.

## 3. Kết quả theo từng hoạt động

| Hoạt động | Trạng thái | Kết quả kiểm tra |
|---|---|---|
| Tự nhập tiêu đề và nội dung | Đạt theo source | Editor có hai trường và validate không rỗng |
| Tự chọn ngày và giờ | Đạt theo source | Có date picker, time picker và kiểm tra thời gian tương lai |
| Lưu reminder | Đạt theo source | Gọi `POST /api/Reminder/scheduled`, lưu vào `notifications` |
| Sửa reminder | Đạt theo source | Có `PATCH /api/Reminder/scheduled/{id}` |
| Bật/tắt reminder | Đạt một phần | Dùng prefix `DISABLED_`; chưa có test và thiết kế lưu trạng thái còn mong manh |
| Snooze 15/30 phút | Đạt theo source | API cho phép 1–1.440 phút |
| Xóa reminder | Đạt theo source | Có xác nhận UI và kiểm tra ownership phía backend |
| Uống nước mỗi 2 giờ | Đạt một phần | Tạo recurring 120 phút nhưng chạy 24/7, kể cả cuối tuần |
| Giãn cơ mỗi giờ | Đạt một phần | Tạo recurring 60 phút nhưng chạy 24/7, kể cả cuối tuần |
| Chọn “Mua nguyên liệu” | Chưa có | Không có reminder type hoặc preset tương ứng |
| Chọn “Nấu bữa ngày mai” | Chưa có | Không có reminder type hoặc preset tương ứng |
| Chọn “Mang cơm” | Chưa có | Không có reminder type hoặc preset tương ứng |
| Hệ thống đề xuất thời gian theo loại | Chưa có | Form chỉ mặc định thời điểm hiện tại + 1 giờ |
| Người dùng chấp nhận hoặc đổi giờ đề xuất | Chưa có | Chưa có khái niệm `suggestedAt` hay UI chọn chế độ |
| Tự tạo reminder từ giờ ăn ưu tiên | Chưa có | Profile và lịch notification đang tách rời |
| Phát notification đến hạn | Đạt theo source | Background job quét mỗi phút, SignalR/FCM theo setting |
| Tạo kỳ tiếp theo cho lịch lặp | Đạt theo source | Dispatcher tạo notification kế tiếp sau khi xử lý kỳ hiện tại |
| Chống tạo preset trùng | Chưa có | Mỗi lần bấm tạo một chuỗi lặp mới |
| Giới hạn theo giờ/ngày làm việc | Chưa có | Không có workday hoặc active time window |
| Chỉ người dùng Office được dùng | Không đạt | API dùng `UserOnly`, màn hình cũng được mở từ Profile |

## 4. Kết quả build và test

### Backend

Đã chạy:

```text
dotnet build MenuGreen.API/MenuGreen.API.csproj --no-restore
```

Kết quả:

```text
Build succeeded.
0 Warning(s)
0 Error(s)
```

Thư mục `backend/MenuGreen.API.Tests` hiện chỉ có `bin` và `obj`, không có test project hoặc source test. Vì vậy không thể chạy unit/integration test reminder hiện có.

### Frontend

Đã thử chạy analyzer trên module `adaptive_reminders` và các điểm truy cập Office. Cả `flutter analyze` và `dart analyze` không trả kết quả và bị treo trong môi trường kiểm tra, nên đã dừng tiến trình.

Trạng thái này được ghi là **chưa xác minh**, không được xem là analyzer đã pass.

### Test coverage

Không tìm thấy widget test, repository test hoặc API test dành riêng cho:

- `AdaptiveRemindersScreen`.
- `ReminderRepository`.
- `ReminderService`.
- `NotificationDispatcherService` với recurring reminder.

## 5. Danh sách lỗi và khoảng trống

### REM-01 — Thiếu ba loại reminder Office đã thống nhất

**Mức độ:** Cao  
**Loại:** Thiếu chức năng

Không có type hoặc preset cho:

- `GROCERY_SHOPPING`: mua nguyên liệu.
- `PREPARE_TOMORROW_MEAL`: nấu/chuẩn bị bữa ngày mai.
- `BRING_LUNCH`: mang cơm.

Người dùng chỉ có thể nhập các nội dung này như reminder tùy chỉnh. Hệ thống không hiểu mục đích để đề xuất thời gian hoặc liên kết với meal plan.

### REM-02 — Chưa có cơ chế thời gian đề xuất

**Mức độ:** Cao  
**Loại:** Thiếu chức năng

Editor luôn mặc định `DateTime.now() + 1 giờ`. Giá trị này không phụ thuộc loại reminder, kế hoạch ăn, giờ làm việc hay giờ ăn ưu tiên.

Thiếu các khái niệm:

- Loại reminder.
- Thời gian được hệ thống đề xuất.
- Nguồn tạo đề xuất.
- Người dùng chấp nhận hay đã chỉnh thời gian đề xuất.

### REM-03 — Giờ ăn ưu tiên không tạo lịch nhắc

**Mức độ:** Cao  
**Loại:** Hành vi không khớp kỳ vọng UI

Màn hình mô tả giờ ăn ưu tiên được dùng để “gợi ý thời điểm nhắc bữa ăn”, nhưng lưu/tính lại profile không tạo hoặc cập nhật notification nào.

Người dùng có thể hiểu rằng sau khi bấm “Lưu giờ ăn” họ sẽ được nhắc, nhưng thực tế sẽ không có notification nếu chưa tạo lịch riêng.

### REM-04 — Preset Office lặp 24/7

**Mức độ:** Cao  
**Loại:** Sai nghiệp vụ Office

Uống nước và giãn cơ dùng chu kỳ phút liên tục, không có:

- Giờ bắt đầu/kết thúc làm việc.
- Lựa chọn ngày trong tuần.
- Nghỉ trưa.
- Múi giờ gắn với lịch làm việc.

Kết quả là lịch có thể nhắc vào ban đêm hoặc cuối tuần.

### REM-05 — Có thể tạo nhiều preset trùng nhau

**Mức độ:** Trung bình  
**Loại:** Trùng dữ liệu/trải nghiệm

Mỗi lần bấm “Nước / 2 giờ” hoặc “Giãn cơ / 1 giờ” đều tạo notification recurring mới. Không có lookup hoặc idempotency key để phát hiện chuỗi đang hoạt động.

Hậu quả là người dùng có thể nhận nhiều notification giống nhau cùng lúc.

### REM-06 — Phân quyền Office chưa đúng

**Mức độ:** Cao  
**Loại:** Authorization/sản phẩm

`ReminderController` dùng `UserOnly`, không dùng `OfficeOnly`. `AdaptiveRemindersScreen` cũng xuất hiện tại Profile.

Nếu toàn bộ reminder là quyền lợi Office, trạng thái hiện tại làm lộ tính năng cho Free. Nếu chỉ preset Office là trả phí, cần tách quyền giữa reminder cơ bản và preset Office.

### REM-07 — Chu kỳ và trạng thái bị mã hóa trong `Notification.Type`

**Mức độ:** Trung bình  
**Loại:** Thiết kế dữ liệu

Ví dụ:

```text
DISABLED_RECURRING:120:CUSTOM_REMINDER
```

Một string đồng thời chứa loại, trạng thái và chu kỳ. Cách này khó validate, query, migration và mở rộng sang workday/window.

### REM-08 — Không thể cấu hình recurrence trong editor

**Mức độ:** Trung bình  
**Loại:** Thiếu UI/API client

Backend DTO hỗ trợ `RepeatIntervalMinutes`, nhưng repository update và editor không cho người dùng thiết lập hoặc thay đổi giá trị này. Recurrence hiện chỉ có thể được tạo qua hai preset.

### REM-09 — Có nguy cơ mất notification khi không gửi được kênh nào

**Mức độ:** Trung bình  
**Loại:** Độ tin cậy

Dispatcher đánh dấu `SentAt` sau khi xử lý. Nếu push tắt và in-app gửi lỗi, notification vẫn có thể bị đánh dấu đã gửi, không còn cơ hội retry.

Cần định nghĩa rõ “đã xử lý”, “đã gửi” và trạng thái từng kênh.

### REM-10 — Nguy cơ gửi trùng khi chạy nhiều backend instance

**Mức độ:** Cao khi scale-out  
**Loại:** Concurrency

Mỗi API instance khởi chạy một `NotificationDispatchBackgroundService`. Quy trình hiện đọc notification đến hạn rồi cập nhật `SentAt` mà không có distributed lock hoặc atomic claim.

Hai instance có thể cùng lấy một notification và cùng gửi/tạo kỳ kế tiếp.

### REM-11 — Hồ sơ reminder không có unique constraint theo user

**Mức độ:** Trung bình  
**Loại:** Toàn vẹn dữ liệu

`reminder_profiles.UserId` chỉ có index thường. Các luồng tạo-on-read hoặc onboarding chạy đồng thời có thể tạo nhiều profile cho một user; service sau đó dùng `FirstOrDefault()`.

### REM-12 — Kết quả tự tính giờ ăn còn đơn giản

**Mức độ:** Thấp/Trung bình  
**Loại:** Chất lượng đề xuất

Thuật toán dùng toàn bộ meal log và trung bình `TimeOfDay`, chưa:

- Ưu tiên dữ liệu gần đây.
- Loại outlier.
- Xử lý thời gian quanh nửa đêm.
- Phân biệt ngày làm việc và cuối tuần.

## 6. Thiết kế luồng mục tiêu

### 6.1 Tạo reminder từ loại có sẵn

```text
Người dùng bấm “Tạo nhắc nhở”
    ↓
Chọn loại
    ├─ Mua nguyên liệu
    ├─ Chuẩn bị bữa ngày mai
    ├─ Mang cơm
    ├─ Uống nước
    ├─ Giãn cơ
    └─ Tùy chỉnh
    ↓
Hệ thống tính title, body và suggestedAt
    ↓
Hiển thị “Thời gian đề xuất”
    ↓
Người dùng giữ nguyên hoặc chọn thời gian khác
    ↓
Lưu reminder + nguồn đề xuất + múi giờ
```

### 6.2 Quy tắc mặc định ban đầu

| Loại | Quy tắc đề xuất |
|---|---|
| Mua nguyên liệu | 18:00 ngày trước ngày nấu/meal plan |
| Chuẩn bị bữa ngày mai | 20:00 ngày hôm trước |
| Mang cơm | Trước giờ bắt đầu làm việc 30 phút |
| Nhắc bữa ăn | Trước giờ ăn ưu tiên 15 phút |
| Uống nước | Mỗi 120 phút, chỉ trong work window |
| Giãn cơ | Mỗi 60 phút, chỉ trong work window |

Nếu không có meal plan hoặc work schedule, dùng fallback và ghi rõ lý do trên UI. Người dùng luôn được phép chỉnh thời gian trước khi lưu.

## 7. Kế hoạch sửa

### Giai đoạn 1 — Chuẩn hóa nghiệp vụ và dữ liệu (P0)

1. Chốt phạm vi phân quyền:
   - Reminder tùy chỉnh là Free, preset/work schedule là Office; hoặc
   - Toàn bộ reminder là Office.
2. Thêm enum/type rõ ràng cho các loại reminder.
3. Tách recurrence khỏi `Notification.Type`:
   - `ReminderType`.
   - `IsEnabled`.
   - `RepeatIntervalMinutes`.
   - `TimeZoneId`.
   - `ActiveFrom`, `ActiveTo`.
   - `DaysOfWeek`.
4. Thêm unique index cho `reminder_profiles.UserId` và xử lý dữ liệu trùng trước migration.
5. Thiết kế trạng thái delivery/claim để dispatcher chạy an toàn trên nhiều instance.

**Đầu ra:** migration, entity/DTO mới, quy tắc entitlement đã chốt.

### Giai đoạn 2 — Backend đề xuất và lập lịch (P0)

1. Thêm service `ReminderSuggestionService`.
2. Nhận `ReminderType`, meal plan/work schedule và timezone.
3. Trả `suggestedAt`, title/body mặc định và lý do đề xuất.
4. Thêm endpoint preview, ví dụ:

```http
POST /api/Reminder/suggestions/preview
```

5. Cho phép create reminder từ suggestion nhưng vẫn nhận thời gian người dùng override.
6. Tạo/cập nhật meal reminder khi người dùng chọn bật nhắc theo giờ ăn ưu tiên.
7. Lập recurrence theo workday/window, không cộng phút vô hạn 24/7.
8. Chống preset trùng bằng logical key hoặc idempotency key.
9. Tách và áp policy Office cho phần trả phí.

**Đầu ra:** API preview/create ổn định và dispatcher đúng nghiệp vụ.

### Giai đoạn 3 — Frontend tạo reminder theo loại (P1)

1. Thêm bước chọn loại reminder.
2. Gọi API preview và hiển thị “Thời gian hệ thống đề xuất”.
3. Cho phép:
   - Dùng thời gian đề xuất.
   - Tự chọn ngày/giờ.
4. Thêm cấu hình ngày làm việc và khung giờ nhận nhắc.
5. Cho phép chỉnh recurrence phù hợp.
6. Hiển thị rõ nguồn lịch: tự tạo, hệ thống đề xuất, meal plan hay preset Office.
7. Khi preset đã tồn tại, đổi nút “Tạo” thành quản lý/bật/tắt để tránh trùng.

**Đầu ra:** UI hoàn chỉnh cho ba reminder Office và reminder tùy chỉnh.

### Giai đoạn 4 — Độ tin cậy và notification delivery (P1)

1. Atomic claim notification đến hạn trước khi gửi.
2. Lưu trạng thái theo kênh: in-app, push, retry count và last error.
3. Chỉ đánh dấu hoàn tất theo delivery policy đã định nghĩa.
4. Thêm retry/backoff và dead-letter hoặc trạng thái failed.
5. Theo dõi metrics: due, sent, failed, duplicate, delivery latency.

**Đầu ra:** không gửi trùng khi scale-out và giảm nguy cơ mất notification.

### Giai đoạn 5 — Automated test (P0, thực hiện song song)

#### Backend unit test

- Tạo reminder quá khứ bị từ chối.
- Preview từng reminder type trả đúng quy tắc.
- User override không bị ghi đè bởi suggestion.
- Recurrence chỉ tạo kỳ trong work window/workday.
- Không tạo preset trùng.
- Disable không được dispatch; enable hoạt động lại.
- Dispatcher không gửi trùng khi hai worker cạnh tranh.
- Profile mỗi user chỉ có một bản ghi.

#### Backend integration test

- CRUD và ownership.
- Free/Office entitlement.
- Chuỗi create → due → dispatch → recurring next occurrence.
- Timezone Asia/Ho_Chi_Minh và ngày chuyển múi giờ ở timezone khác.

#### Frontend test

- Chọn từng loại và nhận suggested time.
- Giữ suggestion hoặc override.
- Hiển thị loading/error/fallback đúng.
- Không tạo reminder với thời gian quá khứ.
- Preset đã tồn tại không tạo bản trùng.
- Free không truy cập phần Office nếu sản phẩm khóa tính năng.

## 8. Thứ tự ưu tiên đề xuất

| Ưu tiên | Công việc |
|---|---|
| P0 | Chốt entitlement và phạm vi Free/Office |
| P0 | Thêm reminder type và suggestion cho ba hoạt động Office |
| P0 | Sửa recurrence theo work window/workday |
| P0 | Tạo test project/backend reminder tests |
| P1 | UI chọn loại, preview và override thời gian |
| P1 | Chống preset trùng |
| P1 | Atomic dispatch và delivery state |
| P2 | Cải thiện thuật toán giờ ăn thông minh |
| P2 | Metrics, lịch sử và phân tích tương tác reminder |

## 9. Tiêu chí nghiệm thu

Tính năng chỉ được xem là hoạt động đúng khi:

- Người dùng tạo được reminder tùy chỉnh.
- Có đủ ba loại mua nguyên liệu, chuẩn bị bữa ngày mai và mang cơm.
- Mỗi loại có thời gian đề xuất hợp lý và giải thích được.
- Người dùng giữ hoặc thay đổi đề xuất trước khi lưu.
- Uống nước/giãn cơ chỉ lặp trong lịch làm việc đã chọn.
- Không thể tạo preset trùng ngoài ý muốn.
- Notification được gửi đúng timezone với sai số theo lịch quét cho phép.
- Tắt, bật, snooze, sửa và xóa đều có automated test.
- Free/Office được phân quyền đúng ở cả frontend và backend.
- Nhiều backend instance không gửi cùng một reminder hai lần.

## 10. Tệp đã kiểm tra

### Frontend

- `frontend/lib/features/adaptive_reminders/views/adaptive_reminders_screen.dart`
- `frontend/lib/features/adaptive_reminders/views/adaptive_reminder_widgets_part.dart`
- `frontend/lib/features/adaptive_reminders/models/reminder_models.dart`
- `frontend/lib/features/adaptive_reminders/repositories/reminder_repository.dart`
- `frontend/lib/features/office/widgets/office_home_panel.dart`
- `frontend/lib/features/office/views/office_workspace_screen.dart`

### Backend

- `backend/MenuGreen.API/Controllers/ReminderController.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/ReminderService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/NotificationDispatcherService.cs`
- `backend/MenuGreen.BusinessLogicLayer/BackgroundJobs/NotificationDispatchBackgroundService.cs`
- `backend/MenuGreen.DataAccessLayer/Entities/ReminderProfile.cs`
- `backend/MenuGreen.DataAccessLayer/Entities/Notification.cs`
- `backend/MenuGreen.DataAccessLayer/Entities/NotificationSetting.cs`

