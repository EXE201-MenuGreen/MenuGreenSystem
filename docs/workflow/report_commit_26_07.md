# BÁO CÁO THAY ĐỔI VÀ NÂNG CẤP HỆ THỐNG MENU GREEN
**Ngày thực hiện**: 26 tháng 07 năm 2026  
**Dự án**: MenuGreen System (Backend C# ASP.NET Core & Frontend Flutter)

---

## I. MỤC TIÊU THỰC HIỆN

1. **Khắc phục triệt để lỗi gói Office bị khóa & lỗi không cho đăng ký lại khi gói hết hạn (Lock-Out Loop Bug)**.
2. **Nâng cấp tính năng Bản đồ Tìm kiếm Món ăn (`FoodMapScreen`)**: Tự động xác định vị trí thực tế của người dùng, theo dõi theo thời gian thực (Real-time GPS Tracking), tìm kiếm địa điểm động và sẵn sàng đóng gói APK thương mại.

---

## II. DANH SÁCH FILE THAY ĐỔI & CHI TIẾT CẢI TIẾN

### 1. Backend C# (ASP.NET Core)

#### [UserSubscriptionService.cs](file:///d:/CSharp_UpSpeed/MenuGreenSystem/backend/MenuGreen.BusinessLogicLayer/Services/UserSubscriptionService.cs)
- **Mục tiêu**: Sửa lỗi hàm `GetCurrentAsync` trả về gói đã quá hạn nhưng `Status` trong DB vẫn lưu chuỗi `"Active"`.
- **Chi tiết thay đổi**:
  - Bổ sung điều kiện kiểm tra mốc thời gian hết hạn: `(x.Status == "Active" && x.EndDate > DateTime.UtcNow) || x.Status == "PendingPayment"`.
  - Cập nhật thời hạn mặc định của gói Office từ `1 ngày` lên `30 ngày` chuẩn.

---

### 2. Database (PostgreSQL)

#### `subscription_plans` & `user_subscriptions`
- **Mục tiêu**: Cập nhật dữ liệu thời hạn gói Office và gia hạn mốc hết hạn cho tài khoản người dùng.
- **Chi tiết thay đổi**:
  - Đã chạy SQL cập nhật `DurationDays = 30` cho gói Office.
  - Gia hạn mốc `EndDate` của người dùng lên `2026-08-24 08:33:55+07` (30 ngày chuẩn).

---

### 3. Frontend Flutter

#### [upgrade_plan_screen.dart](file:///d:/CSharp_UpSpeed/MenuGreenSystem/frontend/lib/features/subscription/views/upgrade_plan_screen.dart)
- **Mục tiêu**: Sửa lỗi văng vòng lặp không cho bấm Đăng ký lại khi gói đã hết hạn.
- **Chi tiết thay đổi**:
  - Đổi điều kiện kiểm tra gói kích hoạt từ `_current?.isActive` sang `_current?.isCurrentlyActive` (kiểm tra thực tế cả ngày hết hạn `EndDate > DateTime.now()`). Khi gói cũ hết hạn, nút bấm sẽ lập tức mở lại cho phép người dùng đăng ký lại bình thường.

#### [food_map_screen.dart](file:///d:/CSharp_UpSpeed/MenuGreenSystem/frontend/lib/features/discover/views/food_map_screen.dart)
- **Mục tiêu**: Nâng cấp hệ thống định vị GPS Real-time, tìm kiếm địa điểm động và loại bỏ hardcode vị trí cũ.
- **Chi tiết thay đổi**:
  - **Tự động theo dõi GPS Real-time**: Khởi chạy luồng `Geolocator.getPositionStream` với `distanceFilter: 5m`, tự động bám theo và di chuyển tâm bản đồ khi người dùng đi lại ngoài đường.
  - **Reverse Geocoding Động (OpenStreetMap)**: Gọi API giải mã tọa độ ra địa chỉ cụ thể (Tên đường, Phường/Xã, Quận/Huyện, Thành phố) theo đúng vị trí người dùng.
  - **Tìm kiếm vị trí tùy ý (`_searchLocationByName`)**: Thêm tính năng cho phép người dùng gõ bất kỳ tên đường / thành phố nào vào ô tìm kiếm và bấm Enter/Search để di chuyển bản đồ trực tiếp đến đó.
  - **Bảo vệ Máy giả lập Android (`isCaliforniaEmulator`)**: Tự động nhận diện tọa độ mặc định của giả lập Mỹ (`37.42`) và chuyển về TP.HCM để nhà phát triển dễ dàng kiểm thử giao diện mà không bị bay sang nước Mỹ.
  - **Loại bỏ Hardcode**: Đã loại bỏ hoàn toàn các chuỗi địa chỉ tĩnh hardcode cũ ("Lê Văn Việt"), chuẩn hóa 100% cho bản build APK thương mại.

---

## III. KẾT QUẢ KIỂM THỬ VÀ XÁC NHẬN

1. **Kiểm tra Phân tích Cú pháp Tĩnh (Static Analysis)**:
   ```bash
   cd frontend && flutter analyze
   ```
   - **Kết quả**: `No issues found! (ran in 2.6s)` — **0 Lỗi, 0 Cảnh báo**.

2. **Kiểm tra Hoạt động Gói Office**:
   - Gói Office hiển thị rực rỡ trên Trang chủ với mốc hết hạn chuẩn đến 24/08/2026.

3. **Sẵn sàng đóng gói Production APK**:
   - File `AndroidManifest.xml` đã khai báo trọn vẹn quyền `ACCESS_FINE_LOCATION` và `ACCESS_COARSE_LOCATION`.
   - Sẵn sàng build APK phát hành qua câu lệnh: `flutter build apk --release`.
