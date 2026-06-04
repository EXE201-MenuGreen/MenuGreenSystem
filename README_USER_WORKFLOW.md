# README WORKFLOW NGƯỜI DÙNG - MENUGREEN

Tài liệu mô tả đầy đủ workflow tính năng dành cho người dùng (User) trên ứng dụng MenuGreen, đồng thời tổng hợp trạng thái triển khai UI/API và kế hoạch các bước tiếp theo.

---

## 1) Mục tiêu tài liệu

- Chuẩn hóa hành trình người dùng từ đăng ký đến sử dụng nâng cao.
- Làm tài liệu tham chiếu chung cho Product, Dev, QA, BA.
- Xác định rõ phần đã chạy được, phần còn thiếu, và thứ tự triển khai tiếp theo.

---

## 2) Đối tượng và phạm vi

- **Đối tượng:** Người dùng cuối (end-user) của app MenuGreen.
- **Trong phạm vi:**
  - Đăng ký, đăng nhập, OTP, quên/đặt lại mật khẩu, quản lý phiên.
  - Hồ sơ cá nhân, hồ sơ sức khỏe, mục tiêu, dị ứng.
  - Tìm kiếm món ăn, gợi ý thực đơn, trợ lý AI.
  - Nhật ký ăn uống, calories/macro, theo dõi cân nặng.
  - Quản lý gói dịch vụ (xem gói, đăng ký, gia hạn, hủy).
- **Ngoài phạm vi:** Luồng Admin.

---

## 3) Tổng quan hành trình người dùng

1. Mở app -> Đăng ký tài khoản.
2. Xác thực OTP -> Kích hoạt tài khoản.
3. Đăng nhập -> Nhận access token + refresh token.
4. Thiết lập hồ sơ và dữ liệu sức khỏe nền.
5. Nhận gợi ý món ăn/thực đơn.
6. Ghi nhật ký ăn uống, theo dõi tiến độ.
7. Tương tác AI (nếu có).
8. Quản lý gói thành viên khi cần.

---

## 4) Workflow chi tiết theo giai đoạn

### 4.1 Guest và tạo tài khoản

#### Luồng chính
- Guest chọn Đăng ký.
- Nhập email và mật khẩu.
- Hệ thống kiểm tra email duy nhất.
- Gửi OTP qua email.
- User nhập OTP.
- Kích hoạt tài khoản thành công.

#### Ngoại lệ
- Email đã tồn tại.
- OTP sai/hết hạn.
- OTP nhập quá số lần cho phép.

#### Đầu ra
- Tài khoản ở trạng thái hoạt động, có thể đăng nhập.

---

### 4.2 Đăng nhập và quản lý phiên

#### Luồng chính
- User đăng nhập email/mật khẩu.
- Hệ thống cấp access token + refresh token.
- App tự refresh khi access token hết hạn.
- User logout khi cần.

#### Ngoại lệ
- Sai thông tin đăng nhập.
- Tài khoản chưa OTP.
- Refresh token hết hạn/không hợp lệ.

#### Đầu ra
- Phiên đăng nhập ổn định, giảm gián đoạn trong sử dụng.

---

### 4.3 Onboarding và thiết lập thông tin nền

#### Luồng chính
- Nhập thông tin cơ bản.
- Nhập thông số sức khỏe (chiều cao, cân nặng, mức độ vận động, mục tiêu...).
- Chọn danh sách dị ứng.
- Lưu dữ liệu onboarding.

#### Xử lý hệ thống
- Tính BMI, BMR, TDEE, Target Calories.
- Cập nhật mục tiêu macro theo mục tiêu người dùng.

#### Ngoại lệ
- Dữ liệu nhập không hợp lệ.
- Lỗi kết nối khi lưu.

#### Đầu ra
- User có baseline cá nhân hóa cho recommendation và tracking.

---

### 4.4 Quản lý hồ sơ cá nhân

#### Luồng chính
- Xem/sửa hồ sơ.
- Cập nhật hoặc xóa avatar.
- Đổi mật khẩu.

#### Ngoại lệ
- Sai mật khẩu hiện tại.
- Mật khẩu mới không đạt chính sách.
- Lưu profile thất bại do lỗi mạng.

#### Đầu ra
- Dữ liệu profile luôn đồng bộ với các module liên quan.

---

### 4.5 Quản lý dị ứng

#### Luồng chính
- Xem danh sách dị ứng.
- Thêm/sửa/xóa dị ứng.
- Hệ thống loại trừ món/nguyên liệu gây dị ứng khi gợi ý.

#### Đầu ra
- Gợi ý an toàn hơn cho người dùng.

---

### 4.6 Khám phá món ăn và công thức (đã triển khai)

#### Luồng chính
- Tab **Khám phá**: tìm món/công thức/nguyên liệu theo từ khóa.
- Lọc món: calories min/max, đạm (high/low), giá tối đa, category; **chỉ món an toàn** (`allergyMode=hide`).
- Cảnh báo/ẩn theo dị ứng user; khai báo dị ứng từ màn Khám phá.
- Chi tiết món (công thức liên quan, yêu thích, ghi nhật ký), chi tiết công thức (nguyên liệu, ghi nhật ký), chi tiết nguyên liệu (công thức liên quan).
- **Gợi ý an toàn** (icon gợi ý): rule-based có `excludeUserAllergies`.

#### Đầu ra
- User tìm nhanh món phù hợp mục tiêu, ngân sách và hạn chế dị ứng.

---

### 4.7 Gợi ý thực đơn rule-based

#### Luồng chính
- Chọn loại gợi ý: calories, eco-money, lunch, daily-menu, smart-schedule.
- Nhập tham số.
- Nhận danh sách đề xuất.

#### Xử lý hệ thống
- Lọc theo bộ quy tắc cố định, ưu tiên tốc độ phản hồi.

#### Đầu ra
- Danh sách món/meal plan phù hợp mục tiêu và ràng buộc.

---

### 4.8 Gợi ý AI và trợ lý AI

#### Luồng chính
- Chat tư vấn dinh dưỡng.
- Đề xuất bữa ăn cá nhân hóa nâng cao.
- Tối ưu theo lịch sử, dị ứng, ngân sách, nguyên liệu sẵn có.

#### Fallback
- Nếu AI lỗi hoặc quá tải -> tự động fallback về rule-based.

#### Đầu ra
- Mức cá nhân hóa cao hơn so với rule-based.

---

### 4.9 Nhật ký ăn uống và theo dõi dinh dưỡng

#### Luồng chính
- Thêm/sửa/xóa món trong từng bữa.
- Tính calories từng bữa và cả ngày.
- Theo dõi macro thực tế so với mục tiêu.

#### Cảnh báo
- Cảnh báo khi macro lệch ngưỡng an toàn.

#### Đầu ra
- User theo dõi được mức tuân thủ mục tiêu dinh dưỡng.

---

### 4.10 Theo dõi cân nặng và tiến độ

#### Luồng chính
- Ghi cân nặng định kỳ.
- Xem biểu đồ tiến độ theo thời gian.
- Dashboard tổng hợp theo ngày/tuần/tháng.

#### Đầu ra
- User thấy rõ tiến độ thực tế.

---

### 4.11 Quản lý gói dịch vụ

#### Luồng chính
- Xem danh sách gói.
- Đăng ký/gia hạn/hủy gói.
- Xem gói hiện tại và lịch sử giao dịch.

#### Đầu ra
- User kiểm soát quyền truy cập tính năng nâng cao.

---

## 5) Ma trận coverage hiện tại (UI + API)

### 5.1 Đã dùng được trên UI và đã gọi API

- `4.1` Đăng ký + OTP.
- `4.2` Đăng nhập + refresh token nền + logout.
- `4.4` Quản lý profile, avatar, đổi mật khẩu.
- `4.5` Dị ứng (đang dùng trong onboarding).
- `4.11` Subscription (plans/current/history/subscribe/renew/cancel).

### 5.2 API đã có nhưng UI mới cover một phần

- `4.3` Onboarding sức khỏe:
  - UI 5 bước đã gọi API: Profile, HealthProfile, UserAiProfile, Allergy/UserAllergy, `Onboarding/complete` (NutritionSnapshot).
  - Gate vào app dựa `Profile/me/completion`; bước dị ứng chỉ chuyển tiếp khi lưu thành công.
- `4.9` Nutrition tracking:
  - API đã có cho meal-log/daily/dashboard.
  - UI đang ở mức demo/mock, chưa nối đầy đủ.
- `4.10` Weight tracking:
  - API ghi/sửa/xóa weight log đã có.
  - UI biểu đồ tiến độ chưa nối dữ liệu thực.

### 5.3 API có nhưng UI chưa triển khai thực tế

- `4.7` Recommendation rule-based nâng cao (smart-schedule, history/feedback UI — chưa có màn riêng ngoài gợi ý an toàn trong Khám phá).
- `4.8` AI assistant (tab AI đang placeholder).
- Notification workflow (API có, UI chưa có màn hình quản lý hoàn chỉnh).

---

## 6) Kế hoạch bước tiếp theo (P1/P2/P3)

### P1 - Hoàn thiện luồng cốt lõi đang dở (ưu tiên cao nhất)

- Nối dữ liệu thực cho Home và History:
  - Bỏ dữ liệu hard-code/mock.
  - Dùng API NutritionTracking để lấy daily/dashboard.
- Viết test tối thiểu cho luồng auth + onboarding + profile:
  - Sửa `widget_test.dart` mặc định thành test thật theo app hiện tại.

**Kết quả mong đợi P1**
- User đi từ đăng ký -> onboarding -> màn hình chính với dữ liệu thật.
- Dashboard lịch sử và chỉ số không còn dữ liệu mẫu.

### P2 - Mở khóa giá trị sử dụng hàng ngày

- Hoàn thiện Recommendation nâng cao (P2):
  - Smart-schedule, lịch sử/feedback, giải thích đề xuất.
- Triển khai màn hình ghi meal log và weight log:
  - CRUD + cập nhật dashboard real-time.

**Kết quả mong đợi P2**
- User dùng app hằng ngày được trọn chu trình gợi ý -> ghi nhận -> theo dõi.

### P3 - Nâng cao trải nghiệm và cá nhân hóa

- Triển khai UI AI assistant + các flow AI.
- Triển khai Notification settings và inbox thông báo.
- Bổ sung test E2E theo các workflow trọng yếu.

**Kết quả mong đợi P3**
- App đạt mức đầy đủ tính năng theo SRS cho user app.

---

## 7) Checklist triển khai kỹ thuật đề xuất

- Tạo `ViewModel/Controller` cho từng feature để tách UI khỏi gọi API trực tiếp.
- Chuẩn hóa model request/response cho:
  - Health profile
  - Nutrition tracking
  - Recommendation
- Chuẩn hóa trạng thái loading/error/empty cho tất cả màn hình.
- Chuẩn hóa message lỗi thân thiện theo từng luồng.
- Bổ sung logging và analytics sự kiện chính:
  - register_success
  - otp_verify_success
  - onboarding_completed
  - meal_logged
  - subscription_subscribed

---

## 8) Tiêu chí hoàn thành (Definition of Done)

- Mỗi workflow từ `4.1` đến `4.11` có:
  - Màn hình UI truy cập được.
  - Gọi API thật, không dùng dữ liệu hard-code cho dữ liệu nghiệp vụ.
  - Có xử lý lỗi và trạng thái loading/empty.
  - Có test tối thiểu (unit/widget/integration phù hợp).
- `flutter analyze` không có lỗi chặn build.
- Bộ test quan trọng chạy qua cho các luồng chính.

---

## 9) Điểm kiểm thử để xác nhận workflow

- Đăng ký mới, OTP đúng/sai/hết hạn.
- Đăng nhập thành công/thất bại, tình huống token hết hạn.
- Lưu profile và cập nhật lại chỉ số.
- Đồng bộ allergy vào recommendation.
- Gợi ý theo calories/budget/time.
- Fallback từ AI sang rule-based.
- Thêm/sửa/xóa meal log và cập nhật dashboard.
- Theo dõi cân nặng theo timeline.
- Đăng ký/gia hạn/hủy gói thành viên.

---

## 10) Kết luận

Hiện tại MenuGreen đã có nền tảng API khá đầy đủ cho user workflow cốt lõi, nhưng UI Flutter mới cover chắc phần Auth/Profile/Allergy/Subscription. Kế hoạch P1/P2/P3 ở trên giúp đưa app từ trạng thái "chạy được từng phần" sang trạng thái "cover đầy đủ workflow người dùng theo SRS".
