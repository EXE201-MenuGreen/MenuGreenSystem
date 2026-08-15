# MenuGreen — User API Contract (Giai đoạn 1–2)

Tài liệu này là nguồn đối chiếu cho Flutter khi kết nối các luồng người dùng. `ApiEndpoints.baseUrl` đã bao gồm hậu tố `/api`; vì vậy chỉ ghép phần đường dẫn sau `/api`, không thêm `/api` lần nữa.

## Quy ước chung

* API yêu cầu đăng nhập dùng `Authorization: Bearer <accessToken>`.
* Lỗi nghiệp vụ trả về `message` hoặc `Message`; Flutter phải hiển thị nội dung này thay vì coi mọi lỗi là lỗi mạng.
* Các ID trên đường dẫn là UUID. Ngày được truyền theo ISO-8601 (`yyyy-MM-dd` khi là ngày).

## Auth

| Mục đích | Method + path | Payload/ghi chú |
| --- | --- | --- |
| Đăng ký | `POST /Auth/register` | Tạo tài khoản và gửi OTP. |
| Xác thực OTP | `POST /Auth/verify-otp` | `{ email, otpCode }`. Response chỉ xác nhận OTP hợp lệ; **không trả token**. |
| Đăng nhập sau OTP | `POST /Auth/login` | `{ email, password }`; đây là bước trả access/refresh token. |
| Google sign-in | `POST /Auth/google` | `{ idToken }`. |
| Quên/đặt lại mật khẩu | `POST /Auth/forgot-password`, `POST /Auth/reset-password` | Theo DTO backend. |

## Onboarding atomic

Flutter giữ dữ liệu cục bộ trong 5 bước và chỉ ghi xuống server một lần ở cuối luồng:

| Dữ liệu | Method + path | Payload tối thiểu |
| --- | --- | --- |
| Hoàn tất 5 bước | `POST /Onboarding/complete-atomic` | `fullName`, `gender`, `dateOfBirth`, `heightCm`, `weightKg`, `activityLevel`, `goal`, tùy chọn `bodyFatPercent`, `targetCalories`, `eatingPattern`, `preferences`, và `allergies`. |
| Luồng cũ tương thích | `POST /Onboarding/complete` | Chỉ finalize một HealthProfile đã tồn tại; không dùng cho app mới. |

Nếu bất kỳ phần nào không hợp lệ, transaction rollback: không lưu Profile, HealthProfile, UserAiProfile hay allergy một phần.

## Kế hoạch, thay thế nguyên liệu và PT review

| Mục đích | Method + path |
| --- | --- |
| Tạo meal plan | `POST /MealPlan` |
| Đổi MealPlanItem thành MealLog | `POST /MealPlan/{planId}/items/{itemId}/convert-to-log` |
| Gợi ý thay nguyên liệu | `GET /Ingredient/{ingredientId}/substitutes?reason=not_available&maxPrice=&macroMatch=false` |
| Gợi ý theo công thức | `GET /Recipe/{recipeId}/substitute-ingredient/{ingredientId}` |
| Áp dụng thay thế vào plan | `POST /MealPlan/{planId}/items/{itemId}/substitute-ingredient` |
| Tạo yêu cầu PT | `POST /PtReview/reports` |
| PT gửi nhận xét bằng token | `POST /PtReview/shared-reports/{token}/submit` (không cần đăng nhập) |
| Người dùng xem/áp dụng/từ chối | `GET /PtReview/requests/{id}/result`, `POST /PtReview/requests/{id}/apply`, `POST /PtReview/requests/{id}/reject` |

`PtReview` dùng policy entitlement `GymFeatures`; người dùng cần subscription Gym đang hoạt động.

## Thanh toán subscription qua SePay

| Mục đích | Method + path | Payload |
| --- | --- | --- |
| Tạo đơn mua gói | `POST /payments/sepay/create-order` | `{ subscriptionPlanId, note? }` |
| Tạo đơn gia hạn | `POST /payments/sepay/create-renew-order` | `{ userSubscriptionId, note? }` |
| Xem đơn chờ | `GET /payments/sepay/pending` | Chỉ các đơn của người dùng hiện tại. |
| Kiểm tra trạng thái | `GET /payments/sepay/{paymentId}` | Chỉ chủ đơn. |
| Webhook SePay | `POST /payments/sepay/webhook` | Endpoint dành cho SePay, không gọi từ Flutter. |

Webhook cập nhật payment/subscription. Việc phân gói và mở/khóa tính năng theo subscription được hoãn lại đến sau khi hoàn thiện các luồng nhóm người dùng.

## Premium Programs

| Mục đích | Method + path |
| --- | --- |
| Catalog/chi tiết | `GET /PremiumPrograms`, `GET /PremiumPrograms/{id}` |
| Checkout/kích hoạt | `POST /PremiumPrograms/{id}/checkout`, `POST /PremiumPrograms/{id}/activate` với `{ startDate }` |
| Chương trình hiện tại/lịch sử | `GET /PremiumPrograms/my-active`, `GET /PremiumPrograms/my-programs` |
| Cột mốc, check-in | `GET /PremiumPrograms/my-active/milestones`, `POST /PremiumPrograms/my-active/milestones/{weekNumber}/checkin` với `{ weightKg, bodyFatPercent? }` |
| Tiến trình, tốt nghiệp, báo cáo | `GET /PremiumPrograms/my-active/progress-trend`, `POST /PremiumPrograms/my-active/graduate`, `GET /PremiumPrograms/my-active/wrap-up-report` |

Backend đã có contract này; UI/repository Premium Programs sẽ được triển khai ở Giai đoạn 6.
