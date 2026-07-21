# Báo cáo hoàn thiện Casual Workflow

Ngày cập nhật: **22/07/2026**

Tài liệu nguồn: [`docs/workflow/casual_workflow.md`](workflow/casual_workflow.md)

Trạng thái kiểm chứng: **95% hoàn thành**

## 1. Kết luận

Casual Workflow đã có đầy đủ luồng nghiệp vụ chính từ đăng ký, onboarding, kích hoạt quyền truy cập đến ba nhóm tính năng **Vòng quay món ăn**, **Khởi động 1 chạm** và **Micro-Learning**. Backend, Flutter và database đã được nối thành một luồng thống nhất; frontend không còn bypass subscription.

Tiến độ được tính trên 20 hạng mục có thể kiểm chứng:

- **18 hạng mục hoàn thành đầy đủ**.
- **2 hạng mục hoàn thành một phần**: test backend tự động và kiểm thử thanh toán Casual trả phí trên staging.
- Điểm quy đổi: `(18 + 2 × 0,5) / 20 = 95%`.

## 2. Ma trận đối chiếu yêu cầu

| # | Yêu cầu trong workflow | Trạng thái | Bằng chứng triển khai |
|---:|---|---|---|
| 1 | Đăng ký Email + OTP | ✅ Hoàn thành | `AuthController`, `AuthService.RegisterAsync`, `VerifyOtpAsync` |
| 2 | Google Sign-In | ✅ Hoàn thành | `AuthController`, `AuthService.LoginWithGoogleAsync` |
| 3 | Tài khoản mới ở tầng miễn phí | ✅ Hoàn thành | Role kỹ thuật mặc định là `User`, tương ứng tầng truy cập miễn phí |
| 4 | Nhân trắc học, mục tiêu và mức vận động | ✅ Hoàn thành | Onboarding Flutter, `HealthProfileService` |
| 5 | Dị ứng và sở thích ẩm thực | ✅ Hoàn thành | `AllergyService`, hồ sơ AI và các bước onboarding |
| 6 | Chọn nhóm Casual / Simple Eater | ✅ Hoàn thành | `user_type_step.dart`, giá trị chuẩn hóa `casual` |
| 7 | Gói Casual, entitlement và role Casual | ✅ Hoàn thành | `EntitlementHandler`, policy `CasualOnly`, `UserSubscriptionService` |
| 8 | Thanh toán/kích hoạt và ánh xạ SePay | 🟡 Hoàn thành một phần | Luồng SePay và role mapping đã có; plan seed hiện là `0đ` nên mặc định kích hoạt trực tiếp, chưa kiểm thử một giao dịch Casual trả phí trên staging |
| 9 | Lấy tối đa 10 món không trùng cho vòng quay | ✅ Hoàn thành | `LuckyWheelService.GetWheelFoodsAsync`, `Take(10)` |
| 10 | Cá nhân hóa theo dị ứng, ngân sách, vùng và sở thích | ✅ Hoàn thành | `LuckyWheelService`, `IAllergenMatchingService` |
| 11 | Hiệu ứng quay và hiển thị dinh dưỡng/giá | ✅ Hoàn thành | `lucky_wheel_screen.dart` |
| 12 | Áp dụng món vào kế hoạch hôm nay hoặc quay lại | ✅ Hoàn thành | `POST /api/LuckyWheel/apply`, `ApplyWheelSelectionAsync` |
| 13 | Dashboard hôm nay, quote và calo còn lại | ✅ Hoàn thành | `GET /api/DailyStarter/today`, `CaloriesConsumed`, `CaloriesRemaining` |
| 14 | Ba món nổi bật phù hợp | ✅ Hoàn thành | `GET /api/DailyStarter/featured-meals`, xếp hạng và `Take(3)` |
| 15 | Chọn món vào kế hoạch hôm nay | ✅ Hoàn thành | `POST /api/DailyStarter/select-meal`, UI Daily Starter |
| 16 | Ghi nhật ký một chạm theo khung giờ | ✅ Hoàn thành | `POST /api/DailyStarter/start-log`, tạo `MealLog` thật |
| 17 | Gợi ý thẻ kiến thức theo lịch sử ăn uống | ✅ Hoàn thành | `GET /api/MicroLearning/cards/recommended`, phân tích 3 ngày gần nhất |
| 18 | Đọc tiêu đề, tóm tắt và Quick Tips | ✅ Hoàn thành | Micro-Learning detail UI và DTO thẻ kiến thức |
| 19 | Đánh dấu đã đọc, lưu và bỏ lưu | ✅ Hoàn thành | `cards/{id}/action`, `cards/saved`, UI bookmark |
| 20 | Test tự động và kiểm thử tích hợp | 🟡 Hoàn thành một phần | Flutter có test entitlement/card; backend build và local integration chạy tốt nhưng chưa có test service/controller Casual chuyên biệt |

## 3. Kiến trúc đã hoàn thiện

### Quyền truy cập và gói cước

- Policy `CasualOnly` yêu cầu entitlement `casual_features`.
- Gói có `FeatureGroup = casual` hoặc `pro` được cấp quyền Casual.
- `LuckyWheelController`, `DailyStarterController` và `MicroLearningController` cùng dùng policy này.
- Flutter kiểm tra subscription thật bằng `hasCasualSubscriptionAccess`; không còn cờ bypass.
- `CasualHubScreen` là cửa ngõ chung, điều hướng người chưa có quyền tới màn Gói dịch vụ.

### Database

- ID cố định của gói Casual: `10000000-0000-0000-0000-000000000005`.
- `backend/database/06_subscription_plans.sql` đã được đồng bộ để seed database mới có gói Casual.
- `backend/database/58_casual_subscription_plan.sql` là script idempotent cho database đang tồn tại; script này đồng thời bổ sung thẻ kiến thức Fiber.
- Workspace hiện dùng migration hợp nhất `20260721173149_Init`; dữ liệu nghiệp vụ được nạp qua bộ seed SQL.

### Flutter

- Trang chủ chỉ hiện `CasualPackageCard` khi tài khoản có entitlement thật.
- Ba lối vào: **Vòng quay**, **1 chạm**, **Kiến thức**.
- Thẻ Casual và Gymer dùng chung `HomePackageCard`, nên nền, viền, shadow, header, badge, divider và action spacing cùng một hệ thống UI.
- Các quick action cũ được đưa qua Casual Hub thay vì mở thẳng tính năng trả phí.

## 4. Kết quả kiểm tra

| Kiểm tra | Kết quả |
|---|---|
| `dotnet build MenuGreen.sln --no-restore` trong `backend` | ✅ Thành công, 0 warning, 0 error |
| Flutter analyze 16 file liên quan Casual/subscription/home | ✅ Không có issue |
| `subscription_access_test.dart` | ✅ 4 case pass |
| `casual_package_card_test.dart` | ✅ Pass |
| `gymer_package_card_test.dart` | ✅ Pass |
| Frontend emulator → local API | ✅ Kết nối trực tiếp `10.0.2.2:5000` và backend nhận truy vấn database |

## 5. Phần còn lại để đạt 100%

1. Thêm unit/integration test backend cho:
   - lọc dị ứng và giới hạn 10 món của Lucky Wheel;
   - ba món nổi bật, chọn món và start-log của Daily Starter;
   - xếp hạng thẻ Micro-Learning và hành vi save/unsave.
2. Cấu hình một mức giá Casual khác `0đ` trên staging và chạy end-to-end SePay: tạo QR, webhook xác nhận, kích hoạt subscription, cấp role và kiểm tra entitlement.

Hai mục này là tăng độ tin cậy phát hành; chúng không chặn việc sử dụng các luồng Casual hiện có ở local.
