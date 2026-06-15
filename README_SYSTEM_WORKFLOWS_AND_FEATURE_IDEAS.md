# README SYSTEM WORKFLOWS AND FEATURE IDEAS - MENUGREEN

Tài liệu này tổng hợp các workflow hệ thống **có thể triển khai/đã có nền tảng dữ liệu** dựa trên các entity hiện tại trong backend (`ApplicationDbContext`), đồng thời đề xuất các tính năng mới cho app dinh dưỡng.

**Cập nhật:** 2026-06-04 · Chi tiết luồng người dùng: [`README_USER_WORKFLOW.md`](README_USER_WORKFLOW.md) · Thanh toán SePay: [`README_SEPAY_PAYMENT_WORKFLOW.md`](README_SEPAY_PAYMENT_WORKFLOW.md)

**Backend production:** `https://menugreensystem.onrender.com/api` (Flutter: `ApiEndpoints.productionBaseUrl`).

**Ánh xạ doc người dùng ↔ hệ thống:**

| User (`README_USER_WORKFLOW`) | System (mục 2.x) |
|-------------------------------|------------------|
| 4.1–4.2 Auth | 2.1 Account lifecycle |
| 4.3 Onboarding | 2.2 Onboarding sức khỏe |
| 4.6 Khám phá | 2.3 Khám phá an toàn dị ứng |
| 4.9–4.10 Tracking | 2.4 Nhật ký dinh dưỡng |
| 4.7 Gợi ý | 2.6 Recommendation |
| 4.8 AI | 2.7 AI Assistant |
| 4.11 Gói | 2.8 Subscription & Payment |

---

## 0) Trạng thái triển khai tổng hợp

| Workflow | Mức độ | Ghi chú |
|----------|--------|---------|
| 2.1 Account lifecycle | ✅ Cốt lõi | Auth, OTP, refresh token, Google sign-in |
| 2.2 Onboarding sức khỏe | ✅ End-to-end | 5 bước Flutter + `Onboarding/complete` |
| 2.3 Khám phá an toàn dị ứng | ✅ Hoàn tất | Discover, allergy mode, ghi log từ món/công thức |
| 2.4 Nhật ký dinh dưỡng | ✅ **100% cốt lõi** | Home + Lịch sử, CRUD, dashboard, cảnh báo macro |
| 2.5 Meal plan | ⏳ Chưa UI | Entity/API một phần |
| 2.6 Recommendation | 🟡 Một phần | Gợi ý an toàn trong Khám phá; chưa smart-schedule/feedback UI |
| 2.7 AI Assistant | ⏳ Placeholder | Tab AI chưa nối API |
| 2.8 Subscription & Payment | ✅ Cốt lõi | SePay + gói; xem doc SePay |
| 2.9 Notification | 🟡 API | Chưa màn cài đặt/inbox đầy đủ |
| 2.10 Analytics | ⏳ | `ActivityLog` có entity, chưa funnel UI |
| 2.11–2.15 | 📋 Roadmap | Vietnam-first, quick-start, gym, barcode, compliance |

**Quy ước API/UI (bắt buộc khi phát triển mới):**

- **Backend:** message/validation/exception trả client **chỉ tiếng Anh** (Cursor rule: `.cursor/rules/backend-english-frontend-vietnamese-i18n.mdc`).
- **Flutter:** UI user-facing **tiếng Việt**; dịch response API qua `ApiMessageTranslator` / `localizeAuthMessage` trước khi hiển thị.

---

## 1) Nguồn phân tích

Workflow dưới đây được suy luận từ các nhóm entity hiện có:

- **Auth & Account:** `User`, `Role`, `Session`, `EmailVerification`, `PasswordResetToken`
- **Profile & Health:** `Profile`, `HealthProfile`, `WeightLog`, `NutritionSnapshot`
- **Allergy & Food Catalog:** `Allergy`, `UserAllergy`, `Food`, `Ingredient`, `FoodAllergy`, `Recipe`, `RecipeIngredient`, `FavoriteFood`
- **Tracking & Planning:** `MealLog`, `MealPlanHeader`, `MealPlanItem`
- **AI & Recommendation:** `AiConversation`, `AiMessage`, `UserAiProfile`, `RecommendationHistory`, `RecommendationFeedback`, `BudgetRequest`
- **Notification:** `Notification`, `NotificationSetting`
- **Subscription & Payment:** `SubscriptionPlan`, `UserSubscription`, `SubscriptionTransaction`, `Subscription`, `Payment`, `SepayTransaction`
- **Audit/Analytics:** `ActivityLog`

---

## 2) Workflow hệ thống có thể có (theo domain)

## 2.1 Account Lifecycle (Guest -> Active User) (Đã làm)

**Mục tiêu:** Biến guest thành user hoạt động, bảo vệ phiên đăng nhập.

**Flow đề xuất:**

1. Guest đăng ký tài khoản (`User`).
2. Gửi OTP/email verify (`EmailVerification`).
3. Xác thực thành công -> kích hoạt user.
4. Đăng nhập tạo session (`Session`).
5. Quên mật khẩu -> tạo token reset (`PasswordResetToken`).
6. Đăng xuất/thu hồi phiên.

**Giá trị:** an toàn tài khoản, quản trị phiên đăng nhập, hỗ trợ khôi phục truy cập.

**Trạng thái triển khai (2026):** Flutter auth (email/OTP/Google), `AuthRepository` + `localizeAuthMessage`; API `AuthController` message tiếng Anh.

---

## 2.2 Onboarding sức khỏe và baseline cá nhân (Đã làm)

**Mục tiêu:** Thiết lập dữ liệu nền cho cá nhân hóa.

**Flow đề xuất:**

1. User cập nhật profile cơ bản (`Profile`).
2. Nhập thông số sức khỏe và mục tiêu (`HealthProfile`).
3. Chọn dị ứng (`UserAllergy` + `Allergy`).
4. Lưu hồ sơ AI cá nhân (`UserAiProfile`) để tối ưu prompt/recommendation.
5. Tạo snapshot đầu kỳ (`NutritionSnapshot`) cho dashboard.

**Giá trị:** nền dữ liệu chuẩn để recommendation/tracking chính xác.

**Trạng thái triển khai (2026):** Đã có end-to-end — Flutter `OnboardingScreen` (5 bước), API `Profile`/`HealthProfile`/`Allergy`+`UserAllergy`/`UserAiProfile`, `POST Onboarding/complete` tạo `NutritionSnapshot`; tracking đồng bộ snapshot khi ghi meal và khi `GET NutritionTracking/daily`.

---

## 2.3 Khám phá món ăn an toàn theo dị ứng (Đã làm)

**Mục tiêu:** Cho user tìm món phù hợp mục tiêu và hạn chế sức khỏe.

**Flow đề xuất:**

1. Browse/search danh mục món (`Food`, `Recipe`, `Ingredient`).
2. Đối chiếu dị ứng user (`Allergy` + alias VN) với nhãn món (`food_allergen_tags` / legacy `FoodAllergy`).
3. Ẩn/cảnh báo món rủi ro dị ứng (`allergyMode=warn|hide` trên `GET /api/Food`).
4. Xem recipe và thành phần (`RecipeIngredient`).
5. Lưu món ưa thích (`FavoriteFood`).

**Triển khai (đã hoàn tất):**

- Flutter `DiscoverView`: món/công thức/nguyên liệu, lọc dinh dưỡng (calories/đạm/giá/category), `allergyMode` + chỉ món an toàn, yêu thích, chi tiết món/công thức/nguyên liệu, ghi nhật ký từ món và công thức.
- `SafeRecommendationsScreen`: gọi `GET /api/Recommendation/*` với `excludeUserAllergies=true` (calories, lunch, eco, daily-menu).
- API: `GET /api/Food?allergyMode`, `GET /api/Recipe/search?allergyMode`, `GET /api/Ingredient/search?allergyMode`, Recommendation `ExcludeUserAllergies`.
- Admin `PUT /api/admin/foods/{id}/allergies`. Migration: `backend/add_food_allergen_tags.sql`.

**Giá trị:** tăng an toàn khi ăn uống và cải thiện trải nghiệm tìm món.

---

## 2.4 Nhật ký dinh dưỡng hằng ngày (Đã làm)

**Mục tiêu:** Theo dõi thực tế ăn uống so với mục tiêu.

**Flow đề xuất:**

1. User ghi bữa ăn (`MealLog`).
2. Hệ thống tổng hợp và cập nhật snapshot (`NutritionSnapshot`).
3. User bổ sung log cân nặng (`WeightLog`).
4. Dashboard hiển thị mức đạt mục tiêu theo ngày/tuần/tháng.

**Triển khai (đã hoàn tất cốt lõi — 2026):**

**Backend**

- `NutritionTrackingController`: `POST/PUT/DELETE meal-logs`, `GET daily?date=`, `GET dashboard?range=day|week|month` (+ `startDate`/`endDate`), `POST/PUT/DELETE weight-logs`.
- `NutritionTrackingService` + `NutritionSnapshotService`: sync snapshot sau mỗi thay đổi meal log; dashboard chỉ sync các ngày có log (tối ưu range dài).
- Din dưỡng từ recipe: `quantityG / 100` = tỷ lệ khẩu phần; food: `quantityG` = gram.
- `NutritionWarningsBuilder`: `WarningMessages` tiếng Anh (calo ±10%, macro ±15%); `HasWarning` đồng bộ API.
- `RecipeService` / catalog: load `RecipeIngredient` kèm `.Include(Ingredient)` — tên nguyên liệu đầy đủ.

**Flutter**

- **Trang chủ (`HomeView`):** tiến độ calo/macro hôm nay từ `GET daily`; nhật ký hôm nay; **Thêm bữa ăn** (`showMealLogSheet`); empty state + Khám phá; chạm món → chi tiết food/recipe.
- **Lịch sử (`HistoryView`):** chọn ngày; toggle Ngày/Tuần/Tháng; `DailySummaryCard`, biểu đồ calo (`fl_chart`), heatmap lịch theo % mục tiêu; CRUD meal log (sheet sửa); CRUD weight + biểu đồ cân; xem chi tiết món từ lịch sử.
- **Khám phá / chi tiết món:** ghi log nhanh từ `FoodDetailScreen` / `RecipeDetailScreen`.
- **Đồng bộ:** `MainScreen` refresh Home khi Lịch sử cập nhật tracking.
- **Cảnh báo:** `NutritionWarningMessages` + `ApiMessageTranslator` — hiển thị tiếng Việt từ message API tiếng Anh.
- **Tests:** `nutrition_models_test`, `nutrition_warning_utils_test`, `api_message_translator_test`.

**Giá trị:** kiểm soát tiến độ dinh dưỡng và kết quả cơ thể theo thời gian.

**Còn lại (P2/P3, ngoài cốt lõi 2.4):** meal plan (2.5), rolling 7-day drift alert, quick-add template, barcode, E2E test.

---

## 2.5 Meal Plan và routine ăn uống (Đã làm)

**Mục tiêu:** Chuyển từ tracking bị động sang kế hoạch chủ động. Đây là lớp “lập lịch” nằm giữa recommendation và meal log: hệ thống không chỉ gợi ý món, mà còn giúp user chốt trước món sẽ ăn theo ngày/tuần, đặt giờ nhắc, rồi đối chiếu kế hoạch với thực tế sau khi ăn.

**Cách hiểu đúng của workflow này:**
- `MealPlan` là “kế hoạch tổng” theo tuần hoặc theo một khung ngày.
- `MealPlanItem` là từng dòng món/bữa cụ thể trong kế hoạch đó.
- `MealLog` vẫn là nguồn sự thật cuối cùng sau khi user thực sự ăn.
- Khi user ăn xong, app có thể convert nhanh từ plan item sang meal log để giảm thao tác nhập tay.
- Notification chỉ là lớp hỗ trợ hành vi, không phải dữ liệu lõi.

**Flow đề xuất:**

1. User tạo kế hoạch theo ngày/tuần (`MealPlanHeader`).
2. User thêm từng bữa (`MealPlanItem`) bằng search món, template, hoặc gợi ý từ recommendation.
3. Hệ thống gắn target calories/macro cho cả plan và từng bữa.
4. Đến giờ ăn, notification nhắc user theo `NotificationSetting`.
5. Sau khi ăn, user bấm “Đã ăn” để tạo `MealLog` từ item của plan.
6. Dashboard so sánh `planned vs actual` theo ngày/tuần và hiển thị mức lệch mục tiêu.
7. Nếu user đổi món, app cập nhật item hoặc đánh dấu item bị bỏ qua để giữ lịch sử rõ ràng.

**Giá trị:**
- Giảm quyết định tức thời mỗi ngày.
- Tăng khả năng bám mục tiêu calories/macro.
- Tạo nền cho reminder, quick-add, streak, và meal-prep workflow sau này.

**API cần có để làm đúng bài:**

### A. Meal plan header
- `POST /MealPlan` — tạo plan mới theo ngày/tuần.
- `GET /MealPlan?from=&to=&type=` — lấy danh sách plan theo khoảng thời gian.
- `GET /MealPlan/{id}` — xem chi tiết plan.
- `PUT /MealPlan/{id}` — cập nhật tên, mục tiêu, trạng thái, ngày hiệu lực.
- `DELETE /MealPlan/{id}` — xoá plan.

### B. Meal plan item
- `POST /MealPlan/{planId}/items` — thêm món/bữa vào plan.
- `PUT /MealPlan/{planId}/items/{itemId}` — sửa giờ ăn, khẩu phần, món, ghi chú.
- `DELETE /MealPlan/{planId}/items/{itemId}` — xoá item khỏi plan.
- `PATCH /MealPlan/{planId}/items/{itemId}/status` — đánh dấu `planned / done / skipped / changed`.

### C. Quick actions từ plan sang log
- `POST /MealPlan/{planId}/items/{itemId}/convert-to-log` — tạo `MealLog` từ item.
- `POST /MealPlan/{planId}/commit` — chốt plan của ngày hôm đó sang dashboard.
- `POST /MealPlan/{planId}/duplicate` — nhân bản plan tuần trước cho tuần mới.

### D. Routine / reminder
- `POST /Notification/meal-plan-remind` — tạo reminder theo plan item.
- `GET /Notification/settings` — đọc cấu hình nhắc.
- `PUT /Notification/settings` — bật/tắt và chỉnh giờ nhắc.

### E. Báo cáo planned vs actual
- `GET /MealPlan/dashboard?date=` — tổng hợp plan của ngày.
- `GET /MealPlan/compare?from=&to=` — so sánh kế hoạch và thực tế theo khoảng thời gian.
- `GET /MealPlan/streaks` — đo mức độ bám plan theo tuần.

**Ưu tiên triển khai kỹ thuật:**
1. Làm CRUD `MealPlanHeader` + `MealPlanItem` trước.
2. Nối action `convert-to-log` sang `MealLog`.
3. Nối reminder với `NotificationSetting` + `Notification`.
4. Làm dashboard compare/streak sau cùng.

**Trạng thái mong muốn sau khi làm xong:**
- User có thể lập plan trong 1-2 phút.
- User bấm một chạm để biến plan thành log.
- Team sản phẩm đo được tỉ lệ “planned meal → actual meal”.

---

## 2.6 Recommendation engine (Rule + AI) (Chưa có AI)

**Mục tiêu:** Đề xuất món/thực đơn cá nhân hóa. Đây là lớp “đề xuất chủ động” đứng sau onboarding và khám phá: thay vì user tự lọc từng món, hệ thống sẽ gom ngữ cảnh từ hồ sơ sức khỏe, dị ứng, lịch sử ăn uống và ngân sách để sinh ra danh sách gợi ý phù hợp hơn.

### Hiểu đúng workflow 2.6

- `RecommendationHistory` là nơi lưu từng lần hệ thống sinh gợi ý cho user.
- `RecommendationFeedback` là dữ liệu user chấm chất lượng đề xuất.
- `BudgetRequest`/ngân sách giúp recommendation không chỉ đúng dinh dưỡng mà còn khả thi khi mua và nấu.
- Rule-based là nền an toàn tối thiểu; AI là lớp nâng cao để cá nhân hóa theo ngữ cảnh.
- Recommendation phải trả về được lý do gợi ý để user tin và hiểu vì sao món đó xuất hiện.

### Flow đề xuất

1. Thu ngữ cảnh từ `HealthProfile`, `UserAllergy`, lịch sử `MealLog`, `BudgetRequest`.
2. Sinh đề xuất và lưu lịch sử (`RecommendationHistory`).
3. User đánh giá chất lượng (`RecommendationFeedback`).
4. Tối ưu dần model/rule theo feedback.

### Giá trị

- Đề xuất càng ngày càng phù hợp.
- Đo được chất lượng recommendation.
- Tạo nền cho AI assistant, smart-schedule và quick-start sau này.

### API cần có để làm đúng bài

#### A. Sinh recommendation (Chưa có)
- `POST /Recommendation/generate` — sinh recommendation theo context user.
- `POST /Recommendation/generate/safe` — sinh gợi ý an toàn, loại trừ dị ứng.
- `POST /Recommendation/generate/daily-menu` — sinh thực đơn trong ngày.
- `POST /Recommendation/generate/weekly-plan` — sinh plan theo tuần.
- `POST /Recommendation/generate/budget-aware` — sinh đề xuất theo ngân sách.
- `POST /Recommendation/generate/smart-schedule` — sinh đề xuất có giờ ăn gợi ý.

#### B. Lưu lịch sử và truy vấn lại (Đã làm)
- `GET /Recommendation/history` — danh sách lịch sử recommendation của user.
- `GET /Recommendation/history/{id}` — xem chi tiết một lần recommendation.
- `DELETE /Recommendation/history/{id}` — xoá lịch sử không cần thiết.

#### C. Feedback loop (Đã làm)
- `POST /Recommendation/history/{id}/feedback` — user chấm chất lượng đề xuất.
- `PUT /Recommendation/feedback/{id}` — cập nhật feedback nếu user đổi ý.
- `GET /Recommendation/feedback/summary` — tổng hợp tỷ lệ thích/không thích.

#### D. Giải thích recommendation (Đã làm)
- `GET /Recommendation/history/{id}/explain` — giải thích vì sao món/thực đơn được đề xuất.
- `GET /Recommendation/{id}/why-this-item` — giải thích chi tiết từng item.

#### E. Tối ưu cá nhân hóa (Đã làm)
- `POST /Recommendation/retrain` — tái tính rule/model từ feedback (job nội bộ/admin).
- `GET /Recommendation/scores` — điểm phù hợp theo từng tiêu chí: calories, macro, dị ứng, ngân sách.

### Ưu tiên triển khai kỹ thuật

1. Làm API generate safe/daily-menu trước.
2. Lưu history và feedback.
3. Thêm explain/why-this-item.
4. Cuối cùng mới tối ưu retrain/scoring nâng cao.

**Trạng thái triển khai (2026):** `SafeRecommendationsScreen` + API `Recommendation/*` (calories, lunch, eco, daily-menu, `excludeUserAllergies`). Chưa có UI lịch sử đề xuất, feedback, smart-schedule.

---

## 2.7 AI Nutrition Assistant (Chưa có)

**Mục tiêu:** Tương tác hội thoại và tư vấn tình huống. Đây là lớp chat “coach dinh dưỡng” giúp user hỏi theo ngữ cảnh thực tế như hôm nay ăn gì, còn thiếu chất gì, nên thay món nào, hoặc có nên giảm/tăng khẩu phần không. Khác với recommendation thuần danh sách, AI assistant phải trả lời theo hội thoại nhiều lượt và giữ mạch ngữ cảnh.

### Hiểu đúng workflow 2.7

- `AiConversation` là một phiên chat.
- `AiMessage` là từng lượt hỏi/đáp trong phiên.
- `UserAiProfile` cung cấp ngữ cảnh cá nhân như mục tiêu, sở thích, hạn chế, phong cách ăn uống.
- AI assistant có thể gọi recommendation, meal plan, nutrition tracking như các công cụ phụ trợ.
- Output không chỉ là câu trả lời mà còn là hành động gợi ý tiếp theo.

### Flow đề xuất

1. Tạo cuộc hội thoại (`AiConversation`).
2. Lưu message theo lượt hỏi đáp (`AiMessage`).
3. Tận dụng hồ sơ AI (`UserAiProfile`) để cá nhân hóa ngữ cảnh.
4. Đề xuất hành động tiếp theo: meal plan, thay món, tối ưu budget.

### Giá trị

- Tăng mức cá nhân hóa.
- Tạo trải nghiệm giống “coach dinh dưỡng”.
- Cho phép user hỏi tự nhiên thay vì phải tự lọc menu.

### API cần có để làm đúng bài

#### A. Conversation lifecycle
- `POST /AiAssistant/conversations` — tạo phiên chat mới.
- `GET /AiAssistant/conversations` — danh sách hội thoại của user.
- `GET /AiAssistant/conversations/{id}` — xem chi tiết hội thoại.
- `DELETE /AiAssistant/conversations/{id}` — xoá hội thoại.
- `PATCH /AiAssistant/conversations/{id}/title` — đổi tiêu đề hội thoại.

#### B. Message workflow
- `POST /AiAssistant/conversations/{id}/messages` — gửi message user và nhận response AI.
- `GET /AiAssistant/conversations/{id}/messages` — lấy toàn bộ message trong hội thoại.
- `POST /AiAssistant/conversations/{id}/messages/{messageId}/regenerate` — tạo lại câu trả lời AI.
- `PATCH /AiAssistant/conversations/{id}/messages/{messageId}/feedback` — user chấm câu trả lời.

#### C. Context & profile
- `GET /AiAssistant/context` — lấy context AI hiện tại từ profile/tracking/recommendation.
- `PUT /AiAssistant/context` — cập nhật ngữ cảnh ưu tiên cho AI assistant.
- `GET /AiAssistant/profile` — đọc `UserAiProfile` để AI dùng cá nhân hóa.
- `PUT /AiAssistant/profile` — cập nhật hồ sơ AI của user.

#### D. Action suggestions
- `GET /AiAssistant/suggestions` — đề xuất hành động tiếp theo từ hội thoại.
- `POST /AiAssistant/actions/meal-plan` — tạo meal plan từ gợi ý AI.
- `POST /AiAssistant/actions/replace-food` — đề xuất món thay thế.
- `POST /AiAssistant/actions/budget-optimize` — tối ưu thực đơn theo ngân sách.

#### E. History/analytics
- `GET /AiAssistant/insights` — thống kê chủ đề hỏi thường gặp.
- `GET /AiAssistant/conversations/{id}/summary` — tóm tắt hội thoại.
- `GET /AiAssistant/usage` — số lần dùng assistant theo ngày/tuần/tháng.

### Ưu tiên triển khai kỹ thuật

1. Làm conversation/message CRUD trước.
2. Nối AI provider thật vào send/regenerate.
3. Thêm context/profile và suggestion actions.
4. Cuối cùng mới làm insights/usage/summary.

**Giá trị:** tăng mức cá nhân hóa, tạo trải nghiệm giống “coach dinh dưỡng”.

---

## 2.8 Subscription & Payment lifecycle (Đã làm)

**Mục tiêu:** Quản lý quyền truy cập tính năng nâng cao và dòng tiền.

**Flow đề xuất:**

1. Hiển thị gói (`SubscriptionPlan`).
2. User đăng ký/gia hạn/hủy (`UserSubscription`, `Subscription`).
3. Ghi nhận giao dịch (`SubscriptionTransaction`, `Payment`, `SepayTransaction`).
4. Đồng bộ quyền feature theo trạng thái thanh toán.

**Giá trị:** kiểm soát entitlement rõ ràng, đảm bảo dữ liệu thanh toán đối soát được.

**Trạng thái triển khai (2026):** UI gói + SePay QR/webhook; chi tiết luồng trong [`README_SEPAY_PAYMENT_WORKFLOW.md`](README_SEPAY_PAYMENT_WORKFLOW.md).

---

## 2.9 Notification & Re-engagement (Đã làm)

**Mục tiêu:** Nhắc user quay lại app và duy trì thói quen.

**Giải thích workflow:**

- `NotificationSetting` là cấu hình cá nhân hóa cho việc nhận nhắc: bật/tắt, chọn kênh, khung giờ cho phép, tần suất và loại nhắc.
- `Notification` là bản ghi thông báo được hệ thống tạo ra để gửi cho user theo sự kiện hoặc lịch hẹn.
- `ActivityLog` (hoặc log tracking riêng) dùng để ghi nhận open/click/action-complete nhằm đo hiệu quả re-engagement.
- Mục tiêu không chỉ là “gửi nhắc”, mà còn là đo được user có quay lại app và hoàn thành hành động sau nhắc hay không.

**Flow đề xuất:**

1. User cấu hình kênh/khung giờ và loại nhắc (`NotificationSetting`).
2. Hệ thống phát thông báo (`Notification`) theo sự kiện:
   - Đến giờ ăn
   - Chưa log bữa trong ngày
   - Sắp hết hạn subscription
   - Nhắc cân mỗi tuần
3. User mở/click thông báo, hệ thống ghi nhận tracking (`ActivityLog` hoặc tracking endpoint riêng).
4. Dashboard/analytics tổng hợp open rate, click rate và tỷ lệ quay lại app.

**Giá trị:** tăng retention và giảm drop-off.

**API cần có để làm đúng bài:**

### A. Notification setting
- `GET /Notification/settings` — lấy cấu hình nhắc hiện tại của user.
- `PUT /Notification/settings` — cập nhật cấu hình nhắc: bật/tắt, kênh, giờ nhắc, timezone, loại nhắc.
- `POST /Notification/settings/reset` — reset cấu hình về mặc định.
- `GET /Notification/channels` — danh sách kênh hỗ trợ.

### B. Notification inbox / lịch sử thông báo
- `GET /Notification` — danh sách thông báo của user.
- `GET /Notification/{id}` — xem chi tiết một notification.
- `PATCH /Notification/{id}/read` — đánh dấu đã đọc.
- `PATCH /Notification/{id}/open` — ghi nhận user đã mở thông báo.
- `PATCH /Notification/{id}/dismiss` — ghi nhận user bỏ qua thông báo.
- `DELETE /Notification/{id}` — xoá một notification nếu hệ thống cho phép.

### C. Gửi thông báo theo sự kiện
- `POST /Notification/send` — gửi một thông báo cụ thể tới user.
- `POST /Notification/send/bulk` — gửi hàng loạt theo danh sách user hoặc segment.
- `POST /Notification/send/event` — gửi theo sự kiện: đến giờ ăn, chưa log bữa, sắp hết hạn, nhắc cân.
- `POST /Notification/send/schedule` — lên lịch gửi vào thời điểm cụ thể.
- `POST /Notification/send/retry` — gửi lại nếu lần trước thất bại.

### D. Re-engagement campaign
- `POST /Notification/campaigns` — tạo chiến dịch re-engagement.
- `GET /Notification/campaigns` — danh sách chiến dịch.
- `GET /Notification/campaigns/{id}` — xem chi tiết chiến dịch.
- `PUT /Notification/campaigns/{id}` — cập nhật nội dung, lịch gửi, target segment.
- `POST /Notification/campaigns/{id}/run` — chạy chiến dịch.
- `POST /Notification/campaigns/{id}/pause` — tạm dừng chiến dịch.

### E. Tracking open/click và hiệu quả
- `POST /Notification/{id}/track/open` — ghi nhận notification được mở.
- `POST /Notification/{id}/track/click` — ghi nhận user click vào CTA.
- `POST /Notification/{id}/track/action-complete` — ghi nhận user đã hoàn thành hành động sau khi click.
- `GET /Notification/analytics` — tổng hợp số sent, opened, clicked, CTR, open rate, action completion rate.
- `GET /Notification/analytics/re-engagement` — báo cáo riêng cho các nhóm nhắc quay lại app.

**Ưu tiên triển khai kỹ thuật:**
1. Làm `NotificationSetting` CRUD trước.
2. Làm `Notification` inbox + trạng thái đọc/mở/click.
3. Nối job gửi notification theo event.
4. Thêm tracking open/click.
5. Cuối cùng mới làm analytics và campaign nâng cao.

**Trạng thái mong muốn sau khi làm xong:**
- User tự cấu hình được nhắc giờ ăn, nhắc cân, nhắc log bữa.
- Hệ thống tự gửi notification theo event.
- App đo được user có mở/click/quay lại hay không.
- Team sản phẩm có số liệu rõ ràng để tối ưu retention.

---

## 2.10 Audit & Product analytics (Đã làm)

**Mục tiêu:** Đo usage thực tế và hỗ trợ vận hành.

**Flow đề xuất:**

1. Ghi sự kiện quan trọng (`ActivityLog`): register, onboarding_completed, meal_logged, subscribe...
2. Tổng hợp funnel và cohort.
3. Phân tích điểm rơi rời bỏ để tối ưu UX.

**Giá trị:** dữ liệu ra quyết định cho Product/Marketing/CS.

**Giải thích đúng workflow:**
- `ActivityLog` là nguồn dữ liệu lõi để ghi lại mọi hành vi quan trọng của user và hệ thống.
- Funnel dùng để đo user rơi ở bước nào trong một hành trình như onboarding → log bữa đầu tiên → subscription.
- Cohort dùng để so sánh retention giữa các nhóm user theo ngày đăng ký, ngày log bữa đầu tiên, hoặc trạng thái subscription.
- Mục tiêu cuối cùng là tìm điểm drop-off để tối ưu UX, tăng retention và hỗ trợ ra quyết định cho Product/Marketing/CS.

**API cần có để làm đúng bài:**

### A. Activity logging
- `POST /Analytics/activity-log` — ghi nhận một sự kiện quan trọng.
- `POST /Analytics/activity-log/bulk` — ghi nhận nhiều sự kiện cùng lúc.
- `GET /Analytics/activity-log` — lấy danh sách sự kiện theo user hoặc thời gian.
- `GET /Analytics/activity-log/{id}` — xem chi tiết một sự kiện.

### B. Funnel analytics
- `GET /Analytics/funnel` — tổng hợp funnel theo một flow định nghĩa sẵn.
- `POST /Analytics/funnel/preview` — xem trước funnel theo các step truyền vào.
- `GET /Analytics/funnel/meal-onboarding` — funnel mặc định cho onboarding → log bữa đầu tiên.
- `GET /Analytics/funnel/subscription` — funnel mặc định cho đăng ký → mua subscription.

### C. Cohort analytics
- `GET /Analytics/cohort` — lấy dữ liệu cohort tổng quát.
- `GET /Analytics/cohort/retention` — đo retention theo D1 / D7 / D30.
- `GET /Analytics/cohort/by-signup-date` — cohort theo ngày đăng ký.
- `GET /Analytics/cohort/by-first-meal-log` — cohort theo ngày log bữa đầu tiên.
- `GET /Analytics/cohort/by-subscription` — cohort theo trạng thái subscription.

### D. Dashboard / report tổng hợp
- `GET /Analytics/dashboard` — tổng hợp KPI chính.
- `GET /Analytics/summary?from=&to=` — báo cáo tổng hợp theo khoảng thời gian.
- `GET /Analytics/metrics?from=&to=` — trả về KPI chi tiết theo ngày / tuần / tháng.
- `GET /Analytics/top-events?from=&to=` — danh sách event được ghi nhận nhiều nhất.

### E. Drop-off / churn analysis
- `GET /Analytics/drop-off` — phân tích các bước có rớt user nhiều nhất.
- `GET /Analytics/churn-risk` — phân nhóm user có nguy cơ rời bỏ.
- `GET /Analytics/inactive-users` — danh sách user không hoạt động trong khoảng thời gian xác định.
- `GET /Analytics/reactivation-opportunities` — danh sách user có thể nhắc quay lại.

### F. Export dữ liệu
- `GET /Analytics/export/activity-log` — xuất activity log ra file hoặc CSV.
- `GET /Analytics/export/funnel` — xuất dữ liệu funnel.
- `GET /Analytics/export/cohort` — xuất dữ liệu cohort.

**Ưu tiên triển khai kỹ thuật:**
1. Làm `ActivityLog` trước.
2. Làm `dashboard` và `summary`.
3. Làm `funnel`.
4. Làm `cohort retention`.
5. Cuối cùng mới làm `churn-risk`, `reactivation-opportunities`, `export`.

---

## 2.11 Vietnam-first local nutrition workflow (Đã làm)

**Mục tiêu:** Tăng mức phù hợp cho người dùng Việt Nam trong sử dụng hằng ngày.

**Giải thích đúng workflow:**
- Người dùng Việt thường quen với món ăn, khẩu phần và đơn vị đo khác với chuẩn quốc tế, nên workflow này cần “localize” ngay từ onboarding và recommendation.
- Hệ thống không chỉ ưu tiên món Việt mà còn phải hiểu ngữ cảnh ăn uống thực tế như ăn ngoài/nấu tại nhà, ngân sách phổ biến, và cách đo khẩu phần theo chén/bát/muỗng/đĩa.
- Mục tiêu cuối cùng là giảm rào cản nhập liệu, tăng độ chính xác khi log bữa ăn, và làm app có cảm giác “hiểu người dùng Việt”.

**Flow đề xuất:**

1. User chọn vùng/khẩu vị ưu tiên khi onboarding (Bắc/Trung/Nam, ăn ngoài/nấu tại nhà).
2. Hệ thống ưu tiên món Việt quen thuộc trong discovery/recommendation.
3. Gợi ý khẩu phần theo đơn vị quen thuộc (chén, bát, muỗng, đĩa) và quy đổi gram.
4. Ưu tiên món theo ngân sách phổ biến tại Việt Nam.
5. Khi cần, hệ thống cho phép đổi giữa đơn vị Việt Nam và gram/ml để log nhanh và chính xác hơn.

**Giá trị:** giảm rào cản sử dụng, tăng cảm giác “app hiểu người dùng Việt”.

**API đã triển khai theo hướng không trùng chức năng:**

### A. Local preference onboarding
- `GET /Nutrition/local-preferences` — lấy cấu hình local preference hiện tại của user.
- `POST /Nutrition/local-preferences` — lưu cấu hình lần đầu.
- `PUT /Nutrition/local-preferences` — cập nhật lại khẩu vị, vùng ưu tiên hoặc kiểu ăn.

> Đã dùng lại `UserAiProfile` hiện có để tránh tạo thêm storage/flow trùng với onboarding AI profile.

### B. Localized food discovery
- `GET /Nutrition/discovery/local` — gợi ý món Việt theo từ khóa và ngân sách.
- `GET /Nutrition/discovery/local/by-region/{region}` — lọc theo vùng Bắc/Trung/Nam.
- `GET /Nutrition/discovery/local/by-budget?maxPrice=` — gợi ý món theo ngân sách.

> Các endpoint này tái sử dụng `FoodService.SearchAsync` và logic phân loại món hiện có, nên không code thêm một search engine riêng.

### C. Portion / unit conversion
- `GET /Nutrition/portions/local-units` — trả về danh sách đơn vị quen thuộc như chén, bát, muỗng, đĩa.
- `POST /Nutrition/portions/convert` — quy đổi giữa đơn vị Việt Nam và gram/ml.
- `GET /Nutrition/portions/estimate?foodId=` — ước lượng khẩu phần mặc định theo món.

> `custom-estimate` chưa tách riêng vì có thể dùng chung với flow log bữa ăn và convert hiện tại; nếu sau này cần UX riêng thì tách sau.

### D. Vietnamese meal logging
- `POST /Nutrition/meal-log/vn` — log bữa ăn với hỗ trợ đơn vị Việt Nam.
- `POST /Nutrition/meal-log/vn/quick-add` — thêm nhanh món quen thuộc bằng đơn vị địa phương.
- `GET /Nutrition/meal-log/vn/suggestions` — gợi ý món Việt dễ log nhanh.
- `GET /Nutrition/meal-log/vn/history` — xem lịch sử log bữa ăn theo format local.

> Hai API `meal-log/vn` và `meal-log/vn/quick-add` hiện dùng chung logic create meal log để tránh duplicate handler.

### E. Budget-aware recommendations
- `GET /Nutrition/recommendations/budget-aware` — gợi ý món theo mục tiêu dinh dưỡng và ngân sách.
- `GET /Nutrition/recommendations/local-friendly` — gợi ý món dễ ăn, dễ tìm, phù hợp thói quen Việt.
- `POST /Nutrition/recommendations/feedback` — ghi nhận feedback để tối ưu gợi ý local.

> `budget-aware` và `local-friendly` đang dùng chung recommendation engine hiện có (`RecommendByEcoAsync`) để không viết trùng một lớp recommendation mới.

**Phần đã code trong backend:**
- Tạo controller `VietnamNutritionController` để gom các endpoint Vietnam-first.
- Tái sử dụng `UserAiProfileService`, `FoodService`, `NutritionTrackingService`, và `RecommendationService`.
- Không code trùng những phần đã có sẵn như search món ăn, log bữa ăn, hoặc feedback recommendation.

**Ưu tiên triển khai kỹ thuật tiếp theo:**
1. Chuẩn hóa DTO riêng cho `PortionConvertRequest` và `custom-estimate` nếu muốn tách UI/UX.
2. Tinh chỉnh rule gợi ý theo vùng/khẩu vị Việt để discovery chính xác hơn.
3. Nếu cần, tách thêm service riêng cho metric local-specific thay vì nhét vào recommendation hiện có.
---

## 2.12 Beginner quick-start workflow (Hôm nay ăn gì?) (Đã làm)

**Mục tiêu:** Hỗ trợ nhóm người dùng chưa biết ăn gì mỗi ngày.

**Giải thích đúng workflow:**
- Đây là workflow tối ưu cho người dùng bận rộn hoặc chưa có thói quen tự lên thực đơn.
- Thay vì bắt user search nhiều bước, hệ thống chỉ cần trả vài gợi ý đủ tốt để họ chọn ngay.
- Workflow này nên nối liền với recommendation, meal plan và meal log hiện có để tránh code trùng.
- Mục tiêu cuối cùng là giảm thời gian ra quyết định, tăng tỉ lệ quay lại app mỗi ngày, và biến “chọn món” thành một thao tác rất nhanh.

**Flow đề xuất:**

1. User vào màn hình nhanh “Hôm nay ăn gì?”.
2. Hệ thống trả 3-5 gợi ý theo mục tiêu calories/macro và dị ứng.
3. User chọn nhanh hoặc bấm đổi món 1 chạm.
4. Tạo sẵn meal plan/ngày và cho phép log nhanh sau khi ăn.
5. User có thể lưu lại lựa chọn tốt để hệ thống học cho những lần sau.

**Giá trị:** rút ngắn thời gian ra quyết định, tăng tỉ lệ dùng app hằng ngày.

**API đã có chức năng tương đương, nên dùng các API này thay vì tạo API quick-start mới:**

### A. Quick-start suggestion
- `GET /api/Recommendation/calories` — lấy gợi ý theo calories/macro cho màn hình “Hôm nay ăn gì?”.
- `GET /api/Recommendation/eco` — lấy gợi ý theo ngân sách và thời gian.
- `GET /api/Recommendation/lunch` — lấy gợi ý bữa trưa nhanh.
- `GET /api/Recommendation/daily-menu` — tạo sẵn menu/ngày từ target calories.
- `POST /api/Recommendation/preview` — xem trước danh sách gợi ý trước khi áp dụng.

### B. One-tap refresh
- `POST /api/Recommendation/preview` — gọi lại với input mới để đổi bộ gợi ý.
- `POST /api/Recommendation/feedback` — user đánh giá món nào hợp/không hợp để tối ưu lần sau.
- `GET /api/Recommendation/history` — xem lịch sử recommendation đã tạo.

### C. Create meal plan from quick-start
- `POST /api/MealPlan` — tạo meal plan/ngày từ món đã chọn nếu hệ thống đã có flow tạo plan.
- `PUT /api/MealPlan/{id}` — cập nhật plan từ lựa chọn mới.
- `GET /api/MealPlan/{id}` — xem trước plan trước khi lưu hoặc áp dụng.
- `POST /api/UserMealPlan` — gắn meal plan vào user hiện tại nếu flow của app dùng user-plan riêng.

### D. Quick logging
- `POST /api/NutritionTracking/meal-logs` — log nhanh món đã chọn vào meal log.
- `PUT /api/NutritionTracking/meal-logs/{mealLogId}` — cập nhật log nếu user đổi món.
- `GET /api/NutritionTracking/meal-logs` — xem lịch sử meal log của user.

**Ghi chú tránh code trùng với API đã có:**
- `quick-start/today`, `quick-start/refresh`, `quick-start/preview`, `quick-start/refine` không nên tạo endpoint mới; chỉ map sang `RecommendationController` hiện có.
- `quick-start/feedback` dùng lại `POST /api/Recommendation/feedback`, không tạo luồng feedback riêng.
- `quick-start/log` và `quick-start/log-and-plan` dùng lại `POST /api/NutritionTracking/meal-logs`, không tạo API log riêng trùng chức năng.
- `quick-start/create-meal-plan` dùng lại `MealPlanService` / `UserMealPlanService` hiện có, không viết lại engine tạo meal plan từ đầu.
- `quick-start/history` nếu chỉ cần lịch sử gợi ý thì dùng lại `GET /api/Recommendation/history`, không thêm history mới.

**Các API quick-start chỉ là tên workflow mô tả, không phải endpoint mới cần code:**
- `GET /Nutrition/quick-start/today` -> `GET /api/Recommendation/calories`
- `POST /Nutrition/quick-start/preview` -> `POST /api/Recommendation/preview`
- `POST /Nutrition/quick-start/refine` -> `POST /api/Recommendation/preview` hoặc `GET /api/Recommendation/calories` với input mới
- `POST /Nutrition/quick-start/refresh` -> gọi lại `POST /api/Recommendation/preview` với seed khác
- `POST /Nutrition/quick-start/feedback` -> `POST /api/Recommendation/feedback`
- `POST /Nutrition/quick-start/log` -> `POST /api/NutritionTracking/meal-logs`
- `POST /Nutrition/quick-start/log-and-plan` -> phối hợp `POST /api/NutritionTracking/meal-logs` + `POST /api/MealPlan`

**Ưu tiên triển khai kỹ thuật:**
1. Tái sử dụng recommendation hiện có để sinh gợi ý nhanh.
2. Nối với meal plan hiện có để tạo plan từ lựa chọn.
3. Nối với meal log hiện có để log nhanh sau khi chọn món.
4. Cuối cùng mới tối ưu feedback loop để cá nhân hóa sâu hơn.

**Ưu tiên triển khai kỹ thuật:**
1. Tái sử dụng recommendation hiện có để sinh gợi ý nhanh.
2. Nối với meal plan hiện có để tạo plan từ lựa chọn.
3. Nối với meal log hiện có để log nhanh sau khi chọn món.
4. Cuối cùng mới tối ưu feedback loop để cá nhân hóa sâu hơn.

---

## 2.13 Gym/PT goal-based workflow (Đã làm)

**Mục tiêu:** Phục vụ nhóm tập gym/PT theo mục tiêu cụ thể.

**Giải thích đúng workflow:**
- Workflow này dành cho người tập nghiêm túc, cần chế độ ăn theo mục tiêu rõ ràng như cut, bulk, maintain, recomp.
- Không chỉ là gợi ý món ăn, mà còn phải điều chỉnh target calories/macro theo ngày tập/ngày nghỉ.
- Cần có guardrail an toàn để tránh kế hoạch quá cực đoan, đồng thời theo dõi planned vs actual để tái cân chỉnh mục tiêu theo tuần.
- Nếu làm đúng, workflow này sẽ giúp app phù hợp với user gym/PT và tăng retention nhóm này.

**Flow đề xuất:**

1. User chọn goal mode: cut/bulk/maintain/recomp.
2. Thiết lập lịch tập và phân tách ngày tập/ngày nghỉ.
3. Hệ thống điều chỉnh target calories/macro theo loại ngày.
4. Áp dụng guardrail an toàn (ngưỡng calories/macro tối thiểu-tối đa) để tránh kế hoạch cực đoan.
5. Theo dõi planned vs actual theo tuần và phát cảnh báo lệch mục tiêu.
6. Recalibrate mục tiêu theo chu kỳ tuần dựa trên tiến độ thực tế.
7. (Nâng cao) chia sẻ báo cáo cho PT/coach để review.

**Giá trị:** phù hợp nhu cầu người tập nghiêm túc và tăng retention nhóm gym.

**API đã có chức năng tương đương, nên dùng thay vì tạo API mới:**

### A. Goal mode / recommendation
- `GET /api/Recommendation/calories` — gợi ý theo target calories/macro cho user.
- `GET /api/Recommendation/daily-menu` — tạo menu/ngày theo mục tiêu dinh dưỡng.
- `POST /api/Recommendation/preview` — xem trước bộ gợi ý trước khi áp dụng.
- `POST /api/Recommendation/feedback` — user phản hồi để cải thiện gợi ý.
- `GET /api/Recommendation/history` — xem lịch sử recommendation.

### B. Tracking planned vs actual
- `GET /api/NutritionTracking/summary` — tổng hợp dinh dưỡng theo ngày/tuần/tháng.
- `GET /api/NutritionTracking/trends` — phân tích xu hướng dinh dưỡng theo thời gian.
- `GET /api/NutritionTracking/daily` — lấy tóm tắt dinh dưỡng theo ngày.
- `GET /api/NutritionTracking/dashboard` — xem dashboard tổng hợp meal logs và weight logs.
- `GET /api/NutritionTracking/weight-logs/trend` — theo dõi xu hướng cân nặng.

### C. Logging dữ liệu thực tế
- `POST /api/NutritionTracking/meal-logs` — ghi nhận bữa ăn thực tế.
- `PUT /api/NutritionTracking/meal-logs/{mealLogId}` — cập nhật log nếu user đổi món/khẩu phần.
- `GET /api/NutritionTracking/meal-logs` — xem lịch sử meal log để so sánh planned vs actual.
- `POST /api/NutritionTracking/weight-logs` — ghi nhận cân nặng thực tế.
- `GET /api/NutritionTracking/weight-logs` — theo dõi các mốc cân nặng.

**Ghi chú tránh code trùng với API đã có:**
- Phần recommendation cho cut/bulk/maintain/recomp nên **tái sử dụng** `RecommendationController` hiện có, không tạo recommendation engine riêng.
- Phần planned vs actual nên **tái sử dụng** `NutritionTrackingController` để lấy summary, trends, dashboard, meal logs, weight logs.
- `recalibrate` theo tuần có thể tính từ dữ liệu `summary`, `trends`, `weight-logs/trend`, nên chưa cần API riêng nếu chỉ là logic xử lý ở service.
- Chia sẻ báo cáo cho PT/coach là chức năng nâng cao, hiện chưa thấy API riêng tương ứng nên có thể tách sau nếu thực sự cần.

**API đã code trong backend, nhưng dùng lại API hiện có để tránh trùng chức năng:**
- `GET /api/GymGoals/me` — lấy cấu hình goal mode hiện tại của user, được map từ `UserAiProfileService` hiện có.
- `POST /api/GymGoals` — tạo/cập nhật cấu hình goal mode, lịch tập và target ban đầu, nhưng thực tế vẫn lưu qua `UserAiProfileService`.
- `PUT /api/GymGoals` — cập nhật goal mode, lịch tập, ngày tập/ngày nghỉ, vẫn dùng lại `UserAiProfileService`.
- `GET /api/GymGoals/plan` — lấy kế hoạch gợi ý theo goal mode, nhưng thực chất gọi `RecommendationController` hiện có.
- `POST /api/GymGoals/recalibrate` — thu thập dữ liệu để recalibrate, nhưng chưa tạo engine recalibration riêng; dùng `NutritionTrackingController` để lấy summary/trends/weight trend.
- `GET /api/GymGoals/alerts` — cảnh báo lệch mục tiêu, nhưng dữ liệu được suy ra từ `MealPlanController.GetCompareAsync` và tracking hiện có.
- `GET /api/GymGoals/coach-report` — báo cáo nâng cao cho PT/coach, nhưng nội dung lấy từ `MealPlanController`, `UserMealPlanController`, `NutritionTrackingController` hiện có.

**Ghi chú:**
- Các endpoint `GymGoals` ở trên là lớp orchestration mới, không tạo storage/engine riêng trùng lặp.
- Nếu muốn tối giản hơn nữa, có thể không expose `GymGoals` mà chỉ dùng thẳng các API hiện có ở `RecommendationController`, `MealPlanController`, `UserMealPlanController`, `NutritionTrackingController`.

**Ưu tiên triển khai kỹ thuật:**
1. Tái sử dụng recommendation hiện có để sinh gợi ý theo goal mode.
2. Nối với tracking hiện có để đo planned vs actual.
3. Thêm guardrail và recalibration logic ở service layer nếu cần.
4. Chỉ tách API riêng cho gym-goals khi đã chắc chắn không trùng với flow tracking hiện có.

---

## 2.14 Real-world food data capture workflow (Chưa có)

**Mục tiêu:** Ghi log dinh dưỡng nhanh và sát thực tế đời sống.

**Giải thích đúng workflow:**
- Workflow này tập trung vào việc ghi nhận bữa ăn trong đời thực, nơi user không phải lúc nào cũng có dữ liệu món ăn chuẩn xác.
- Hệ thống cần hỗ trợ nhiều cách nhập khác nhau: tìm món, chọn template, quét barcode, hoặc nhập tay fallback.
- Điểm quan trọng nhất là giảm friction khi log nhưng vẫn giữ được độ chính xác calories/macro.
- Các luồng có sẵn như meal log, food search, recommendation, meal plan nên được tái sử dụng tối đa để tránh code trùng.

**Flow đề xuất:**

1. Log bữa bằng 3 cách: tìm món, chọn template.
2. Hỗ trợ chọn khẩu phần nhanh theo đơn vị thường dùng.
3. Hệ thống quy đổi khẩu phần về gram để tính calories/macro nhất quán.
4. Nếu không tìm thấy món, user dùng fallback nhập tay nhanh (macro ước tính + ghi chú).
5. User chỉnh tay nếu sai lệch và lưu thành quick-add lần sau.

**Giá trị:** giảm friction khi ghi log và tăng độ chính xác dữ liệu.

**API đã có chức năng tương đương, nên dùng thay vì tạo API mới:**

### A. Tìm món / chọn món có sẵn
- `GET /api/Food` — tìm kiếm món ăn theo keyword và các bộ lọc dinh dưỡng/giá/thời gian.
- `GET /api/Food/{id}` — lấy chi tiết món ăn để log nhanh.
- `GET /api/Food/{id}/similar` — lấy món tương tự khi user không tìm thấy món chính xác.
- `GET /api/Food/{id}/recipes` — lấy công thức liên quan nếu user muốn log theo recipe.
- `GET /api/Food/favorites` — dùng món yêu thích làm template log nhanh.

### B. Ghi meal log thực tế
- `POST /api/NutritionTracking/meal-logs` — ghi nhận bữa ăn thực tế.
- `PUT /api/NutritionTracking/meal-logs/{mealLogId}` — chỉnh tay lại khẩu phần/macro nếu user thấy sai lệch.
- `GET /api/NutritionTracking/meal-logs` — xem lịch sử log để dùng lại lần sau.
- `GET /api/NutritionTracking/meal-logs/{mealLogId}` — xem chi tiết một meal log đã ghi.
- `GET /api/NutritionTracking/meal-logs/range` — lấy log theo khoảng ngày.

### C. Chọn nhanh theo template / quick-add
- `POST /api/NutritionTracking/meal-logs` — có thể dùng làm quick-add nếu request chứa món/template sẵn.
- `POST /api/user-meal-plans/from-daily-menu` — tạo plan mẫu để user dùng như template log nhanh.
- `POST /api/user-meal-plans` — tạo hoặc cập nhật plan ngày để tái sử dụng như preset cho lần log sau.
- `GET /api/user-meal-plans` — lấy plan theo ngày để chọn nhanh từ template đã lưu.

### D. Hỗ trợ fallback nhập tay
- `POST /api/NutritionTracking/meal-logs` — có thể dùng làm fallback nhập tay bằng macro ước tính và ghi chú.
- `PUT /api/NutritionTracking/meal-logs/{mealLogId}` — chỉnh lại macro/khẩu phần sau khi user sửa tay.
- `GET /api/NutritionTracking/daily` — kiểm tra tổng dinh dưỡng ngày hiện tại để đối chiếu sau khi nhập tay.

**Ghi chú tránh code trùng với API đã có:**
- `search món` và `similar food` nên **dùng lại** `FoodController`, không tạo endpoint search riêng cho workflow này.
- `log bữa`, `quick-add`, `fallback nhập tay` nên **dùng lại** `NutritionTrackingController` / `meal-logs`, không tạo API meal log mới.
- `template` và `preset` nên **dùng lại** `UserMealPlanController` nếu cần lưu meal template, không tạo storage trùng.
- `barcode` nếu sau này cần hỗ trợ riêng thì mới tách API mới; hiện tại chưa thấy endpoint barcode riêng nên có thể triển khai sau.

**API mới chưa có, đã được code để không trùng với API hiện có:**
- `POST /api/Nutrition/food-capture/quick-template` — tạo template log nhanh từ một món hoặc meal log đã có; bên trong dùng lại `FoodController.GetById` hoặc `NutritionTrackingController.GetMealLogById`.
- `POST /api/Nutrition/food-capture/fallback-estimate` — nhập tay macro ước tính kèm ghi chú khi không tìm thấy món; bên trong dùng lại `NutritionTrackingController.CreateMealLogAsync`.
- `POST /api/Nutrition/food-capture/save-as-quick-add` — lưu một meal log chuẩn thành quick-add cho những lần sau; bên trong vẫn dùng `NutritionTrackingController.CreateMealLogAsync`.
- `GET /api/Nutrition/food-capture/template-from-plan` — lấy template từ meal plan hiện có; bên trong dùng lại `UserMealPlanController.GetByDate`.

**Ưu tiên triển khai kỹ thuật:**
1. Tái sử dụng `FoodController` và `NutritionTrackingController` cho search + log trước.
2. Dùng `UserMealPlanController` cho template/preset nếu cần.
3. Chỉ tách barcode/fallback/quick-add riêng khi workflow thật sự cần UX chuyên biệt.

---

## 2.15 Safety, trust, and compliance workflow (Play Store-ready) (Chưa có)

**Mục tiêu:** Đảm bảo app an toàn, đáng tin cậy và phù hợp phát hành CH Play.

**Giải thích đúng workflow:**
- Workflow này không nhằm tạo thêm tính năng dinh dưỡng mới, mà tập trung vào độ tin cậy, pháp lý, quyền riêng tư và khả năng vận hành an toàn khi app ra production.
- Người dùng cần được nhìn thấy disclaimer rõ ràng để hiểu app chỉ hỗ trợ dinh dưỡng, không thay thế tư vấn y khoa.
- Một số nhóm user có rủi ro cao cần được cảnh báo phù hợp, tránh đưa ra lời khuyên quá tự tin hoặc gây hiểu nhầm.
- Consent cho analytics/notification phải được quản lý minh bạch, có thể bật/tắt và ghi nhận trạng thái đồng ý.
- Người dùng cũng phải có luồng export/delete dữ liệu cá nhân để đáp ứng yêu cầu quyền riêng tư và tiêu chuẩn store.
- Cuối cùng, app cần theo dõi sự cố, lỗi production và trạng thái hệ thống để tăng độ ổn định và trust.

**Flow đề xuất:**

1. Hiển thị disclaimer rõ: app hỗ trợ dinh dưỡng, không thay thế chẩn đoán y khoa.
2. Với nhóm rủi ro cao, hiển thị cảnh báo và gợi ý tham vấn chuyên gia.
3. Quản lý consent cho analytics/notification rõ ràng.
4. Cung cấp luồng export/delete dữ liệu người dùng theo yêu cầu.
5. Theo dõi sự cố quan trọng và phản hồi lỗi ổn định cho production.

**Giá trị:** tăng trust, giảm rủi ro vận hành và hỗ trợ tiêu chuẩn phát hành.

**API đã có chức năng tương đương, nên dùng lại thay vì tạo mới:**

### A. Consent / privacy / user data
- `GET /api/Profile/me` — lấy thông tin profile và trạng thái hiện tại của user.
- `PUT /api/Profile/me` — cập nhật thông tin cá nhân và các lựa chọn liên quan.
- `GET /api/UserAiProfile/me` — lấy profile AI/personalization hiện tại.
- `PUT /api/UserAiProfile/me` — cập nhật preferences phục vụ cá nhân hóa.
- `POST /api/Auth/logout` — đăng xuất, thường dùng kết hợp với thu hồi consent trên client.

### B. Analytics / tracking consent
- `GET /api/Analytics/dashboard` — xem tổng quan KPI để biết hệ thống đang hoạt động thế nào.
- `GET /api/Analytics/summary` — báo cáo tổng hợp theo khoảng thời gian.
- `GET /api/Analytics/activity-log` — theo dõi các hành vi quan trọng nếu user đã đồng ý analytics.
- `POST /api/Analytics/activity-log` — ghi nhận sự kiện khi consent analytics đang bật.

### C. Safety / health risk / disclaimer support
- `GET /api/HealthProfile/me` — lấy dữ liệu sức khỏe để xác định nhóm rủi ro cao.
- `PUT /api/HealthProfile/me` — cập nhật dữ liệu sức khỏe để hỗ trợ cảnh báo phù hợp.
- `GET /api/Allergy/me` hoặc API allergy tương đương — dùng để cảnh báo dị ứng và safety warning.
- `GET /api/Onboarding/me` hoặc API onboarding tương đương — kiểm tra user đã đọc/đồng ý disclaimer hay chưa.

### D. Export / delete data
- `GET /api/Profile/export` — xuất dữ liệu cá nhân của user.
- `DELETE /api/Profile/me` — xóa dữ liệu cá nhân theo yêu cầu.
- `GET /api/User/export` — xuất toàn bộ dữ liệu user nếu hệ thống tách theo user aggregate.
- `DELETE /api/User/me` — xóa account hoặc dữ liệu liên quan nếu policy cho phép.

### E. Production incident / support
- `GET /api/Notification/history` — xem lịch sử notification nếu cần audit.
- `POST /api/Notification/test` — kiểm tra push/notification trước khi release.
- `GET /api/Dashboard/health` — nếu có dashboard vận hành, dùng để theo dõi trạng thái tổng thể.
- `GET /api/Analytics/error-events` — nếu hệ thống đã ghi log lỗi vận hành, dùng để theo dõi issue production.

**Ghi chú tránh code trùng với API đã có:**
- Disclaimer nên được hiển thị từ UI/config hoặc onboarding flow hiện có, không cần một engine disclaimer riêng nếu chỉ là text tĩnh.
- Consent analytics/notification nên tái sử dụng profile/onboarding hiện có thay vì tạo bảng consent trùng lặp.
- Export/delete dữ liệu nên gắn vào `Profile`, `User`, hoặc `Auth` flow hiện có; chỉ tách API mới nếu policy yêu cầu luồng riêng.
- Các cảnh báo rủi ro cao nên suy ra từ `HealthProfile`, `Allergy`, `Onboarding` và `NutritionTracking` hiện có, không tạo risk engine mới trùng chức năng.

**API mới chỉ nên tách riêng nếu triển khai thật sự cần:**
- `GET /Safety/disclaimer` — trả nội dung disclaimer chuẩn theo version.
- `PUT /Safety/consent` — cập nhật consent analytics/notification/marketing.
- `GET /Safety/consent` — lấy trạng thái consent hiện tại của user.
- `GET /Safety/alerts` — trả cảnh báo an toàn/rủi ro cao theo profile sức khỏe.
- `POST /Safety/export-data` — yêu cầu xuất toàn bộ dữ liệu cá nhân.
- `DELETE /Safety/delete-data` — yêu cầu xóa dữ liệu cá nhân theo chính sách.
- `POST /Safety/report-issue` — gửi phản hồi lỗi production hoặc sự cố quan trọng.

**Ưu tiên triển khai kỹ thuật:**
1. Làm disclaimer + consent trước để đáp ứng yêu cầu store và privacy.
2. Tái sử dụng profile/health/allergy/onboarding hiện có để tránh code trùng.
3. Chỉ tách API riêng cho export/delete/report issue khi thật sự cần luồng độc lập.

---

## 3) Ma trận workflow ưu tiên triển khai

- **P1 - Cốt lõi sử dụng hằng ngày**
  - ~~Account lifecycle~~ ✅
  - ~~Onboarding sức khỏe~~ ✅
  - ~~Meal log + weight log + dashboard (2.4)~~ ✅
  - ~~Allergy-safe discovery cơ bản (2.3)~~ ✅
  - Beginner quick-start workflow (Hôm nay ăn gì?) — **chưa màn riêng**
  - Safety/compliance bắt buộc cho launch:
    - disclaimer dinh dưỡng
    - consent analytics/notification
    - luồng export/delete dữ liệu cơ bản
- **P2 - Tăng giá trị và giữ chân**
  - Meal plan + notification (2.5, 2.9)
  - Recommendation history + feedback loop (2.6)
  - Favorite food và quick-add meal template
  - Vietnam-first local nutrition workflow cơ bản (2.11)
  - Real-world food data capture (template + khẩu phần địa phương, 2.14)
  - Gym/PT goal-based workflow cơ bản (2.13)
  - Goal drift alert rolling 7 ngày (mở rộng cảnh báo macro ngày hiện có)
- **P3 - Premium và tối ưu doanh thu**
  - AI assistant sâu theo ngữ cảnh (2.7)
  - Subscription/payment lifecycle hoàn chỉnh (2.8 — phần lớn đã có)
  - Analytics nâng cao + segmentation (2.10)
  - Safety/compliance nâng cao (risk automation, compliance analytics) + coach/PT sharing workflow


## 4) Đề xuất tính năng mới cho app dinh dưỡng

## 4.1 Nhóm “nên làm sớm” (high impact, effort vừa phải)

1. **Smart Streak & Habit Score** (Đã làm)
   - Điểm thói quen theo chuỗi ngày log bữa, log cân, đạt mục tiêu calories.
   - Tăng động lực quay lại app.

   **Chức năng tương đương đã có trong hệ thống:**
   - `NutritionTrackingController` (`/api/NutritionTracking`) cho meal log, weight log, summary, trends.
   - `GymGoalsController` (`/api/GymGoals`) cho alerts và recalibrate theo tuần.
   - `NotificationController` (`/api/Notification`) cho reminder, tracking mở/click và analytics.

   **Giải thích đúng workflow:**
   - Chức năng này theo dõi hành vi duy trì đều đặn của user thay vì chỉ nhìn một ngày riêng lẻ.
   - Hệ thống có thể cộng điểm khi user hoàn thành các hành vi tốt như log bữa đúng giờ, log cân định kỳ, bám sát mục tiêu calories và không bỏ log quá lâu.
   - Mục tiêu cuối cùng là biến dữ liệu sử dụng hằng ngày thành một chỉ số dễ hiểu để tạo động lực, nhắc nhở và tăng retention.

   **API khớp với code hiện tại (để implement Habit Score):**

   ### A. Nguồn dữ liệu cho Habit Score
   - `GET /api/NutritionTracking/meal-logs` — dữ liệu meal log để tính mức độ log đều.
   - `GET /api/NutritionTracking/weight-logs` — dữ liệu weight log để tính độ duy trì thói quen.
   - `GET /api/NutritionTracking/dashboard` — dashboard tổng hợp phục vụ tính score.
   - `GET /api/NutritionTracking/summary` — tổng hợp dinh dưỡng theo ngày/tuần/tháng.
   - `GET /api/NutritionTracking/trends` — xu hướng dinh dưỡng theo thời gian.
   - `GET /api/NutritionTracking/weight-logs/trend` — xu hướng cân nặng.

   ### B. Goal / alert signals dùng cho Habit Score
   - `GET /api/GymGoals/alerts` — cảnh báo lệch mục tiêu, dùng như tín hiệu trừ điểm.
   - `POST /api/GymGoals/recalibrate` — thu thập dữ liệu để tái cân chỉnh mục tiêu.
   - `GET /api/GymGoals/coach-report` — báo cáo tổng hợp cho coach/insight.

   ### C. API Habit Score do mình vừa code thêm
   - `GET /api/Engagement/habit-score` — trả Habit Score tổng hợp hiện tại.
   - `GET /api/Engagement/habit-score/history` — lịch sử Habit Score theo ngày.
   - `GET /api/Engagement/habit-score/breakdown` — breakdown các thành phần cấu thành score.
   - `GET /api/Engagement/streak` — streak hiện tại để hỗ trợ Habit Score.
   - `GET /api/Engagement/notification-engagement` — mức độ tương tác notification.

   ### D. Notifications / nudges
   - `GET /api/Notification/settings` — lấy cấu hình nhắc hiện tại.
   - `PUT /api/Notification/settings` — cập nhật cấu hình nhắc.
   - `POST /api/Notification/meal-plan-remind` — tạo nhắc bữa ăn.
   - `POST /api/Notification/schedule-prep-reminder` — tạo nhắc chuẩn bị nguyên liệu.
   - `GET /api/Notification/analytics` — xem hiệu quả nhắc.

2. **Quick Add Meal Templates** (Đã làm)
   - Lưu “bữa thường dùng” để thêm nhanh.
   - Rất phù hợp với user ăn lặp lại menu.
   - *Đã có nền:* ghi log nhanh từ Khám phá/Trang chủ/Lịch sử (`meal_log_sheet`); chưa lưu template tái sử dụng.

   **Giải thích đúng workflow:**
   - Tính năng này cho phép user biến một bữa đã ăn nhiều lần thành template để lần sau thêm chỉ bằng vài thao tác.
   - Phù hợp nhất với user có thói quen ăn lặp lại món, đi làm theo ca cố định hoặc theo meal prep.
   - Mục tiêu là giảm ma sát khi log bữa, giúp người dùng duy trì thói quen đều hơn.

   **API cần có để làm đúng bài:**

   ### A. Meal template CRUD
   - `GET /MealTemplates` — lấy danh sách template của user.
   - `GET /MealTemplates/{id}` — xem chi tiết một template.
   - `POST /MealTemplates` — tạo template mới từ món/bữa hiện có.
   - `PUT /MealTemplates/{id}` — cập nhật template.
   - `DELETE /MealTemplates/{id}` — xoá template.

   ### B. Quick add from template
   - `POST /MealTemplates/{id}/log` — log trực tiếp template vào nhật ký ăn uống.
   - `POST /MealTemplates/{id}/duplicate` — sao chép template để chỉnh sửa nhanh.
   - `GET /MealTemplates/{id}/usage` — xem số lần sử dụng template.

3. **Adaptive Reminder** (Đã làm)
   - Notification tự điều chỉnh giờ nhắc theo hành vi mở app/log bữa.
   - Giảm spam, tăng tỉ lệ phản hồi.

   **Giải thích đúng workflow:**
   - Hệ thống quan sát các mốc mà user thường mở app, log bữa hoặc bỏ lỡ nhắc để tự tối ưu khung giờ gửi thông báo.
   - Thay vì đặt giờ cố định cho tất cả, reminder sẽ dần “học” theo lịch sinh hoạt của từng người.
   - Điều này giúp thông báo đúng lúc hơn và tránh gây khó chịu.

   **API cần có để làm đúng bài:**

   ### A. Reminder profile (Đã làm)
   - `GET /api/Reminder/profile` — lấy hồ sơ nhắc hiện tại của user.
   - `POST /api/Reminder/profile/recalculate` — tính lại khung giờ nhắc tối ưu.
   - `PUT /api/Reminder/profile` — cập nhật cấu hình nhắc theo ý user.

   ### B. Reminder scheduling (Đã làm)
   - `GET /api/Reminder/scheduled` — lấy danh sách reminder đã lên lịch.
   - `POST /api/Reminder/scheduled` — tạo reminder mới.
   - `PATCH /api/Reminder/scheduled/{id}` — bật/tắt hoặc đổi giờ nhắc.
   - `DELETE /api/Reminder/scheduled/{id}` — xoá reminder.

   ### C. Engagement tracking & Snooze (Đã làm)
   - `POST /api/Notification/{id}/track/open` — ghi nhận user mở thông báo (tái sử dụng hệ thống Notification hiện có).
   - `POST /api/Reminder/scheduled/{id}/snooze` — tạm hoãn nhắc.
   - `GET /api/Notification/analytics` — xem hiệu quả nhắc theo thời gian (tái sử dụng hệ thống Notification hiện có).

4. **Goal Drift Alert** (Đã làm)
   - Cảnh báo sớm khi xu hướng lệch mục tiêu (không chỉ theo ngày, mà theo rolling 7 ngày).
   - *Đã có nền:* cảnh báo calo/macro theo ngày (`WarningMessages` API + UI Lịch sử/Trang chủ).

   **Giải thích đúng workflow:**
   - Tính năng này không chỉ nhìn một ngày vượt/nghẹt mục tiêu, mà theo dõi xu hướng kéo dài để phát hiện drift sớm.
   - Ví dụ user ăn dư calo nhẹ nhưng liên tục trong 5–7 ngày thì hệ thống sẽ cảnh báo trước khi lệch quá xa.
   - Cách tiếp cận này tốt hơn cảnh báo theo ngày vì phản ánh đúng xu hướng hành vi.

   **API cần có để làm đúng bài:**

    ### A. Drift detection (Đã triển khai)
    - `GET /api/Goals/drift-alerts` — lấy danh sách cảnh báo drift.
    - `GET /api/Goals/drift-alerts/current` — xem cảnh báo hiện tại.
    - `POST /api/Goals/drift-alerts/recalculate` — tính lại drift từ dữ liệu 7 ngày/14 ngày.
    - `GET /api/Goals/drift-alerts/summary` — tóm tắt mức lệch mục tiêu theo tuần.

    ### B. Trend analytics (Tái sử dụng API có sẵn)
    - `GET /api/NutritionTracking/trends` — xem xu hướng calories và macro (dùng chung API trends).
    - `GET /api/NutritionTracking/weight-logs/trend` hoặc `GET /api/Dashboard/weight-trend` — xem xu hướng cân nặng.
    - `GET /api/MealPlan/compare` hoặc `GET /api/Engagement/habit-score` — xem mức độ bám mục tiêu (planned vs actual & habit score).

    ### C. Alert actions (Đã triển khai)
    - `POST /api/Goals/drift-alerts/{id}/dismiss` — bỏ qua cảnh báo.
    - `POST /api/Goals/drift-alerts/{id}/acknowledge` — xác nhận đã xem cảnh báo.
    - `POST /api/Goals/drift-alerts/{id}/create-nudge` — tạo nhắc hành động từ cảnh báo.

5. **Allergy Risk Badge**
   - Gắn nhãn mức rủi ro dị ứng trực tiếp trên danh sách món.

   **Giải thích đúng workflow:**
   - Khi user xem món ăn, hệ thống đối chiếu thành phần với hồ sơ dị ứng của user để gắn nhãn rủi ro ngay tại danh sách.
   - Badge có thể phân cấp theo mức độ như an toàn, có thể chứa thành phần cần tránh, hoặc rủi ro cao.
   - Mục tiêu là giúp user ra quyết định nhanh hơn mà không cần mở từng món.

   **API cần có để làm đúng bài:**

   ### A. Allergy profile
   - `GET /Allergies/profile` — lấy hồ sơ dị ứng của user.
   - `PUT /Allergies/profile` — cập nhật danh sách dị ứng.
   - `GET /Allergies/catalog` — lấy danh mục chất gây dị ứng hỗ trợ hệ thống.

   ### B. Risk evaluation
   - `POST /Allergies/evaluate` — đánh giá rủi ro dị ứng cho một món hoặc nhiều món.
   - `POST /Allergies/evaluate/batch` — đánh giá hàng loạt cho danh sách món.
   - `GET /Allergies/meal/{mealId}/badge` — lấy badge rủi ro cho món cụ thể.

   ### C. User experience
   - `GET /Allergies/recommendations` — gợi ý món phù hợp với hồ sơ dị ứng.
   - `POST /Allergies/recommendations/refresh` — làm mới gợi ý sau khi user đổi hồ sơ.

6. **Hôm nay ăn gì? (1-tap daily starter)**
   - Màn hình vào nhanh cho người mới, chọn ngay thực đơn trong ngày.

   **Giải thích đúng workflow:**
   - Đây là màn hình khởi đầu nhanh giúp user mới không bị “lạc” trong app.
   - Chỉ cần một chạm là có thể vào luôn luồng gợi ý thực đơn hôm nay, thay vì phải tự mò từng màn hình.
   - Rất phù hợp để tăng activation và giảm tỷ lệ thoát ở lần mở app đầu tiên.

   **API cần có để làm đúng bài:**

   ### A. Daily starter content
   - `GET /DailyStarter/today` — lấy nội dung khởi đầu cho hôm nay.
   - `GET /DailyStarter/recommendations` — lấy thực đơn gợi ý cho user mới.
   - `GET /DailyStarter/featured-meals` — lấy các món/meal nổi bật để bắt đầu nhanh.

   ### B. Quick action flows
   - `POST /DailyStarter/select-meal` — chọn nhanh một thực đơn để tiếp tục.
   - `POST /DailyStarter/start-log` — bắt đầu flow log bữa từ màn hình này.
   - `POST /DailyStarter/save-preference` — lưu sở thích ban đầu của user.

   ### C. Personalization
   - `GET /DailyStarter/personalization` — lấy mức cá nhân hoá hiện tại.
   - `PUT /DailyStarter/personalization` — cập nhật tiêu chí cá nhân hoá.

## 4.2 Nhóm “nâng cao trải nghiệm”

1. **Budget-aware Weekly Plan**
   - Lập meal plan theo ngân sách tuần/tháng kết hợp `BudgetRequest`.

2. **Ingredient Substitution Engine**
   - Gợi ý nguyên liệu thay thế khi dị ứng/khó mua/đắt.

3. **Contextual AI Coach**
   - AI trả lời theo ngữ cảnh hiện tại: “Hôm nay bạn còn thiếu Xg protein”.

4. **Planned vs Actual Insights**
   - So sánh kế hoạch ăn và thực tế, chỉ ra nguyên nhân lệch.

5. **Micro-learning Cards**
   - Các thẻ kiến thức ngắn theo vấn đề user đang gặp (thiếu protein, vượt fat...).

6. **Vietnam Portion Converter**
   - Bộ quy đổi đơn vị Việt Nam (bát/chén/muỗng/đĩa) sang gram.

---

## 4.3 Nhóm “premium/monetization”

1. **Premium Program Packs**
   - Gói theo mục tiêu: giảm cân 8 tuần, tăng cơ 12 tuần.

2. **Coach Mode (B2B2C/B2C+)**
   - Cho phép chuyên gia theo dõi chỉ số và phản hồi cho user.

3. **Dynamic Paywall by Value Moment**
   - Đề nghị nâng cấp khi user vừa nhận giá trị cao (ví dụ vừa hoàn thành plan tuần).

4. **Family Plan**
   - Nhiều hồ sơ trong một tài khoản (cha mẹ/con cái, cặp đôi).

5. **PT Review Mode**
   - Người dùng chia sẻ báo cáo tuần để PT nhận xét và điều chỉnh kế hoạch.

---

## 5) Đề xuất KPI để đo hiệu quả workflow/tính năng

- **Activation**
  - `register_to_onboarding_complete_rate`
  - `onboarding_to_first_meal_log_rate`
  - `first_day_plan_created_rate`
- **Engagement**
  - `meal_logs_per_user_per_week`
  - `weight_logs_per_user_per_month`
  - `recommendation_feedback_rate`
  - `daily_starter_click_rate` (hôm nay ăn gì)
- **Retention**
  - D1/D7/D30 retention
  - streak completion rate
  - weekly check-in completion rate
- **Monetization**
  - trial-to-paid conversion
  - renewal rate
  - churn rate theo plan
  - gym/PT segment conversion rate
  - ARPPU by segment (general vs gym/PT)

- **Trust & Compliance**
  - consent opt-in rate
  - data export completion rate
  - account deletion completion SLA

---

## 6) KPI governance (vận hành đo lường)

- **Weekly product review (bắt buộc):**
  - Theo dõi activation/engagement/retention theo cohort tuần.
  - Kiểm tra nhóm user mới “không biết ăn gì” và tỷ lệ quay lại ngày 2-7.
- **Monthly strategy review:**
  - Đánh giá KPI monetization theo segment (general vs gym/PT).
  - Rà soát trust/compliance KPI và backlog cải tiến.
- **Owner đề xuất:**
  - Product owner: Activation + Retention.
  - Growth/Marketing: Engagement + Re-engagement.
  - Tech lead: Reliability + Trust/Compliance SLA.

---

## 7) Gợi ý hướng tổ chức tài liệu tiếp theo

- **Tài liệu chính (đã có):**
  - [`README_USER_WORKFLOW.md`](README_USER_WORKFLOW.md) — hành trình user 4.1–4.11, ma trận UI/API, QA checklist, P1/P2/P3
  - [`README_SEPAY_PAYMENT_WORKFLOW.md`](README_SEPAY_PAYMENT_WORKFLOW.md) — thanh toán gói
  - `.cursor/rules/backend-english-frontend-vietnamese-i18n.mdc` — API English, UI Vietnamese
  - `.cursor/rules/vietnamese-only-responses.mdc` — AI assistant trả lời tiếng Việt trong Cursor
- **Có thể tách thêm:**
  1. `README_WORKFLOW_DATA.md` (entity + relation + data contract)
  2. `README_WORKFLOW_METRICS.md` (event tracking + KPI + dashboard định kỳ)

**File code tham chiếu nhanh (2.4):**

| Layer | Đường dẫn |
|-------|-----------|
| API | `backend/MenuGreen.API/Controllers/NutritionTrackingController.cs` |
| Services | `NutritionTrackingService.cs`, `NutritionSnapshotService.cs`, `NutritionWarningsBuilder.cs` |
| Flutter repo | `frontend/lib/features/tracking/repositories/nutrition_tracking_repository.dart` |
| Flutter UI | `home_view.dart`, `history_view.dart`, `meal_log_sheet.dart`, `daily_summary_card.dart` |
| i18n | `frontend/lib/core/i18n/api_message_translator.dart` |

Tài liệu này đóng vai trò bản đồ tổng quan để team ưu tiên roadmap theo năng lực triển khai hiện tại.
