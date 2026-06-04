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

## 2.1 Account Lifecycle (Guest -> Active User)

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

## 2.2 Onboarding sức khỏe và baseline cá nhân

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

## 2.3 Khám phá món ăn an toàn theo dị ứng

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

## 2.4 Nhật ký dinh dưỡng hằng ngày

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

## 2.5 Meal Plan và routine ăn uống

**Mục tiêu:** Chuyển từ tracking bị động sang kế hoạch chủ động.

**Flow đề xuất:**

1. Tạo kế hoạch tuần/ngày (`MealPlanHeader`).
2. Gắn món theo từng bữa (`MealPlanItem`).
3. Nhắc giờ ăn/nấu ăn qua notification (`Notification`, `NotificationSetting`).
4. Sau khi ăn, chuyển plan item thành meal log để so sánh planned vs actual.

**Giá trị:** cải thiện khả năng tuân thủ, giảm quyết định tức thời.

---

## 2.6 Recommendation engine (Rule + AI)

**Mục tiêu:** Đề xuất món/thực đơn cá nhân hóa.

**Flow đề xuất:**

1. Thu ngữ cảnh từ `HealthProfile`, `UserAllergy`, lịch sử `MealLog`, `BudgetRequest`.
2. Sinh đề xuất và lưu lịch sử (`RecommendationHistory`).
3. User đánh giá chất lượng (`RecommendationFeedback`).
4. Tối ưu dần model/rule theo feedback.

**Giá trị:** đề xuất càng ngày càng phù hợp, đo được chất lượng recommendation.

**Trạng thái triển khai (2026):** `SafeRecommendationsScreen` + API `Recommendation/*` (calories, lunch, eco, daily-menu, `excludeUserAllergies`). Chưa có UI lịch sử đề xuất, feedback, smart-schedule.

---

## 2.7 AI Nutrition Assistant

**Mục tiêu:** Tương tác hội thoại và tư vấn tình huống.

**Flow đề xuất:**

1. Tạo cuộc hội thoại (`AiConversation`).
2. Lưu message theo lượt hỏi đáp (`AiMessage`).
3. Tận dụng hồ sơ AI (`UserAiProfile`) để cá nhân hóa ngữ cảnh.
4. Đề xuất hành động tiếp theo: meal plan, thay món, tối ưu budget.

**Giá trị:** tăng mức cá nhân hóa, tạo trải nghiệm giống “coach dinh dưỡng”.

---

## 2.8 Subscription & Payment lifecycle

**Mục tiêu:** Quản lý quyền truy cập tính năng nâng cao và dòng tiền.

**Flow đề xuất:**

1. Hiển thị gói (`SubscriptionPlan`).
2. User đăng ký/gia hạn/hủy (`UserSubscription`, `Subscription`).
3. Ghi nhận giao dịch (`SubscriptionTransaction`, `Payment`, `SepayTransaction`).
4. Đồng bộ quyền feature theo trạng thái thanh toán.

**Giá trị:** kiểm soát entitlement rõ ràng, đảm bảo dữ liệu thanh toán đối soát được.

**Trạng thái triển khai (2026):** UI gói + SePay QR/webhook; chi tiết luồng trong [`README_SEPAY_PAYMENT_WORKFLOW.md`](README_SEPAY_PAYMENT_WORKFLOW.md).

---

## 2.9 Notification & Re-engagement

**Mục tiêu:** Nhắc user quay lại app và duy trì thói quen.

**Flow đề xuất:**

1. User cấu hình kênh/khung giờ (`NotificationSetting`).
2. Hệ thống phát thông báo (`Notification`) theo sự kiện:
   - Đến giờ ăn
   - Chưa log bữa trong ngày
   - Sắp hết hạn subscription
   - Nhắc cân mỗi tuần
3. Theo dõi open/click (có thể ghi `ActivityLog`).

**Giá trị:** tăng retention và giảm drop-off.

---

## 2.10 Audit & Product analytics

**Mục tiêu:** Đo usage thực tế và hỗ trợ vận hành.

**Flow đề xuất:**

1. Ghi sự kiện quan trọng (`ActivityLog`): register, onboarding_completed, meal_logged, subscribe...
2. Tổng hợp funnel và cohort.
3. Phân tích điểm rơi rời bỏ để tối ưu UX.

**Giá trị:** dữ liệu ra quyết định cho Product/Marketing/CS.

---

## 2.11 Vietnam-first local nutrition workflow

**Mục tiêu:** Tăng mức phù hợp cho người dùng Việt Nam trong sử dụng hằng ngày.

**Flow đề xuất:**

1. User chọn vùng/khẩu vị ưu tiên khi onboarding (Bắc/Trung/Nam, ăn ngoài/nấu tại nhà).
2. Hệ thống ưu tiên món Việt quen thuộc trong discovery/recommendation.
3. Gợi ý khẩu phần theo đơn vị quen thuộc (chén, bát, muỗng, đĩa) và quy đổi gram.
4. Ưu tiên món theo ngân sách phổ biến tại Việt Nam.

**Giá trị:** giảm rào cản sử dụng, tăng cảm giác “app hiểu người dùng Việt”.

---

## 2.12 Beginner quick-start workflow (Hôm nay ăn gì?)

**Mục tiêu:** Hỗ trợ nhóm người dùng chưa biết ăn gì mỗi ngày.

**Flow đề xuất:**

1. User vào màn hình nhanh “Hôm nay ăn gì?”.
2. Hệ thống trả 3-5 gợi ý theo mục tiêu calories/macro và dị ứng.
3. User chọn nhanh hoặc bấm đổi món 1 chạm.
4. Tạo sẵn meal plan/ngày và cho phép log nhanh sau khi ăn.

**Giá trị:** rút ngắn thời gian ra quyết định, tăng tỉ lệ dùng app hằng ngày.

---

## 2.13 Gym/PT goal-based workflow

**Mục tiêu:** Phục vụ nhóm tập gym/PT theo mục tiêu cụ thể.

**Flow đề xuất:**

1. User chọn goal mode: cut/bulk/maintain/recomp.
2. Thiết lập lịch tập và phân tách ngày tập/ngày nghỉ.
3. Hệ thống điều chỉnh target calories/macro theo loại ngày.
4. Áp dụng guardrail an toàn (ngưỡng calories/macro tối thiểu-tối đa) để tránh kế hoạch cực đoan.
5. Theo dõi planned vs actual theo tuần và phát cảnh báo lệch mục tiêu.
6. Recalibrate mục tiêu theo chu kỳ tuần dựa trên tiến độ thực tế.
7. (Nâng cao) chia sẻ báo cáo cho PT/coach để review.

**Giá trị:** phù hợp nhu cầu người tập nghiêm túc và tăng retention nhóm gym.

---

## 2.14 Real-world food data capture workflow

**Mục tiêu:** Ghi log dinh dưỡng nhanh và sát thực tế đời sống.

**Flow đề xuất:**

1. Log bữa bằng 3 cách: tìm món, chọn template, quét barcode (đồ đóng gói).
2. Hỗ trợ chọn khẩu phần nhanh theo đơn vị thường dùng.
3. Hệ thống quy đổi khẩu phần về gram để tính calories/macro nhất quán.
4. Nếu không tìm thấy món/barcode lỗi, user dùng fallback nhập tay nhanh (macro ước tính + ghi chú).
5. User chỉnh tay nếu sai lệch và lưu thành quick-add lần sau.

**Giá trị:** giảm friction khi ghi log và tăng độ chính xác dữ liệu.

---

## 2.15 Safety, trust, and compliance workflow (Play Store-ready)

**Mục tiêu:** Đảm bảo app an toàn, đáng tin cậy và phù hợp phát hành CH Play.

**Flow đề xuất:**

1. Hiển thị disclaimer rõ: app hỗ trợ dinh dưỡng, không thay thế chẩn đoán y khoa.
2. Với nhóm rủi ro cao, hiển thị cảnh báo và gợi ý tham vấn chuyên gia.
3. Quản lý consent cho analytics/notification rõ ràng.
4. Cung cấp luồng export/delete dữ liệu người dùng theo yêu cầu.
5. Theo dõi sự cố quan trọng và phản hồi lỗi ổn định cho production.

**Giá trị:** tăng trust, giảm rủi ro vận hành và hỗ trợ tiêu chuẩn phát hành.

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

---

## 4) Đề xuất tính năng mới cho app dinh dưỡng

## 4.1 Nhóm “nên làm sớm” (high impact, effort vừa phải)

1. **Smart Streak & Habit Score**
   - Điểm thói quen theo chuỗi ngày log bữa, log cân, đạt mục tiêu calories.
   - Tăng động lực quay lại app.

2. **Quick Add Meal Templates**
   - Lưu “bữa thường dùng” để thêm nhanh.
   - Rất phù hợp với user ăn lặp lại menu.
   - *Đã có nền:* ghi log nhanh từ Khám phá/Trang chủ/Lịch sử (`meal_log_sheet`); chưa lưu template tái sử dụng.

3. **Adaptive Reminder**
   - Notification tự điều chỉnh giờ nhắc theo hành vi mở app/log bữa.
   - Giảm spam, tăng tỉ lệ phản hồi.

4. **Goal Drift Alert**
   - Cảnh báo sớm khi xu hướng lệch mục tiêu (không chỉ theo ngày, mà theo rolling 7 ngày).
   - *Đã có nền:* cảnh báo calo/macro theo ngày (`WarningMessages` API + UI Lịch sử/Trang chủ).

5. **Allergy Risk Badge**
   - Gắn nhãn mức rủi ro dị ứng trực tiếp trên danh sách món.

6. **Hôm nay ăn gì? (1-tap daily starter)**
   - Màn hình vào nhanh cho người mới, chọn ngay thực đơn trong ngày.

---

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
