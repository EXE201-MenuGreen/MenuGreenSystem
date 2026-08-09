# Kế hoạch triển khai — Chuẩn hóa thông báo thân thiện, không lộ hạ tầng

**Dự án:** MenuGreen System  
**Phạm vi:** Flutter mobile (`frontend`)  
**Mục tiêu:** Không hiển thị cho người dùng chi tiết backend, cấu hình, secret/token, URL/IP, stack trace, HTTP status hay exception thô. Người dùng chỉ nhận thông báo tiếng Việt, thân thiện, có hướng dẫn hành động phù hợp.

## 1. Kết quả rà soát

Thông báo đã sửa ở Auth chỉ xử lý một nhánh `Connection error. Is backend running?`. Các đường rò rỉ còn lại gồm:

| Nhóm | Phát hiện | Rủi ro |
|---|---|---|
| Banner kết nối | “Đang mất kết nối với máy chủ…”, “Đã kết nối lại với máy chủ!” | Lộ kiến trúc máy chủ và không theo câu chữ thân thiện đã yêu cầu. |
| Auth/Google | `Google sign-in is not configured on the server`, `Backend chưa cấu hình Firebase Admin`, `firebase-adminsdk.json`, Firebase chưa khởi tạo, Firebase ID token | Lộ backend, file cấu hình và cơ chế xác thực. |
| Firebase Storage | Hướng dẫn Firebase Console, Storage Rules, `avatars/{userId}`, mã/chi tiết Firebase exception | Lộ cấu hình, đường dẫn dữ liệu và quyền nội bộ. |
| API translator | `ApiMessageTranslator` giữ nguyên mọi chuỗi “trông như tiếng Việt”; một mapping đang nói “Database schema… run migrations”. | Backend có thể trả tiếng Việt chứa database, migration, API key, token… và được đưa thẳng ra UI. |
| UI/Provider | Nhiều `error.toString()`, `snapshot.error`, `provider.error` và interpolation `Lỗi: $error` | Có thể lộ exception, response body, URL, token hoặc thông tin nhà cung cấp. |
| Repository | Một số repository trả raw `message` từ response/API vào Provider/UI. | Bỏ qua translator trung tâm, tạo regression ở màn hình mới. |

## 2. Quy ước thông điệp người dùng

1. Giữ thông báo nghiệp vụ đã được duyệt (ví dụ: email/mật khẩu sai, OTP hết hạn, không có quyền, dữ liệu biểu mẫu không hợp lệ).
2. Chỉ hiển thị các thông điệp đã được whitelist/dịch rõ nghĩa. Chuỗi unknown luôn chuyển thành fallback theo ngữ cảnh, không trả lại raw text.
3. Không hiển thị các từ/chi tiết hạ tầng: backend, server/máy chủ (trong ngữ cảnh kỹ thuật), database/schema/migration, Firebase Console/Rules, API endpoint/URL/IP/port, HTTP status, exception/stack trace, request/response body, JWT/access/refresh token, API key, secret, file cấu hình hoặc đường dẫn nội bộ.
4. Dùng câu chữ thống nhất:
   - Kết nối/chờ đồng bộ: **“Bạn vui lòng chờ để ghi nhận kết nối thông tin.”**
   - Lỗi dịch vụ/không xác định: **“Thao tác chưa thể hoàn tất. Vui lòng thử lại sau.”**
   - Google Sign-In không sẵn sàng: **“Đăng nhập Google hiện chưa sẵn sàng. Vui lòng thử lại sau hoặc dùng email.”**
   - Tải ảnh thất bại: **“Chưa thể tải ảnh lên. Vui lòng thử lại.”**
   - Quyền vị trí bị từ chối: nêu hành động người dùng cần thực hiện, không nêu Goong key hay cấu hình dịch vụ.
5. Chi tiết gốc chỉ được ghi qua `debugPrint`/logging đã có cơ chế che dữ liệu; không đưa vào `SnackBar`, `Text`, empty/error state hoặc notification.

## 3. Thiết kế thực hiện

### 3.1. Điểm chuẩn hóa duy nhất

[MODIFY] `frontend/lib/core/i18n/api_message_translator.dart`

- Mở rộng translator thành cổng duy nhất cho mọi message không do UI tự tạo: nhận `raw` và fallback theo ngữ cảnh (`general`, `connection`, `authentication`, `upload`, `location`).
- Duy trì dictionary/regex cho lỗi nghiệp vụ an toàn; unknown không được trả nguyên văn.
- Kiểm tra technical/sensitive trước nhánh “giữ nguyên tiếng Việt”, kể cả chuỗi tiếng Việt. Nhận diện cả Anh/Việt và cấu trúc URL/IP/token/key/JSON/stack trace.
- Chuyển mapping `Database schema is outdated. Please run migrations.` thành fallback chung; bổ sung mapping cho lỗi Google/Firebase phổ biến bằng câu thân thiện.
- Bảo đảm input HTML, JSON/ProblemDetails lồng nhau, exception prefix, message có CR/LF và response body đều không thể đi qua nguyên văn.

### 3.2. Nguồn lỗi hạ tầng và trạng thái kết nối

[MODIFY] `frontend/lib/core/widgets/connection_status_banner.dart`

- Đổi hai text banner không nhắc “máy chủ/backend”; trạng thái retry dùng thông điệp kết nối chuẩn, trạng thái khôi phục dùng “Kết nối đã được khôi phục.”

[MODIFY] `frontend/lib/core/middleware/error_translator.dart`  
[MODIFY] `frontend/lib/core/middleware/error_middleware.dart`

- Cho transport/status-code fallback đi qua chuẩn câu chữ ở mục 2; không tạo raw string riêng tại middleware.
- Vẫn giữ phân loại nội bộ `ApiErrorType` để retry, logging và test, nhưng không đưa `cause`/status chi tiết ra UI.

[MODIFY] `frontend/lib/features/auth/utils/auth_error_messages.dart`  
[MODIFY] `frontend/lib/features/auth/repositories/auth_repository.dart`

- Xóa/đổi mọi mapping và fallback lộ Backend, Firebase Admin, file `firebase-adminsdk.json`, token Google; mọi unknown Auth phải qua sanitizer thay vì `return normalized`.

[MODIFY] `frontend/lib/core/services/firebase_storage_errors.dart`  
[MODIFY] `frontend/lib/core/services/firebase_google_auth_service.dart`  
[MODIFY] `frontend/lib/firebase_options.dart`

- Thay thông báo hướng dẫn Firebase Console/Rules, mã Firebase, client/token và file cấu hình bằng thông báo theo ngữ cảnh.
- Giữ diagnostic nội bộ trong log debug (đã che secret), không biến chi tiết thành exception để UI hiển thị.

### 3.3. Xóa các đường hiển thị exception/message raw

Áp dụng `ApiMessageTranslator`/helper chuẩn trước khi hiển thị hoặc trước khi gán state lỗi. Không dùng `replaceFirst('Exception: ', '')` như một biện pháp bảo mật.

**Nhóm Provider/repository cần chuẩn hóa trước khi publish state:**

- [MODIFY] `frontend/lib/features/coach_chat/providers/coach_chat_provider.dart`
- [MODIFY] `frontend/lib/features/coach_pt/providers/coach_meal_plan_provider.dart`
- [MODIFY] `frontend/lib/features/coach_pt/providers/coach_report_provider.dart`
- [MODIFY] `frontend/lib/features/discover/providers/recommendation_provider.dart`
- [MODIFY] `frontend/lib/features/ai_assistant/providers/ai_assistant_provider.dart`
- [MODIFY] `frontend/lib/features/meal_plan/providers/meal_plan_provider.dart`
- [MODIFY] `frontend/lib/features/discover/repositories/recommendation_repository.dart`
- [MODIFY] `frontend/lib/features/onboarding/repositories/onboarding_repository.dart`
- [MODIFY] `frontend/lib/features/onboarding/repositories/health_profile_repository.dart`
- [MODIFY] `frontend/lib/features/onboarding/repositories/user_ai_profile_repository.dart`
- [MODIFY] `frontend/lib/features/subscription/repositories/sepay_payment_repository.dart`

**Nhóm view/widget có đường hiển thị trực tiếp đã xác nhận:**

- [MODIFY] `frontend/lib/features/adaptive_reminders/views/adaptive_reminders_screen.dart`
- [MODIFY] `frontend/lib/features/adaptive_reminders/views/adaptive_reminder_widgets_part.dart`
- [MODIFY] `frontend/lib/features/advanced/views/advanced_features_screen.dart`
- [MODIFY] `frontend/lib/features/advanced/views/advanced_detail_screens.dart`
- [MODIFY] `frontend/lib/features/ai_assistant/views/ai_chat_screen.dart`
- [MODIFY] `frontend/lib/features/coach/views/coach_main_screen.dart`
- [MODIFY] `frontend/lib/features/coach_chat/views/coach_chat_screen.dart`
- [MODIFY] `frontend/lib/features/coach_chat/views/coach_chat_partners_screen.dart`
- [MODIFY] `frontend/lib/features/coach_pt/views/coach_report_select_client_screen.dart`
- [MODIFY] `frontend/lib/features/coach_pt/views/coach_report_detail_screen.dart`
- [MODIFY] `frontend/lib/features/coach_pt/views/coach_meal_plan_detail_screen.dart`
- [MODIFY] `frontend/lib/features/coach_pt/views/coach_meal_plan_history_screen.dart`
- [MODIFY] `frontend/lib/features/coach_pt/views/coach_meal_plan_select_client_screen.dart`
- [MODIFY] `frontend/lib/features/coach_pt/views/coach_reports_tab_screen.dart`
- [MODIFY] `frontend/lib/features/discover/views/discover_view.dart`
- [MODIFY] `frontend/lib/features/discover/views/budget_aware_screen.dart`
- [MODIFY] `frontend/lib/features/discover/views/weekly_plan_screen.dart`
- [MODIFY] `frontend/lib/features/discover/views/recommendation_screen.dart`
- [MODIFY] `frontend/lib/features/discover/views/safe_recommendations_screen.dart`
- [MODIFY] `frontend/lib/features/gymer/views/route_approval_detail_screen.dart`
- [MODIFY] `frontend/lib/features/gymer/views/premium_programs_screen.dart`
- [MODIFY] `frontend/lib/features/meal_templates/views/meal_templates_screen.dart`
- [MODIFY] `frontend/lib/features/meal_templates/views/meal_template_editor_part.dart`
- [MODIFY] `frontend/lib/features/micro_learning/views/micro_learning_screen.dart`
- [MODIFY] `frontend/lib/features/micro_learning/views/micro_learning_detail_part.dart`
- [MODIFY] `frontend/lib/features/micro_learning/views/micro_learning_saved_part.dart`
- [MODIFY] `frontend/lib/features/meal_plan/views/meal_plan_today_screen.dart`
- [MODIFY] `frontend/lib/features/meal_plan/views/meal_plan_detail_screen.dart`
- [MODIFY] `frontend/lib/features/meal_plan/views/meal_plan_screen.dart`
- [MODIFY] `frontend/lib/features/meal_plan/views/create_meal_plan_screen.dart`
- [MODIFY] `frontend/lib/features/meal_plan/widgets/edit_item_sheet.dart`
- [MODIFY] `frontend/lib/features/office/views/office_meal_plan_screen.dart`
- [MODIFY] `frontend/lib/features/subscription/views/sepay_payment_screen.dart`
- [MODIFY] `frontend/lib/features/vietnam_local/views/consent_screen.dart`
- [MODIFY] `frontend/lib/features/vietnam_local/views/daily_starter_personalization_screen.dart`
- [MODIFY] `frontend/lib/features/vietnam_local/views/food_capture_screen.dart`
- [MODIFY] `frontend/lib/features/vietnam_local/views/gym_goals_screen.dart`
- [MODIFY] `frontend/lib/features/vietnam_local/views/ingredient_substitution_screen.dart`
- [MODIFY] `frontend/lib/features/vietnam_local/views/local_preferences_screen.dart`
- [MODIFY] `frontend/lib/features/vietnam_local/views/planned_vs_actual_screen.dart`
- [MODIFY] `frontend/lib/features/vietnam_local/views/safety_hub_screen.dart`

Các màn hình còn dùng `provider.error`, `provider.errorMessage`, `_error`, `snapshot.error` hoặc `result.message` phải được Developer quét lại bằng lệnh ở mục 5, kể cả khi không có trong danh sách trên. Đây là requirement bao phủ, không chỉ là danh sách ví dụ.

## 4. Rủi ro và giới hạn

- Không che lỗi validation do người dùng có thể sửa; nếu không có mapping an toàn thì fallback chung thay vì phản chiếu API message.
- Không log access/refresh token, password, OTP, API key, Authorization header hay body chứa dữ liệu nhạy cảm trong lúc bổ sung debug logging.
- Thay đổi chỉ ở frontend presentation/error normalization; không đổi API contract, database hay backend.
- Cần kiểm tra UI có content dài trên banner và error state ở mobile để tránh tràn layout.

## 5. Kế hoạch kiểm thử và tiêu chí nghiệm thu

[NEW] `frontend/test/api_message_translator_test.dart` (mở rộng)

- Bảng test input độc hại: `Connection error. Is backend running?`, `Google sign-in is not configured on the server.`, Firebase Console/Rules, database/migration, URL/IP/port, JWT/token/API key, HTML, JSON ProblemDetails, `SocketException`, .NET stack trace và message kỹ thuật bằng tiếng Việt.
- Với từng input, assert output là thông điệp thân thiện dự kiến và **không chứa** các từ/giá trị nhạy cảm đầu vào.
- Regression test cho mapping nghiệp vụ hợp lệ: email/mật khẩu, OTP, quyền truy cập, validation biểu mẫu và thanh toán bị hủy.

[NEW] `frontend/test/connection_status_banner_test.dart`

- Render banner ở trạng thái reconnect/success; xác nhận text mới và không xuất hiện “máy chủ”, “backend”.

Kiểm tra bắt buộc trước hand-off:

1. `flutter test test/api_message_translator_test.dart test/connection_status_banner_test.dart` pass.
2. `flutter analyze` không có lỗi mới.
3. Rà soát tĩnh các điểm hiển thị: `rg -n --glob '*.dart' "error\.toString\(|e\.toString\(|snapshot\.error|Text\(.*provider\.error|Lỗi: \$" frontend/lib`. Mọi kết quả có thể đưa raw ra UI phải được thay bằng sanitizer hoặc chứng minh chỉ là debug/log nội bộ.
4. Manual smoke test: tắt mạng/timeout, backend trả 500 HTML, Auth Google chưa cấu hình, upload ảnh bị cấm, lỗi API trả ProblemDetails và một lỗi validation hợp lệ. Không màn hình/snackbar/banner nào lộ thuật ngữ/ký tự kỹ thuật; validation an toàn vẫn có hướng dẫn cụ thể.

## 6. Open questions

Không có câu hỏi chặn triển khai. Tiêu chuẩn được áp dụng: ưu tiên bảo mật; nếu một message chưa được whitelist thì hiển thị fallback thân thiện.
