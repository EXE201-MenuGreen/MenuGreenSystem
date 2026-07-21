# Báo cáo triển khai Casual Workflow

## Phạm vi

Hoàn thiện các mục 1–4 của `docs/workflow/casual_workflow.md`, đóng ba nhóm tính năng Casual đang rời rạc thành một gói subscription có entitlement riêng và một khu vực riêng trong Flutter, tương đương cách triển khai gói Gym/PT.

## Luồng đã triển khai

1. Người dùng đăng ký bằng Email + OTP hoặc Google Sign-In, hoàn thành hồ sơ sức khỏe, dị ứng, sở thích và chọn nhóm **Người dùng phổ thông**. Onboarding lưu segment chuẩn là `casual`.
2. Người dùng mở **Gói dịch vụ**, kích hoạt **Gói Casual** bằng subscription hiện có. Gói seed đang để `0đ` và không thời hạn để có thể thay đổi giá sau này. Khi thanh toán gói trả phí qua SePay, backend ưu tiên `FeatureGroup` của gói để gán đúng role `Casual`.
3. Sau khi gói hoạt động, Trang chủ hiển thị thẻ **CASUAL PLUS** với ba lối vào riêng: **Vòng quay**, **1 chạm** và **Kiến thức**. Các quick action cũ đi qua Casual Hub/paywall nên không còn mở thẳng API trả phí.
4. **Vòng quay món ăn** tải tối đa 10 món không trùng, ưu tiên ngân sách, vùng miền và sở thích; món khớp dị ứng bị loại trước khi trả về. Backend kiểm tra lại trạng thái món, loại bữa và dị ứng khi người dùng chọn **Ăn món này**.
5. **Khởi động 1 chạm** trả câu truyền cảm hứng, calo mục tiêu, calo đã dùng và calo còn lại theo ngày Việt Nam. Ba món nổi bật được xếp hạng theo calo còn lại, ngân sách, vùng miền và độ an toàn dị ứng.
6. Người dùng có thể thêm món nổi bật vào kế hoạch hôm nay. Backend kiểm tra món còn hoạt động, loại bữa hợp lệ và dị ứng trước khi tạo kế hoạch, đồng thời đặt đúng giờ sáng/trưa/tối/bữa phụ.
7. Nút **Ghi nhận nhanh theo khung giờ** tự nhận diện bữa sáng/trưa/tối/phụ, chọn món an toàn phù hợp nhất và tạo `MealLog` thật bằng khẩu phần mặc định chỉ với một lần chạm.
8. **Góc dinh dưỡng** giữ luồng đọc, đánh dấu đã đọc, lưu/bỏ lưu thẻ. Gợi ý dùng dữ liệu ba ngày gần nhất, hồ sơ sức khỏe và dị ứng; bổ sung phát hiện thiếu chất xơ cùng thẻ kiến thức Fiber không kèm quiz.

## Thay đổi backend

### Gói Casual và phân quyền

- Seed plan **Gói Casual** với `FeatureGroup = "casual"`, giá `0`, ID cố định `10000000-0000-0000-0000-000000000005`.
- Migration: `20260721103000_AddCasualSubscriptionPlan.cs`.
- SQL triển khai thủ công tương ứng: `database/58_casual_subscription_plan.sql`.
- Policy `CasualOnly` dùng entitlement `casual_features`; chấp nhận gói `casual` hoặc `pro`, không còn dựa vào danh sách role mở rộng.
- `LuckyWheelController`, `DailyStarterController` và `MicroLearningController` cùng dùng policy Casual.
- `UserSubscriptionService` và `SepayPaymentService` ánh xạ gói Casual/Pro sang role `Casual`; luồng SePay lấy `FeatureGroup` của gói làm nguồn chính xác thay cho segment hồ sơ.

### Lucky Wheel

- Lọc dị ứng trước khi random, không fallback sang món không an toàn.
- Trả tối đa 10 món riêng biệt từ nhóm ứng viên được chấm điểm theo ngân sách, vùng và sở thích.
- Kiểm tra lại `FoodId`, trạng thái món, `MealType` và dị ứng ở endpoint apply.
- Lưu món vào kế hoạch ngày Việt Nam và đặt giờ theo loại bữa.

### Daily Starter

- `GET /api/DailyStarter/today` dùng cửa sổ ngày Việt Nam và trả thêm `CaloriesConsumed`, `CaloriesRemaining`.
- `GET /api/DailyStarter/featured-meals` được cá nhân hóa theo user, chỉ trả ba món an toàn.
- `POST /api/DailyStarter/select-meal` giới hạn 1–4 món, kiểm tra dữ liệu và dị ứng trước khi tạo kế hoạch.
- `POST /api/DailyStarter/start-log` tạo nhật ký thật qua `INutritionTrackingService` và trả `LoggedMealId`, `LoggedFood`.

### Micro-Learning

- Phân tích protein, fat, dị ứng và chất xơ từ lịch sử ăn uống ba ngày gần nhất.
- Bổ sung category **Fiber** và thẻ **Bổ sung chất xơ mỗi ngày**.
- Thẻ Fiber tập trung vào nội dung đọc/mẹo nhanh, không yêu cầu quiz, đúng phạm vi Casual Workflow hiện tại.

## Thay đổi Flutter

- Thêm `CasualHubScreen` làm cửa ngõ/paywall cho ba tính năng Casual.
- Thêm `CasualPackageCard` trên Trang chủ khi user có entitlement.
- Thêm kiểm tra `hasCasualSubscriptionAccess`, hỗ trợ đồng thời nhiều subscription.
- Màn **Gói dịch vụ** có card Casual riêng, kích hoạt segment `casual`, subscribe/SePay và mở Casual Hub sau khi thành công.
- Quick action **Hôm nay ăn gì?**, **Góc dinh dưỡng** và hai lối vào Lucky Wheel trong hồ sơ đều đi qua Casual Hub.
- Daily Starter hiển thị calo còn lại và có nút ghi nhật ký một chạm.
- Sửa mapping món gợi ý trên Trang chủ vốn ép model thành `Map` sai kiểu khiến danh sách bị bỏ qua âm thầm.

## Kiểm thử

- `dotnet build MenuGreen.sln --no-restore`: thành công, không có lỗi; còn ba cảnh báo nullable cũ ngoài phạm vi Casual.
- Flutter analyze cho 13 file thay đổi: không có issue.
- Flutter tests:
  - active Casual/Pro mở Casual dashboard;
  - gói hủy hoặc gói không liên quan không mở Casual dashboard;
  - card Casual hiển thị đủ ba action và không overflow ở chiều rộng 360 px;
  - test card Gym hiện có vẫn chạy qua.

## Lưu ý triển khai

1. Chạy EF migration hoặc `database/58_casual_subscription_plan.sql` trước khi phát hành app mới.
2. Giá seed hiện là `0đ`; có thể cập nhật bằng API quản lý SubscriptionPlan mà không cần sửa app.
3. User cũ chưa có subscription Casual sẽ được chuyển đến màn Gói dịch vụ khi mở một tính năng Casual.
