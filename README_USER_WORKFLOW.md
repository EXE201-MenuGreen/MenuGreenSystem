# README WORKFLOW NGƯỜI DÙNG - MENUGREEN

Tài liệu mô tả đầy đủ workflow tính năng dành cho người dùng (User) trên ứng dụng MenuGreen, đồng thời tổng hợp trạng thái triển khai UI/API và kế hoạch các bước tiếp theo.

**Cập nhật:** 2026-06-04 · Bản đồ hệ thống: [`README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md`](README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md) · Thanh toán: [`README_SEPAY_PAYMENT_WORKFLOW.md`](README_SEPAY_PAYMENT_WORKFLOW.md)

---

## 1) Mục tiêu tài liệu

- Chuẩn hóa hành trình người dùng từ đăng ký đến sử dụng nâng cao.
- Làm tài liệu tham chiếu chung cho Product, Dev, QA, BA.
- Xác định rõ phần đã chạy được, phần còn thiếu, và thứ tự triển khai tiếp theo.

---

## 2) Đối tượng và phạm vi

- **Đối tượng:** Người dùng cuối (end-user) của app MenuGreen.
- **Trong phạm vi:**
  - Đăng ký, đăng nhập, OTP, quên/đặt lại mật khẩu, Google sign-in, quản lý phiên.
  - Onboarding: hồ sơ cá nhân, sức khỏe, mục tiêu, dị ứng, hồ sơ AI.
  - Khám phá món/công thức/nguyên liệu, gợi ý an toàn theo dị ứng.
  - Nhật ký ăn uống, calories/macro, dashboard ngày/tuần/tháng, theo dõi cân nặng.
  - Gợi ý rule-based (một phần); trợ lý AI (chưa UI đầy đủ).
  - Quản lý gói dịch vụ (SePay).
- **Ngoài phạm vi:** Luồng Admin.

**Quy ước khi phát triển thêm:** API trả message **tiếng Anh**; UI user-facing **tiếng Việt** (dịch qua `ApiMessageTranslator` / `localizeAuthMessage`). Chi tiết: `.cursor/rules/backend-english-frontend-vietnamese-i18n.mdc`.

---

## 3) Tổng quan hành trình người dùng

1. Mở app → Đăng ký / đăng nhập (email hoặc Google).
2. Xác thực OTP (nếu đăng ký email) → Kích hoạt tài khoản.
3. Onboarding 5 bước → baseline sức khỏe + dị ứng + snapshot dinh dưỡng.
4. **Trang chủ:** tiến độ calo/macro hôm nay, nhật ký bữa ăn, thêm bữa nhanh.
5. **Khám phá:** tìm món, lọc dị ứng, gợi ý an toàn, ghi log từ chi tiết món/công thức.
6. **Lịch sử:** dashboard ngày/tuần/tháng, heatmap, biểu đồ calo/cân, CRUD meal & weight.
7. Tab AI (placeholder) / Gói thành viên khi cần nâng cấp.

---

## 4) Workflow chi tiết theo giai đoạn

### 4.1 Guest và tạo tài khoản (Đã làm)

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

### 4.2 Đăng nhập và quản lý phiên (Đã làm)

#### Luồng chính
- User đăng nhập email/mật khẩu hoặc Google.
- Hệ thống cấp access token + refresh token.
- App tự refresh khi access token hết hạn (`ApiClient`).
- User logout khi cần.

#### Xử lý UI
- `AuthRepository` dịch message API qua `localizeAuthMessage` trước khi trả về màn hình.

#### Ngoại lệ
- Sai thông tin đăng nhập.
- Tài khoản chưa OTP.
- Refresh token hết hạn/không hợp lệ.

#### Đầu ra
- Phiên đăng nhập ổn định, giảm gián đoạn trong sử dụng.

---

### 4.3 Onboarding và thiết lập thông tin nền (Đã làm)

#### Luồng chính
- `OnboardingScreen` 5 bước: thông tin cơ bản, sức khỏe, mục tiêu, dị ứng, hoàn tất.
- Gọi API: `Profile`, `HealthProfile`, `UserAiProfile`, `Allergy` / `UserAllergy`, `POST Onboarding/complete`.
- Gate vào app: `Profile/me/completion` — user chưa hoàn tất onboarding được điều hướng lại.

#### Xử lý hệ thống
- Tính BMI, BMR, TDEE, target calories/macro.
- Tạo `NutritionSnapshot` ban đầu khi hoàn tất onboarding.

#### Ngoại lệ
- Dữ liệu không hợp lệ (API message tiếng Anh → UI tiếng Việt).
- Thiếu chiều cao/cân nặng khi complete.

#### Đầu ra
- Baseline cá nhân hóa cho recommendation và tracking.

---

### 4.4 Quản lý hồ sơ cá nhân (Đã làm)

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

### 4.5 Quản lý dị ứng (Đã làm)

#### Luồng chính
- Xem danh sách dị ứng.
- Thêm/sửa/xóa dị ứng.
- Hệ thống loại trừ món/nguyên liệu gây dị ứng khi gợi ý.

#### Đầu ra
- Gợi ý an toàn hơn cho người dùng.

---

### 4.6 Khám phá món ăn và công thức (Đã làm)

#### Luồng chính
- Tab **Khám phá**: tìm món/công thức/nguyên liệu theo từ khóa.
- Lọc món: calories min/max, đạm (high/low), giá tối đa, category; **chỉ món an toàn** (`allergyMode=hide`).
- Cảnh báo/ẩn theo dị ứng user; khai báo dị ứng từ màn Khám phá.
- Chi tiết món (công thức liên quan, yêu thích, ghi nhật ký), chi tiết công thức (nguyên liệu, ghi nhật ký), chi tiết nguyên liệu (công thức liên quan).
- **Gợi ý an toàn** (icon gợi ý): rule-based có `excludeUserAllergies`.

#### Đầu ra
- User tìm nhanh món phù hợp mục tiêu, ngân sách và hạn chế dị ứng.

---

### 4.7 Gợi ý thực đơn rule-based (một phần)

#### Luồng chính
- **Đã có:** `SafeRecommendationsScreen` từ Khám phá — calories, lunch, eco, daily-menu với `excludeUserAllergies=true`.
- **Chưa có UI riêng:** smart-schedule, lịch sử đề xuất, feedback, giải thích chi tiết từng món.
- Trạng thái tổng quan: các API gợi ý an toàn trong phạm vi hiện tại đã làm.

#### Xử lý hệ thống
- Lọc theo quy tắc + profile/dị ứng user.

#### Đầu ra
- Danh sách món/meal gợi ý an toàn và phù hợp mục tiêu (phạm vi hiện tại).

---

### 4.8 Gợi ý AI và trợ lý AI (Chưa hoàn thiện)

#### Luồng chính
- Chat tư vấn dinh dưỡng.
- Đề xuất bữa ăn cá nhân hóa nâng cao.
- Tối ưu theo lịch sử, dị ứng, ngân sách, nguyên liệu sẵn có.

#### Fallback
- Nếu AI lỗi hoặc quá tải -> tự động fallback về rule-based.

#### Đầu ra
- Mức cá nhân hóa cao hơn so với rule-based.

---

### 4.9 Nhật ký ăn uống và theo dõi dinh dưỡng (Đã làm — cốt lõi 100%)

#### Luồng chính
- **Ghi log:** `showMealLogSheet` — từ Trang chủ, Lịch sử, Khám phá (chi tiết món/công thức).
  - Món (`food`): `quantityG` = gram thực tế.
  - Công thức (`recipe`): `quantityG / 100` = số khẩu phần (100 = 1 phần).
- **Sửa/xóa:** menu trên từng dòng nhật ký trong tab Lịch sử (`meal_log_edit_sheet`).
- **Xem chi tiết:** chạm món trên Trang chủ / Lịch sử → `FoodDetailScreen` / `RecipeDetailScreen`.
- **Đồng bộ:** sau khi ghi/sửa/xóa, Trang chủ và Lịch sử refresh qua `MainScreen.onTrackingUpdated`.

#### API (backend production: `https://menugreensystem.onrender.com/api`)
- `POST/PUT/DELETE /NutritionTracking/meal-logs` (Đã làm)
- `GET /NutritionTracking/daily?date=` (Đã làm)
- `GET /NutritionTracking/dashboard?range=day|week|month` (tùy chọn `startDate`/`endDate`) (Đã làm)

#### UI
- **Trang chủ:** card calo/macro, danh sách bữa hôm nay, nút Thêm bữa ăn, empty state + Khám phá.
- **Lịch sử:** `DailySummaryCard`, biểu đồ calo (`fl_chart`), heatmap % mục tiêu, toggle Ngày/Tuần/Tháng.

#### Cảnh báo
- API: `WarningMessages` (tiếng Anh), `HasWarning`.
- UI: `NutritionWarningMessages` + `ApiMessageTranslator` → hiển thị tiếng Việt (calo ±10%, macro ±15%).

#### Đầu ra
- User theo dõi tuân thủ mục tiêu dinh dưỡng theo ngày/tuần/tháng.

---

### 4.10 Theo dõi cân nặng và tiến độ (đã triển khai)

#### Luồng chính
- Ghi/sửa/xóa cân nặng trong tab **Lịch sử** (`weight_log_sheet`).
- Biểu đồ xu hướng cân (`weight_trend_chart`) cùng dashboard calo.

#### API
- `POST/PUT/DELETE /NutritionTracking/weight-logs`
- Dữ liệu weight gộp trong `GET /NutritionTracking/dashboard`

#### Đầu ra
- User thấy tiến độ cân nặng và dinh dưỡng trên cùng màn Lịch sử.

---

### 4.11 Quản lý gói dịch vụ (Đã làm)

#### Luồng chính
- Xem danh sách gói.
- Đăng ký/gia hạn/hủy gói.
- Xem gói hiện tại và lịch sử giao dịch.

#### Đầu ra
- User kiểm soát quyền truy cập tính năng nâng cao.

---

## 5) Ma trận coverage hiện tại (UI + API)

| Mã | Workflow | UI | API | Ghi chú |
|----|----------|----|-----|---------|
| 4.1 | Đăng ký + OTP | ✅ | ✅ | `localizeAuthMessage` |
| 4.2 | Đăng nhập / refresh / logout | ✅ | ✅ | Email + Google |
| 4.3 | Onboarding 5 bước | ✅ | ✅ | Gate `Profile/me/completion` |
| 4.4 | Profile, avatar, đổi MK | ✅ | ✅ | `ApiMessageTranslator` cho lỗi API |
| 4.5 | Dị ứng | ✅ | ✅ | Onboarding + Khám phá |
| 4.6 | Khám phá món/công thức | ✅ | ✅ | Allergy mode, favorite, ghi log |
| 4.7 | Recommendation | 🟡 | ✅ | Chỉ gợi ý an toàn trong Khám phá |
| 4.8 | AI assistant | ⏳ | 🟡 | Tab AI placeholder |
| 4.9 | Nutrition tracking | ✅ | ✅ | Home + Lịch sử, CRUD, dashboard |
| 4.10 | Weight tracking | ✅ | ✅ | Trong tab Lịch sử |
| 4.11 | Subscription / SePay | ✅ | ✅ | Xem doc SePay |

### 5.1 Đã dùng được trên UI và đã gọi API

- `4.1` – `4.6`, `4.9`, `4.10`, `4.11` (theo bảng trên).

### 5.2 API đã có nhưng UI mới cover một phần

- `4.7` Recommendation nâng cao: smart-schedule, history, feedback — chưa có màn riêng.
- `4.8` AI assistant: API/backend có nền; tab AI chưa nối đầy đủ.
- Notification: API có; chưa màn cài đặt/inbox hoàn chỉnh.

### 5.3 Chưa triển khai / roadmap

- Meal plan tuần/ngày (workflow 2.5 trong doc hệ thống).
- Màn **Hôm nay ăn gì?** (quick-start 1-tap).
- Analytics funnel (`ActivityLog` UI).
- E2E test Flutter; unit test backend .NET.

---

## 6) Kế hoạch bước tiếp theo (P1/P2/P3)

### P1 - Hoàn thiện luồng cốt lõi đang dở (ưu tiên cao nhất)

- ~~Nối dữ liệu thực cho Home và History (NutritionTracking API).~~ **Đã xong (4.9/4.10).**
- Viết test tối thiểu cho luồng auth + onboarding + profile:
  - Sửa `widget_test.dart` mặc định thành test thật theo app hiện tại.
- Unit test nutrition models/warnings (đã có một phần).

**Kết quả mong đợi P1**
- User đi từ đăng ký → onboarding → màn hình chính với dữ liệu thật. **Đạt.**
- Dashboard lịch sử và chỉ số không còn mock. **Đạt.**
- Còn: widget/integration test auth/onboarding; Play Store disclaimer/consent cơ bản.

### P2 - Mở khóa giá trị sử dụng hàng ngày

- Recommendation nâng cao: smart-schedule, feedback, giải thích đề xuất.
- ~~Meal log + weight log + dashboard real-time.~~ **Đã xong.**
- Meal plan + notification nhắc bữa (2.5 / 2.9).
- Quick-add meal template; màn **Hôm nay ăn gì?**
- Goal drift alert rolling 7 ngày (mở rộng cảnh báo macro ngày).

**Kết quả mong đợi P2**
- User dùng app hằng ngày: gợi ý → ghi nhận → theo dõi → nhắc nhở. **Phần ghi nhận + theo dõi đã đạt.**

### P3 - Nâng cao trải nghiệm và cá nhân hóa

- UI AI assistant + flow hội thoại.
- Notification settings và inbox.
- E2E test; analytics sự kiện (`meal_logged`, `onboarding_completed`, …).

**Kết quả mong đợi P3**
- App đạt mức đầy đủ tính năng theo SRS cho user app.

---

## 7) Checklist triển khai kỹ thuật đề xuất

- **i18n:** Backend response English; Flutter `ApiMessageTranslator` + `localizeAuthMessage` trước SnackBar/dialog.
- **API base:** Production `https://menugreensystem.onrender.com/api` (`ApiEndpoints`); dev override `--dart-define=API_BASE_URL=...`.
- Tách ViewModel/Controller dần để UI không gọi API trực tiếp (ưu tiên feature mới).
- Chuẩn hóa loading/error/empty trên mọi màn có gọi API.
- Tests hiện có: `nutrition_models_test`, `nutrition_warning_utils_test`, `api_message_translator_test`.
- Analytics sự kiện đề xuất: `register_success`, `otp_verify_success`, `onboarding_completed`, `meal_logged`, `subscription_subscribed`.

---

## 8) Tiêu chí hoàn thành (Definition of Done)

| Workflow | Trạng thái DoD |
|----------|----------------|
| 4.1–4.6, 4.9–4.11 | ✅ UI + API thật, xử lý lỗi cơ bản, test unit một phần (nutrition/i18n) |
| 4.7 | 🟡 Gợi ý an toàn OK; thiếu history/feedback UI |
| 4.8 | ⏳ Tab placeholder |
| Toàn app | `flutter analyze` không lỗi chặn build; hot restart sau deploy backend |

---

## 9) Điểm kiểm thử để xác nhận workflow

**Auth & onboarding**
- Đăng ký, OTP đúng/sai/hết hạn; đăng nhập email/Google; refresh token.
- Onboarding 5 bước; gate khi chưa complete; message lỗi hiển thị tiếng Việt.

**Khám phá & gợi ý**
- Lọc dị ứng hide/warn; gợi ý an toàn; yêu thích; ghi log từ chi tiết món.

**Nutrition tracking (4.9 / 4.10)**
- Trang chủ: calo/macro hôm nay, Thêm bữa ăn, chạm xem chi tiết món.
- Lịch sử: Ngày/Tuần/Tháng, heatmap, biểu đồ calo & cân; sửa/xóa meal & weight.
- Cảnh báo macro sau deploy backend mới (`WarningMessages` EN → UI VI).
- Recipe log: 100 = 1 khẩu phần; food log: gram.

**Khác**
- Profile, đổi mật khẩu, avatar.
- Subscription / SePay (theo `README_SEPAY_PAYMENT_WORKFLOW.md`).

---

## 10) Kết luận

MenuGreen đã có **chuỗi cốt lõi end-to-end** cho người dùng Việt Nam: đăng ký/đăng nhập → onboarding → khám phá an toàn dị ứng → ghi nhật ký & dashboard dinh dưỡng/cân nặng → gói SePay. Backend deploy trên Render; Flutter mặc định trỏ production API.

**Ưu tiên tiếp theo (Play Store):** disclaimer/compliance, test auth/onboarding, recommendation/AI/notification nâng cao, meal plan. Chi tiết roadmap hệ thống: [`README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md`](README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md).
