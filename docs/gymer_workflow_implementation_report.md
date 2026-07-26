# Báo cáo triển khai Gymer Workflow

## Phạm vi

Hoàn thiện các mục 1–5 của `docs/workflow/gymer_workflow.md`, nối gói Gym/PT với subscription backend và tách khu vực Gymer thành một luồng riêng trong Flutter. Giao diện dùng màu xanh hiện có của MenuGreen, kết hợp điểm nhấn vàng/VIP vừa đủ để phân biệt gói mà không làm lệch hệ màu chung.

## Luồng đã triển khai

1. Người dùng đăng ký bằng Email + OTP hoặc Google Sign-In và hoàn thành onboarding với tuổi/ngày sinh, chiều cao, cân nặng, cân nặng mục tiêu, mức hoạt động và mục tiêu **Tăng cơ/Recomp**.
2. Backend tính BMI, BMR, TDEE, calorie target và macro; Recomp dùng cấu hình giàu protein tương tự mục tiêu tăng cơ.
3. Người dùng chọn nhóm **Người tập Gym**, mở Gói dịch vụ và đăng ký **Gói Gym/PT** qua luồng subscription/SePay. Giá seed hiện tại là `0đ` để có thể chỉnh sau.
4. Sau khi gói hoạt động, người dùng mở khu vực **GYMER VIP** nằm ngay phía trên bốn quick action trên Trang chủ. Bốn lối vào riêng gồm **Mục tiêu**, **PT Review**, **Coach** và **Lộ trình**.
5. Trong **Mục tiêu**, người dùng cấu hình cân nặng mục tiêu, % mỡ mục tiêu, protein tối thiểu, calorie ngày tập/ngày nghỉ và lịch tập; sau đó ghi cân nặng/% mỡ định kỳ để hệ thống hiệu chỉnh xu hướng.
6. Trong **PT Review**, người dùng tạo báo cáo 7 ngày và link token; PT bên ngoài xem/gửi feedback mà không cần tài khoản. Người dùng nhận thông báo và có thể Apply để cập nhật calories/macros.
7. Trong **Coach**, người dùng tìm kiếm/kết nối huấn luyện viên, cấp hoặc thu hồi quyền xem dữ liệu. Coach được cấp quyền có thể xem hồ sơ, dinh dưỡng 7 ngày, cân nặng và điều chỉnh meal plan/macros.
8. Trong **Lộ trình**, người dùng chọn chương trình 8–12 tuần, thanh toán, chọn ngày bắt đầu, nhận meal plan tuần và check-in cân nặng, % mỡ, vòng ngực, vòng eo, vòng hông.
9. Sau mỗi check-in, backend mở khóa tuần kế tiếp. Nếu đủ calorie và protein trong 7 ngày liên tiếp, người dùng nhận huy hiệu **Kỷ luật dinh dưỡng 7 ngày** và `100` điểm.
10. Khi hoàn tất mọi milestone, người dùng bấm **Tốt nghiệp & nhận chứng nhận** để chốt chương trình, xem báo cáo thay đổi cân nặng/% mỡ/số đo, mức tuân thủ, điểm thưởng và huy hiệu. Backend có endpoint xuất chứng nhận HTML có thể in/lưu thành file.

## Thay đổi backend

### Gói Gym/PT và phân quyền

- Seed plan **Gói Gym/PT** với `FeatureGroup = "gym"`, giá `0`, bốn nhóm quyền Mục tiêu/PT Review/Coach/Lộ trình.
- `EntitlementHandler` kiểm tra toàn bộ subscription đang hoạt động và chấp nhận feature group `gym` cho tính năng Gymer. (Trước 2026-07-24 nhánh `pro` được chấp nhận cho tương thích ngược; hiện đã gỡ vì không còn bán gói `Pro` riêng.)
- `UserSubscriptionService` ánh xạ gói Gym/PT sang role `Gymer` nhưng vẫn giữ nguyên ánh xạ Office và các gói khác.
- `GET /api/UserSubscription/me/active` trả toàn bộ subscription đang hiệu lực, nên một user có thể đồng thời dùng Office, Gym và các gói khác mà không phụ thuộc gói mua gần nhất.
- Migration: `20260716160000_AddGymerSubscriptionPlan.cs`.

### Onboarding và Gym Goals

- Onboarding hỗ trợ **Tái cấu trúc cơ thể (Recomp)**, **Very Active** và cân nặng mục tiêu.
- `HealthProfile` lưu `TargetWeightKg`; dashboard trả đúng cân nặng mục tiêu thay vì giá trị rỗng.
- `HealthProfileMetricsCalculator` tính Recomp ở mức calorie cân bằng và dùng tỷ lệ macro giàu protein.
- `GymGoalUpsertRequest` hỗ trợ `TargetWeightKg` và `TargetBodyFatPercent`.
- `POST /api/GymGoals/setup` được bổ sung đúng theo tài liệu; route cũ `POST /api/GymGoals` vẫn giữ để tương thích.
- Cấu hình Gym lưu lịch tập, calorie ngày tập/ngày nghỉ, khoảng calorie/protein và các chỉ số hình thể mục tiêu.
- Weight log dùng luồng tracking hiện có; `POST /api/GymGoals/recalibrate` đọc lịch sử chỉ số để đánh giá xu hướng và gợi ý calorie target.
- Migration: `20260717110500_AddHealthTargetWeight.cs`.

### PT Review và Coaches

- PT Review có đầy đủ tạo report/token, xem báo cáo chia sẻ, gửi feedback, notification, Apply/Reject và cập nhật calories/macros.
- Bổ sung alias tương thích tài liệu:
  - `POST /api/PtReview/shared-reports/{token}/feedback`.
  - `POST /api/PtReview/reports/{id}/apply`.
- Các route cũ `/submit` và `/requests/{id}/apply` vẫn hoạt động, tránh xung đột frontend hoặc client cũ.
- Coaches giữ đầy đủ catalog, connect, grant/revoke access, dữ liệu dinh dưỡng 7 ngày, health profile, weight trend và quyền điều chỉnh kế hoạch.

### Premium Programs

- Có catalog chương trình, checkout SePay, activation, enrollment history, milestone tuần, progress trend, graduation và wrap-up report.
- Check-in tuần lưu cân nặng, % mỡ, vòng ngực, vòng eo và vòng hông; đồng thời ghi weight log dùng chung.
- `POST /api/PremiumPrograms/checkin` tự xác định tuần hiện tại của chương trình active đúng theo workflow; route cũ có week number vẫn được giữ để tương thích client cũ.
- Mỗi check-in mở khóa milestone/meal plan tuần tiếp theo.
- Backend kiểm tra 7 nutrition snapshot gần nhất; nếu cả 7 ngày đạt 90–110% calorie target và đủ protein target thì cấp huy hiệu cùng `100` điểm.
- Báo cáo tổng kết gồm thay đổi cân nặng, % mỡ, vòng ngực/eo/hông, tỷ lệ tuân thủ, huy hiệu, điểm thưởng và trend theo tuần.
- Endpoint cho chương trình đã hoàn thành:
  - `GET /api/PremiumPrograms/my-programs/{id}/wrap-up-report`.
  - `GET /api/PremiumPrograms/my-programs/{id}/certificate` để xuất chứng nhận HTML có thể in.
- Migration: `20260717110000_AddPremiumProgramMeasurementsAndRewards.cs`.

## Thay đổi Flutter

- Trang chủ có card **GYMER VIP** nền trắng, viền xanh và bóng đổ đồng bộ khối quick action, đặt ngay phía trên **Hôm nay ăn gì/Kế hoạch ăn/Tính calo/Cân nặng**. Bốn icon dùng bảng màu xanh của ứng dụng; màu vàng chỉ làm điểm nhấn cho vương miện, kèm badge xanh **TRẢ PHÍ** để nhận diện gói Premium.
- Dải **GYMER VIP** chỉ được render khi danh sách subscription có ít nhất một gói `gym` đang active; tài khoản chưa mua, đang chờ thanh toán, đã hủy hoặc hết hạn sẽ không thấy dashboard này. (Trước 2026-07-24 điều kiện còn bao gồm `pro`; hiện đã gỡ.)
- Bốn tính năng Gym được tách khỏi Không gian Office và dẫn tới `GymerHubScreen`.
- `UpgradePlanScreen` hiển thị card Gym/PT riêng với bốn icon, giá đọc từ backend và mặc định seed `0đ`.
- `GymGoalsScreen` hiển thị chỉ số mục tiêu, cho phép ghi cân nặng/% mỡ và hiệu chỉnh xu hướng ngay trong luồng Gym.
- `AdvancedFeaturesScreen` hỗ trợ chế độ Gymer, chỉ hiển thị PT Review/Coach và không trộn các thao tác quản trị coach vào trải nghiệm học viên.
- `PremiumProgramsScreen` có catalog, thanh toán QR, kích hoạt, check-in đủ số đo, điểm thưởng, nút tốt nghiệp, báo cáo tổng kết và chứng nhận hoàn thành.

## Kiểm tra

- `dotnet build MenuGreen.sln --no-restore`: thành công, `0` lỗi; còn `2` warning cũ trong `AiAssistantService.cs` và `Program.cs`.
- `flutter test --no-pub`: thành công, toàn bộ `17` tests passed.
- Test subscription xác nhận user có nhiều gói vẫn thấy Gymer khi bất kỳ gói `gym` nào active, và không thấy khi chỉ có Office hoặc gói Gym đã hủy.
- `flutter analyze --no-pub`: không có lỗi từ phần Gymer; còn `2` info cũ `unnecessary_underscores` trong `lucky_wheel_screen.dart`.
- Widget test xác nhận gói Gymer được tách riêng, có bốn action và hiển thị ổn ở chiều rộng mobile `360px`.

## Việc triển khai môi trường

- Chạy EF migrations trên database mục tiêu để thêm gói Gym/PT, `HealthProfile.TargetWeightKg` và các cột số đo/huy hiệu/điểm của milestone.
- Nếu dựng database bằng bộ SQL seed, dùng bản cập nhật của `05_health_profiles.sql`, `06_subscription_plans.sql`, `53_user_program_milestones.sql` và `57_gymer_subscription_plan.sql`.
- Deploy/restart backend để nhận route tương thích PT Review, Gym Goals setup, Premium report/certificate và logic reward mới.
- Build/release lại Flutter app để người dùng nhận giao diện **GYMER VIP**, Gym Hub và luồng Premium Programs hoàn chỉnh.
