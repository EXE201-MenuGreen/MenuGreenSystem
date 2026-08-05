# Hoạt động Backend: Phân quyền tính năng Free, Office và Gym/PT

## 1. Mục tiêu

Xây dựng cơ chế phân quyền tập trung để backend là nguồn sự thật duy nhất về quyền sử dụng tính năng. Người dùng Free được sử dụng các chức năng dinh dưỡng cơ bản; tính năng Office và Gym/PT chỉ được thực thi khi người dùng có entitlement tương ứng.

Hoạt động này không chỉ phục vụ việc ẩn shortcut trên frontend. Mọi API trả phí vẫn phải được backend bảo vệ để người dùng không thể gọi trực tiếp bằng HTTP.

## 2. Phạm vi người dùng

| Nhóm | Entitlement | Quyền chính |
|---|---|---|
| Free/Casual/User | `free_features` | Chức năng dinh dưỡng cơ bản |
| Office | `office_features` | Toàn bộ Free và bộ công cụ Office |
| Gym/PT | `gym_features` | Toàn bộ Free và bộ công cụ Gym/PT |
| Admin | Theo chính sách quản trị | Có thể kiểm tra hoặc quản trị mọi nhóm |

Một tài khoản có thể có nhiều subscription đang active. Quyền hiệu lực là hợp của các entitlement còn hạn, không chỉ là subscription mới nhất.

## 3. Trạng thái hiện tại

- `subscription_plans.FeatureGroup` đã chứa các giá trị như `office` và `gym`.
- `GET /api/UserSubscription/me/active` đã trả về toàn bộ subscription còn hiệu lực.
- `EntitlementHandler` đã nhận biết `gym_features`, `coach_access` và `office_features`.
- Policy `GymerOnly` đã dùng entitlement.
- Policy `OfficeOnly` hiện dựa vào role `Office` hoặc `Admin`, chưa thống nhất với cách kiểm tra subscription của Gym.
- `UserDashboardService` mặc định tên gói là `Free` khi người dùng không có subscription.

## 4. Danh mục quyền đề xuất

### 4.1 Free

- Gợi ý “Hôm nay ăn gì?”
- Kế hoạch ăn cơ bản
- Tìm món ăn và xem chi tiết món
- Quét nguyên liệu và tính calo cơ bản
- Ghi cân nặng
- Ghi nhận bữa ăn ngoài
- Yêu thích
- Sở thích món Việt
- Thay thế nguyên liệu
- So sánh kế hoạch với thực tế
- Mẫu thực đơn đã lưu
- Góc dinh dưỡng
- An toàn, consent và quyền dữ liệu

### 4.2 Office

- Không gian Office
- Kế hoạch cơm hộp theo tuần
- Ngân sách bữa trưa văn phòng
- Nhắc uống nước, giãn cơ và giờ ăn
- Các thao tác Office chuyên biệt khác

### 4.3 Gym/PT

- Mục tiêu Gym
- PT Review
- Kết nối huấn luyện viên
- Chương trình/lộ trình tập luyện premium
- Các thao tác Gym chuyên biệt khác

## 5. Luồng xử lý

1. Client gửi JWT đến API.
2. Backend xác định `userId` từ claim.
3. Backend tải tất cả `user_subscriptions` có trạng thái active.
4. Loại các subscription đã hết hạn hoặc đã bị vô hiệu hóa.
5. Đọc `FeatureGroup` của từng plan và tổng hợp entitlement.
6. Endpoint Free yêu cầu xác thực và policy `UserOnly`.
7. Endpoint Office yêu cầu `office_features`; endpoint Gym/PT yêu cầu `gym_features`.
8. Thiếu entitlement phải trả `403 Forbidden`, không trả `404` hoặc `200` với dữ liệu rỗng.

## 6. Công việc triển khai

### Backend API

- Bổ sung policy `OfficeOnly` sử dụng `EntitlementRequirement("office_features")`, tương tự `GymerOnly`.
- Chuẩn hóa `FeatureGroup` về các giá trị máy đọc được: `free`, `office`, `gym`, `coach`, `premium`.
- Gắn `[Authorize(Policy = "OfficeOnly")]` vào toàn bộ controller/action Office.
- Gắn `[Authorize(Policy = "GymerOnly")]` vào toàn bộ controller/action Gym/PT.
- Giữ API Free với `[Authorize(Policy = "UserOnly")]`.
- Không dùng role giao diện hoặc `aiProfile.mode` thay cho entitlement trả phí.

### API quyền truy cập dành cho client

Có thể tiếp tục dùng `GET /api/UserSubscription/me/active`. Nếu muốn giảm logic suy diễn ở client, bổ sung endpoint tổng hợp:

```http
GET /api/UserSubscription/me/entitlements
```

Response đề xuất:

```json
{
  "tier": "free",
  "entitlements": ["free_features"],
  "featureGroups": ["free"],
  "expiresAt": null
}
```

Người dùng có cả Office và Gym/PT:

```json
{
  "tier": "paid",
  "entitlements": ["free_features", "office_features", "gym_features"],
  "featureGroups": ["office", "gym"],
  "expiresAt": null
}
```

`free_features` luôn được cấp cho tài khoản người dùng hợp lệ. `expiresAt` có thể là `null` khi quyền không hết hạn hoặc khi mỗi entitlement có thời hạn khác nhau; nếu cần biểu diễn chính xác hơn, trả thời hạn theo từng entitlement.

## 7. Quy tắc bảo mật

- Ẩn nút ở frontend không phải là authorization.
- Không tin `role`, `mode` hoặc cờ boolean do client gửi lên.
- Việc kiểm tra thời hạn phải dùng thời gian UTC phía server.
- Subscription `Cancelled` nhưng còn hiệu lực cần tuân theo nghiệp vụ đã thống nhất; trạng thái được phép phải được định nghĩa rõ tại một nơi.
- Khi subscription hết hạn, background service cập nhật trạng thái nhưng authorization vẫn phải kiểm tra `EndDate` để tránh khoảng trễ.
- Ghi log quyết định từ chối theo `userId`, policy và endpoint; không ghi token hoặc dữ liệu nhạy cảm.

## 8. Kiểm thử

### Unit test

- Free không đạt `office_features` hoặc `gym_features`.
- Office đạt `office_features` nhưng không mặc định đạt `gym_features`.
- Gym/PT đạt `gym_features` nhưng không mặc định đạt `office_features`.
- Người dùng có đồng thời hai gói đạt cả hai entitlement.
- Subscription hết hạn, inactive hoặc bị hủy theo quy tắc nghiệp vụ không cấp quyền.
- Admin được xử lý đúng theo policy đã định nghĩa.

### Integration test

- Free gọi API Free nhận `200`.
- Free gọi API Office/Gym nhận `403`.
- Office gọi API Office nhận `200`.
- Gym/PT gọi API Gym nhận `200`.
- Không có JWT nhận `401`.
- Endpoint entitlement trả đúng hợp quyền khi người dùng có nhiều subscription active.

## 9. Tiêu chí hoàn thành

- Không có API Office/Gym nào chỉ dựa vào việc frontend ẩn nút.
- `OfficeOnly` và `GymerOnly` đều dựa trên entitlement còn hiệu lực.
- Người dùng Free vẫn truy cập đầy đủ API cơ bản.
- Kết quả phân quyền nhất quán giữa API entitlement, policy và dữ liệu subscription.
- Có unit test và integration test cho ma trận Free/Office/Gym/PT.

## 10. Tệp liên quan

- `backend/MenuGreen.API/Program.cs`
- `backend/MenuGreen.API/Authorization/EntitlementHandler.cs`
- `backend/MenuGreen.API/Controllers/UserSubscriptionController.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/UserSubscriptionService.cs`
- `backend/MenuGreen.DataAccessLayer/Entities/SubscriptionPlan.cs`
- `backend/database/06_subscription_plans.sql`

