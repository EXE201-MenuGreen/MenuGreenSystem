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

**Luồng chính**
- Guest chọn Đăng ký.
- Nhập email và mật khẩu.
- Hệ thống kiểm tra email duy nhất.
- Gửi OTP qua email.
- User nhập OTP.
- Kích hoạt tài khoản thành công.

**Ngoại lệ**
- Email đã tồn tại.
- OTP sai/hết hạn.
- OTP nhập quá số lần cho phép.

---

### 4.2 Đăng nhập và quản lý phiên

**Luồng chính**
- User đăng nhập email/mật khẩu.
- Hệ thống cấp access token + refresh token.
- App tự refresh khi access token hết hạn.
- User logout khi cần.

**Ngoại lệ**
- Sai thông tin đăng nhập.
- Tài khoản chưa OTP.
- Refresh token hết hạn/không hợp lệ.

---

### 4.3 Onboarding và thiết lập thông tin nền

**Luồng chính**
- Nhập thông tin cơ bản.
- Nhập thông số sức khỏe (chiều cao, cân nặng, mức độ vận động, mục tiêu...).
- Chọn danh sách dị ứng.
- Lưu dữ liệu onboarding.

**Xử lý hệ thống**
- Tính BMI, BMR, TDEE, Target Calories.
- Cập nhật mục tiêu macro theo mục tiêu người dùng.

---

### 4.4 Quản lý hồ sơ cá nhân

**Luồng chính**
- Xem/sửa hồ sơ.
- Cập nhật hoặc xóa avatar.
- Đổi mật khẩu.

---

### 4.5 Quản lý dị ứng

**Luồng chính**
- Xem danh sách dị ứng.
- Thêm/sửa/xóa dị ứng.
- Hệ thống loại trừ món/nguyên liệu gây dị ứng khi gợi ý.

---

### 4.6 Khám phá món ăn và công thức

**Luồng chính**
- Tìm kiếm món theo từ khóa.
- Lọc theo calories/protein/chi phí/thời gian/nhóm món.
- Xem chi tiết món ăn, thành phần, công thức.

---

### 4.7 Gợi ý thực đơn rule-based

**Luồng chính**
- Chọn loại gợi ý: calories, eco-money, lunch, daily-menu, smart-schedule.
- Nhập tham số.
- Nhận danh sách đề xuất.

---

### 4.8 Gợi ý AI và trợ lý AI

**Luồng chính**
- Chat tư vấn dinh dưỡng.
- Đề xuất bữa ăn cá nhân hóa nâng cao.
- Tối ưu theo lịch sử, dị ứng, ngân sách, nguyên liệu sẵn có.

**Fallback**
- Nếu AI lỗi hoặc quá tải -> tự động fallback về rule-based.

---

### 4.9 Nhật ký ăn uống và theo dõi dinh dưỡng

**Luồng chính**
- Thêm/sửa/xóa món trong từng bữa.
- Tính calories từng bữa và cả ngày.
- Theo dõi macro thực tế so với mục tiêu.

---

### 4.10 Theo dõi cân nặng và tiến độ

**Luồng chính**
- Ghi cân nặng định kỳ.
- Xem biểu đồ tiến độ theo thời gian.
- Dashboard tổng hợp theo ngày/tuần/tháng.

---

### 4.11 Quản lý gói dịch vụ

**Luồng chính**
- Xem danh sách gói.
- Đăng ký/gia hạn/hủy gói.
- Xem gói hiện tại và lịch sử giao dịch.

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
  - UI có các bước nhập liệu.
  - Chưa đồng bộ đầy đủ với lưu Health Profile cho toàn bộ bước.
- `4.9` Nutrition tracking:
  - API đã có cho meal-log/daily/dashboard.
  - UI đang ở mức demo/mock, chưa nối đầy đủ.
- `4.10` Weight tracking:
  - API ghi/sửa/xóa weight log đã có.
  - UI biểu đồ tiến độ chưa nối dữ liệu thực.

### 5.3 API có nhưng UI chưa triển khai thực tế

- `4.6` Khám phá món ăn/công thức (tab khám phá đang placeholder).
- `4.7` Recommendation rule-based (chưa có màn hình/flow gọi API thực).
- `4.8` AI assistant (tab AI đang placeholder).
- Notification workflow (API có, UI chưa có màn hình quản lý hoàn chỉnh).

---

## 6) Kế hoạch bước tiếp theo (P1/P2/P3)

### P1 - Hoàn thiện luồng cốt lõi đang dở (ưu tiên cao nhất)

- Hoàn tất lưu onboarding vào backend:
  - Nối các bước `BasicInfo`, `UserType`, `Preferences`, `CalorieGoal` vào payload thật.
  - Đồng bộ với API profile/health-profile phù hợp.
- Nối dữ liệu thực cho Home và History:
  - Bỏ dữ liệu hard-code/mock.
  - Dùng API NutritionTracking để lấy daily/dashboard.
- Viết test tối thiểu cho luồng auth + onboarding + profile:
  - Sửa `widget_test.dart` mặc định thành test thật theo app hiện tại.

**Kết quả mong đợi P1**
- User đi từ đăng ký -> onboarding -> màn hình chính với dữ liệu thật.
- Dashboard lịch sử và chỉ số không còn dữ liệu mẫu.

### P2 - Mở khóa giá trị sử dụng hàng ngày

- Triển khai màn hình Khám phá (Food/Recipe/Ingredient):
  - List, filter, detail.
- Triển khai màn hình Recommendation rule-based:
  - Calories/Eco/Lunch/Daily-menu/Smart-schedule.
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

## 9) Kết luận

Hiện tại MenuGreen đã có nền tảng API khá đầy đủ cho user workflow cốt lõi, nhưng UI Flutter mới cover chắc phần Auth/Profile/Allergy/Subscription. Kế hoạch P1/P2/P3 ở trên giúp đưa app từ trạng thái “chạy được từng phần” sang trạng thái “cover đầy đủ workflow người dùng theo SRS”.

# README WORKFLOW NGƯỜI DÙNG - MENUGREEN

Tài liệu này mô tả chi tiết toàn bộ workflow tính năng dành cho người dùng (User) trên ứng dụng MenuGreen, tập trung vào luồng sử dụng thực tế trên mobile app.

---

## 1) Mục tiêu tài liệu

- Chuẩn hóa hành trình sử dụng app từ lúc chưa có tài khoản đến khi sử dụng nâng cao.
- Làm tài liệu tham chiếu cho Product, Dev, QA, BA khi triển khai và kiểm thử.
- Xác định rõ đầu vào, xử lý, đầu ra, và các trường hợp ngoại lệ của mỗi luồng.

---

## 2) Đối tượng và phạm vi

- Đối tượng: Người dùng cuối (end-user) sử dụng app MenuGreen.
- Trong phạm vi:
  - Đăng ký, đăng nhập, xác thực OTP, quản lý phiên.
  - Hồ sơ cá nhân, hồ sơ sức khỏe, mục tiêu, dị ứng.
  - Tìm kiếm món ăn, gợi ý thực đơn, AI assistant.
  - Nhật ký ăn uống, theo dõi calories/macro/cân nặng.
  - Quản lý gói dịch vụ (xem gói, đăng ký, gia hạn, hủy).
- Ngoài phạm vi:
  - Các luồng quản trị Admin.

---

## 3) Tổng quan hành trình người dùng (User Journey)

1. Guest mở app -> đăng ký tài khoản.
2. Xác thực OTP -> tài khoản kích hoạt.
3. Đăng nhập -> nhận access token và refresh token.
4. Thiết lập hồ sơ cá nhân + thông số sức khỏe + mục tiêu + dị ứng.
5. Sử dụng hệ thống tìm kiếm/gợi ý món ăn.
6. Ghi nhật ký bữa ăn và theo dõi tiến độ theo ngày/tuần/tháng.
7. Tương tác với AI (nếu có) để nhận gợi ý cá nhân hóa sâu.
8. Quản lý gói thành viên khi cần mở rộng tính năng.

---

## 4) Workflow chi tiết theo giai đoạn

### 4.1 Giai đoạn Guest và tạo tài khoản

#### Luồng chính
- Bước 1: Guest chọn Đăng ký.
- Bước 2: Nhập email và mật khẩu.
- Bước 3: Hệ thống kiểm tra email đã tồn tại chưa.
- Bước 4: Nếu hợp lệ, hệ thống tạo tài khoản chờ kích hoạt và gửi OTP.
- Bước 5: User nhập OTP.
- Bước 6: Hệ thống xác minh OTP, kích hoạt tài khoản.

#### Ngoại lệ
- Email đã tồn tại -> thông báo lỗi, yêu cầu dùng email khác.
- OTP sai/hết hạn -> thông báo và cho phép gửi lại OTP.
- OTP nhập quá số lần cho phép -> tạm khóa chức năng nhập OTP trong một khoảng thời gian.

#### Đầu ra
- Tài khoản chuyển trạng thái sang Hoạt động, user có thể đăng nhập.

---

### 4.2 Đăng nhập và quản lý phiên

#### Luồng chính
- Bước 1: User nhập email và mật khẩu.
- Bước 2: Hệ thống xác thực thông tin đăng nhập.
- Bước 3: Nếu thành công, hệ thống trả về access token + refresh token.
- Bước 4: App lưu token an toàn và vào màn hình chính.
- Bước 5: Khi access token hết hạn, app tự động dùng refresh token để cấp mới.
- Bước 6: User logout -> xóa session trên client và gửi yêu cầu hủy token.

#### Ngoại lệ
- Sai email/mật khẩu -> thông báo đăng nhập thất bại.
- Tài khoản chưa xác thực OTP -> điều hướng sang màn hình xác thực OTP.
- Refresh token không hợp lệ/hết hạn -> buộc đăng nhập lại.

#### Đầu ra
- User duy trì phiên làm việc ổn định, không bị gián đoạn khi token ngắn hạn hết hạn.

---

### 4.3 Onboarding và thiết lập thông tin nền

#### Luồng chính
- Bước 1: Sau đăng nhập lần đầu, user vào onboarding.
- Bước 2: Nhập thông tin cơ bản (họ tên, giới tính, ngày sinh nếu có).
- Bước 3: Nhập thông số sức khỏe:
  - Chiều cao (cm)
  - Cân nặng (kg)
  - Tỷ lệ mỡ (tùy chọn)
  - Mức độ vận động
  - Mục tiêu (giảm cân/tăng cân/giữ cân/tăng cơ giảm mỡ)
- Bước 4: Chọn danh sách dị ứng.
- Bước 5: Lưu toàn bộ dữ liệu.

#### Xử lý hệ thống
- Tự động tính BMI, BMR, TDEE, Target Calories.
- Tự động cập nhật mục tiêu macro (Protein/Carbs/Fat) theo mục tiêu cá nhân.

#### Ngoại lệ
- Giá trị nhập không hợp lệ (âm, rỗng, sai định dạng) -> báo lỗi tại chỗ.
- Lỗi kết nối khi lưu -> cho phép thử lại.

#### Đầu ra
- User có baseline cá nhân hóa cho toàn bộ hệ thống gợi ý và theo dõi.

---

### 4.4 Quản lý hồ sơ cá nhân

#### Luồng chính
- Xem thông tin profile hiện tại.
- Cập nhật thông tin (họ tên, giới tính, chỉ số cơ thể, mức vận động, mục tiêu).
- Cập nhật avatar bằng URL/tệp (tùy implementation).
- Xóa avatar.
- Đổi mật khẩu khi cần.

#### Ngoại lệ
- Mật khẩu hiện tại sai khi đổi mật khẩu.
- Mật khẩu mới không đạt chính sách.
- Cập nhật profile thất bại do lỗi mạng.

#### Đầu ra
- Dữ liệu profile luôn được đồng bộ và sử dụng ngay trong recommendation/tracking.

---

### 4.5 Quản lý dị ứng

#### Luồng chính
- User vào màn hình dị ứng.
- Xem danh sách đã thiết lập.
- Thêm dị ứng mới.
- Chỉnh sửa tên/mục dị ứng (nếu app có luồng sửa trực tiếp).
- Xóa dị ứng không còn áp dụng.

#### Xử lý hệ thống
- Hệ thống loại bỏ món/nguyên liệu trùng với danh sách dị ứng khi gợi ý.

#### Đầu ra
- Gợi ý món ăn an toàn hơn, giảm rủi ro cho người dùng.

---

### 4.6 Khám phá món ăn và công thức

#### Luồng chính
- User tìm món ăn theo từ khóa.
- Áp dụng bộ lọc:
  - Khoảng calories
  - Protein cao/thấp
  - Giới hạn chi phí
  - Thời gian chế biến
  - Nhóm món (chay/mặn/keto...)
- Xem chi tiết món:
  - Calories
  - Macro và chỉ số dinh dưỡng
  - Giá ước tính
  - Nguyên liệu
  - Công thức nấu

#### Đầu ra
- User tìm nhanh được món phù hợp mục tiêu và điều kiện thực tế.

---

### 4.7 Gợi ý thực đơn rule-based

#### Luồng chính
- User chọn kiểu gợi ý:
  - Theo calories mục tiêu
  - Eco-money (chi phí + thời gian)
  - Gợi ý bữa trưa nhanh
  - Tự động lập menu ngày
  - Smart schedule nhắc nhở nấu ăn
- User nhập tham số đầu vào (budget, giờ ăn, giới hạn thời gian...).
- Hệ thống trả về danh sách đề xuất.

#### Xử lý hệ thống
- Lọc theo bộ quy tắc cố định (rule-based), ưu tiên tốc độ phản hồi.

#### Đầu ra
- Danh sách món/meal plan hợp lý với mục tiêu và ràng buộc.

---

### 4.8 Gợi ý AI và trợ lý AI

#### Luồng chính
- User chat với trợ lý AI để hỏi đáp dinh dưỡng.
- User yêu cầu AI đề xuất bữa ăn, lập lịch tuần, tối ưu nguyên liệu tồn.
- AI sử dụng dữ liệu ngữ cảnh:
  - Mục tiêu sức khỏe
  - Dị ứng
  - Lịch sử ăn uống
  - Ngân sách
  - Nguyên liệu hiện có

#### Quy tắc fallback
- Nếu AI service lỗi/chậm/quá tải -> tự động fallback về rule-based để đảm bảo trải nghiệm liên tục.

#### Đầu ra
- Gợi ý cá nhân hóa sâu hơn so với rule-based.

---

### 4.9 Nhật ký ăn uống và theo dõi dinh dưỡng

#### Luồng chính
- Thêm món vào các bữa: sáng, trưa, tối, bữa phụ.
- Sửa/xóa món đã ghi.
- Xem tổng calories từng bữa và cả ngày.
- Theo dõi tổng macro trong ngày.
- So sánh thực tế với mục tiêu.

#### Cảnh báo
- Nếu macro lệch quá ngưỡng an toàn -> hiện cảnh báo để user điều chỉnh.

#### Đầu ra
- User biết rõ mình đang ăn bao nhiêu và có đúng hướng mục tiêu hay không.

---

### 4.10 Theo dõi cân nặng và tiến độ

#### Luồng chính
- User ghi cân nặng định kỳ (có thể kèm body fat).
- Hệ thống vẽ biểu đồ xu hướng theo ngày/tuần/tháng.
- Dashboard tổng hợp:
  - Lượng ăn vào
  - Calories
  - Macro
  - Biến động cân nặng

#### Đầu ra
- User thấy được tiến độ thực tế và mức độ tuân thủ kế hoạch.

---

### 4.11 Quản lý gói dịch vụ (Subscription)

#### Luồng chính
- Xem danh sách các gói (Free/Premium/Pro) và quyền lợi.
- Đăng ký gói mới.
- Gia hạn gói hiện tại.
- Hủy gói nếu không có nhu cầu.
- Xem trạng thái gói và lịch sử giao dịch.

#### Đầu ra
- User kiểm soát được quyền truy cập tính năng nâng cao theo nhu cầu.

---

## 5) Luồng dữ liệu tổng hợp (Input -> Process -> Output)

### Input
- Dữ liệu tài khoản: email, mật khẩu, OTP.
- Dữ liệu cá nhân và sức khỏe: profile + metric cơ thể + mục tiêu + dị ứng.
- Dữ liệu hành vi sử dụng: nhật ký bữa ăn, cân nặng, truy vấn gợi ý.

### Process
- Xác thực và quản lý token.
- Tính toán chỉ số dinh dưỡng và mục tiêu.
- Lọc món theo quy tắc / AI cá nhân hóa.
- Tổng hợp và đối chiếu thực tế với mục tiêu.

### Output
- Dashboard tiến độ.
- Danh sách món/gợi ý thực đơn.
- Cảnh báo lệch mục tiêu.
- Gợi ý cải thiện theo tình trạng thực tế.

---

## 6) Điểm kiểm thử để xác nhận workflow

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

## 7) Kết luận

Workflow user trên MenuGreen được xây dựng theo mô hình "cá nhân hóa liên tục":

1. Xác thực và thu thập dữ liệu nền.
2. Phân tích và gợi ý theo mục tiêu.
3. Ghi nhận hành vi thực tế.
4. Phản hồi và tối ưu để đạt kết quả sức khỏe bền vững.

Tài liệu này có thể dùng trực tiếp cho:
- Đặc tả use case chi tiết.
- Viết test case UAT/E2E.
- Căn cứ thiết kế màn hình và API mapping cho app mobile.

# README WORKFLOW NGUOI DUNG - MENUGREEN

Tai lieu nay mo ta chi tiet toan bo workflow tinh nang danh cho nguoi dung (User) tren ung dung MenuGreen, tap trung vao luong su dung thuc te tren mobile app.

---

## 1) Muc tieu tai lieu

- Chuan hoa hanh trinh su dung app tu luc chua co tai khoan den khi su dung nang cao.
- Lam tai lieu tham chieu cho Product, Dev, QA, BA khi trien khai va kiem thu.
- Xac dinh ro dau vao, xu ly, dau ra, va cac truong hop ngoai le cua moi luong.

---

## 2) Doi tuong va pham vi

- Doi tuong: Nguoi dung cuoi (end-user) su dung app MenuGreen.
- Trong pham vi:
  - Dang ky, dang nhap, xac thuc OTP, quan ly phien.
  - Ho so ca nhan, ho so suc khoe, muc tieu, di ung.
  - Tim kiem mon an, goi y thuc don, AI assistant.
  - Nhat ky an uong, theo doi calories/macro/can nang.
  - Quan ly goi dich vu (xem goi, dang ky, gia han, huy).
- Ngoai pham vi:
  - Cac luong quan tri Admin.

---

## 3) Tong quan hanh trinh nguoi dung (User Journey)

1. Guest mo app -> dang ky tai khoan.
2. Xac thuc OTP -> tai khoan kich hoat.
3. Dang nhap -> nhan access token va refresh token.
4. Thiet lap ho so ca nhan + thong so suc khoe + muc tieu + di ung.
5. Su dung he thong tim kiem/goi y mon an.
6. Ghi nhat ky bua an va theo doi tien do theo ngay/tuan/thang.
7. Tuong tac voi AI (neu co) de nhan goi y ca nhan hoa sau.
8. Quan ly goi thanh vien khi can mo rong tinh nang.

---

## 4) Workflow chi tiet theo giai doan

### 4.1 Giai doan Guest va tao tai khoan

#### Luong chinh
- Buoc 1: Guest chon Dang ky.
- Buoc 2: Nhap email va mat khau.
- Buoc 3: He thong kiem tra email da ton tai chua.
- Buoc 4: Neu hop le, he thong tao tai khoan cho kich hoat va gui OTP.
- Buoc 5: User nhap OTP.
- Buoc 6: He thong xac minh OTP, kich hoat tai khoan.

#### Ngoai le
- Email da ton tai -> thong bao loi, yeu cau dung email khac.
- OTP sai/het han -> thong bao va cho phep gui lai OTP.
- OTP nhap qua so lan cho phep -> tam khoa chuc nang nhap OTP trong mot khoang thoi gian.

#### Dau ra
- Tai khoan chuyen trang thai sang Hoat dong, user co the dang nhap.

---

### 4.2 Dang nhap va quan ly phien

#### Luong chinh
- Buoc 1: User nhap email va mat khau.
- Buoc 2: He thong xac thuc thong tin dang nhap.
- Buoc 3: Neu thanh cong, he thong tra ve access token + refresh token.
- Buoc 4: App luu token an toan va vao man hinh chinh.
- Buoc 5: Khi access token het han, app tu dong dung refresh token de cap moi.
- Buoc 6: User logout -> xoa session tren client va gui yeu cau huy token.

#### Ngoai le
- Sai email/mat khau -> thong bao dang nhap that bai.
- Tai khoan chua xac thuc OTP -> dieu huong sang man hinh xac thuc OTP.
- Refresh token khong hop le/het han -> buoc dang nhap lai.

#### Dau ra
- User duy tri phien lam viec on dinh, khong bi gian doan khi token ngan han het han.

---

### 4.3 Onboarding va thiet lap thong tin nen

#### Luong chinh
- Buoc 1: Sau dang nhap lan dau, user vao onboarding.
- Buoc 2: Nhap thong tin co ban (ho ten, gioi tinh, ngay sinh neu co).
- Buoc 3: Nhap thong so suc khoe:
  - Chieu cao (cm)
  - Can nang (kg)
  - Ty le mo (tuy chon)
  - Muc do van dong
  - Muc tieu (giam can/tang can/giu can/tang co giam mo)
- Buoc 4: Chon danh sach di ung.
- Buoc 5: Luu toan bo du lieu.

#### Xu ly he thong
- Tu dong tinh BMI, BMR, TDEE, Target Calories.
- Tu dong cap nhat muc tieu macro (Protein/Carbs/Fat) theo muc tieu ca nhan.

#### Ngoai le
- Gia tri nhap khong hop le (am, rong, sai dinh dang) -> bao loi tai cho.
- Loi ket noi khi luu -> cho phep thu lai.

#### Dau ra
- User co baseline ca nhan hoa cho toan bo he thong goi y va theo doi.

---

### 4.4 Quan ly ho so ca nhan

#### Luong chinh
- Xem thong tin profile hien tai.
- Cap nhat thong tin (ho ten, gioi tinh, chi so co the, muc van dong, muc tieu).
- Cap nhat avatar bang URL/tep (tuy implementation).
- Xoa avatar.
- Doi mat khau khi can.

#### Ngoai le
- Mat khau hien tai sai khi doi mat khau.
- Mat khau moi khong dat chinh sach.
- Cap nhat profile that bai do loi mang.

#### Dau ra
- Du lieu profile luon duoc dong bo va su dung ngay trong recommendation/tracking.

---

### 4.5 Quan ly di ung

#### Luong chinh
- User vao man hinh di ung.
- Xem danh sach da thiet lap.
- Them di ung moi.
- Chinh sua ten/muc di ung (neu app co luong sua truc tiep).
- Xoa di ung khong con ap dung.

#### Xu ly he thong
- He thong loai bo mon/nguyen lieu trung voi danh sach di ung khi goi y.

#### Dau ra
- Goi y mon an an toan hon, giam rui ro cho nguoi dung.

---

### 4.6 Kham pha mon an va cong thuc

#### Luong chinh
- User tim mon an theo tu khoa.
- Ap dung bo loc:
  - Khoang calories
  - Protein cao/thap
  - Gioi han chi phi
  - Thoi gian che bien
  - Nhom mon (chay/man/keto...)
- Xem chi tiet mon:
  - Calories
  - Macro va chi so dinh duong
  - Gia uoc tinh
  - Nguyen lieu
  - Cong thuc nau

#### Dau ra
- User tim nhanh duoc mon phu hop muc tieu va dieu kien thuc te.

---

### 4.7 Goi y thuc don rule-based

#### Luong chinh
- User chon kieu goi y:
  - Theo calories muc tieu
  - Eco-money (chi phi + thoi gian)
  - Goi y bua trua nhanh
  - Tu dong lap menu ngay
  - Smart schedule nhac nho nau an
- User nhap tham so dau vao (budget, gio an, gioi han thoi gian...).
- He thong tra ve danh sach de xuat.

#### Xu ly he thong
- Loc theo bo quy tac co dinh (rule-based), uu tien toc do phan hoi.

#### Dau ra
- Danh sach mon/meal plan hop ly voi muc tieu va rang buoc.

---

### 4.8 Goi y AI va tro ly AI

#### Luong chinh
- User chat voi tro ly AI de hoi dap dinh duong.
- User yeu cau AI de xuat bua an, lap lich tuan, toi uu nguyen lieu ton.
- AI su dung du lieu ngu canh:
  - Muc tieu suc khoe
  - Di ung
  - Lich su an uong
  - Ngan sach
  - Nguyen lieu hien co

#### Quy tac fallback
- Neu AI service loi/cham/qua tai -> tu dong fallback ve rule-based de dam bao trai nghiem lien tuc.

#### Dau ra
- Goi y ca nhan hoa sau hon so voi rule-based.

---

### 4.9 Nhat ky an uong va theo doi dinh duong

#### Luong chinh
- Them mon vao cac bua: sang, trua, toi, bua phu.
- Sua/xoa mon da ghi.
- Xem tong calories tung bua va ca ngay.
- Theo doi tong macro trong ngay.
- So sanh thuc te voi muc tieu.

#### Canh bao
- Neu macro lech qua nguong an toan -> hien canh bao de user dieu chinh.

#### Dau ra
- User biet ro minh dang an bao nhieu va co dung huong muc tieu hay khong.

---

### 4.10 Theo doi can nang va tien do

#### Luong chinh
- User ghi can nang dinh ky (co the kem body fat).
- He thong ve bieu do xu huong theo ngay/tuan/thang.
- Dashboard tong hop:
  - Luong an vao
  - Calories
  - Macro
  - Bien dong can nang

#### Dau ra
- User thay duoc tien do thuc te va muc do tuan thu ke hoach.

---

### 4.11 Quan ly goi dich vu (Subscription)

#### Luong chinh
- Xem danh sach cac goi (Free/Premium/Pro) va quyen loi.
- Dang ky goi moi.
- Gia han goi hien tai.
- Huy goi neu khong co nhu cau.
- Xem trang thai goi va lich su giao dich.

#### Dau ra
- User kiem soat duoc quyen truy cap tinh nang nang cao theo nhu cau.

---

## 5) Luong du lieu tong hop (Input -> Process -> Output)

### Input
- Du lieu tai khoan: email, mat khau, OTP.
- Du lieu ca nhan va suc khoe: profile + metric co the + muc tieu + di ung.
- Du lieu hanh vi su dung: nhat ky bua an, can nang, truy van goi y.

### Process
- Xac thuc va quan ly token.
- Tinh toan chi so dinh duong va muc tieu.
- Loc mon theo quy tac / AI ca nhan hoa.
- Tong hop va doi chieu thuc te voi muc tieu.

### Output
- Dashboard tien do.
- Danh sach mon/goi y thuc don.
- Canh bao lech muc tieu.
- Goi y cai thien theo tinh trang thuc te.

---

## 6) Diem kiem thu de xac nhan workflow

- Dang ky moi, OTP dung/sai/het han.
- Dang nhap thanh cong/that bai, tinh huong token het han.
- Luu profile va cap nhat lai chi so.
- Dong bo allergy vao recommendation.
- Goi y theo calories/budget/time.
- Fallback tu AI sang rule-based.
- Them/sua/xoa meal log va cap nhat dashboard.
- Theo doi can nang theo timeline.
- Dang ky/gia han/huy goi thanh vien.

---

## 7) Ket luan

Workflow user tren MenuGreen duoc xay dung theo mo hinh "ca nhan hoa lien tuc":

1. Xac thuc va thu thap du lieu nen.
2. Phan tich va goi y theo muc tieu.
3. Ghi nhan hanh vi thuc te.
4. Phan hoi va toi uu de dat ket qua suc khoe ben vung.

Tai lieu nay co the dung truc tiep cho:
- Dac ta use case chi tiet.
- Viet test case UAT/E2E.
- Can cu thiet ke man hinh va API mapping cho app mobile.

