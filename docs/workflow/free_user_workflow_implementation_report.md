# Báo cáo triển khai Free User Workflow

> Cập nhật ngày 22/07/2026  
> Nhánh triển khai: `free-user-workflow`  
> Tài liệu đối chiếu: `D:\EXE\MenuGreen_Free_User_Workflow_new.md`

## 1. Kết quả

Free User Workflow đã được triển khai xuyên suốt backend và Flutter theo nguyên tắc: tài khoản người dùng hợp lệ luôn có `free_features`; subscription chỉ cộng thêm quyền trả phí và không thay đổi role hệ thống.

Home Free hiện cung cấp vòng lặp sử dụng cơ bản gồm tìm món, ghi bữa ăn, tra cứu calorie, theo dõi cân nặng, lập kế hoạch ăn thủ công, ghi nhận ăn ngoài và xem món yêu thích. Lucky Wheel, Daily Starter, Office và Gym/PT không còn xuất hiện lẫn trong grid Free.

Không phát sinh migration hoặc thay đổi schema cơ sở dữ liệu.

## 2. Mô hình quyền truy cập

### 2.1. Nguồn quyền tập trung

Đã bổ sung endpoint:

```http
GET /api/UserSubscription/me/entitlements
Authorization: Bearer <token>
```

Response khi người dùng không có subscription trả phí hiệu lực:

```json
{
  "tier": "free",
  "entitlements": ["free_features"],
  "featureGroups": ["free"],
  "expiresAt": null
}
```

Resolver chỉ công nhận subscription khi đồng thời thỏa mãn:

- `Status = Active`;
- `StartDate <= now`;
- `EndDate > now`.

Nhiều subscription đang hoạt động được hợp nhất. `free_features` luôn tồn tại; thời điểm hết hạn trả về là hạn xa nhất trong các gói trả phí được nhận diện.

### 2.2. Mapping entitlement

| Nhóm | Entitlement |
| --- | --- |
| Free | `free_features` |
| Casual | `casual_features` |
| Office | `office_features` |
| Gym/PT | `gym_features` |
| Kết nối Coach | `coach_access` |
| AI chuyên biệt | `ai_features` |

Gói `basic` không cộng quyền trả phí và được xem là Free. Trước 2026-07-24 các feature group `pro/premium/vip/gold` được quy đổi tương thích thành Casual + Gym/PT + Coach + AI; hiện tại nhánh mapping đã được gỡ khỏi `FeatureAccessResolver` vì dự án chỉ còn 4 gói Free, Casual, Gym/PT và Office.

### 2.3. Role và subscription

Đã gỡ việc đổi role người dùng theo tên gói khỏi các luồng đăng ký, thanh toán SePay, hủy và hết hạn subscription. Role tiếp tục dùng cho quyền hệ thống (`User`, `Admin`, `Coach`); entitlement quyết định quyền sản phẩm.

Các role sản phẩm cũ vẫn được chấp nhận trong policy `UserOnly` để không làm hỏng tài khoản đã tồn tại, nhưng code mới không tiếp tục ghi các role đó khi subscription thay đổi.

## 3. Authorization backend

`EntitlementHandler` đã chuyển sang kiểm tra quyền qua `IFeatureAccessService`. Admin vẫn có quyền bypass quản trị.

Các ranh giới chính đã áp dụng:

| Phạm vi | API/luồng được gate |
| --- | --- |
| Casual | Lucky Wheel, Daily Starter, gợi ý cá nhân hóa, tạo daily/weekly plan tự động, smart schedule, micro-learning đề xuất và quiz, tạo meal plan từ daily menu |
| Office | tạo/cập nhật budget request, cấu hình và tạo/sửa/snooze reminder, scan vào meal plan, tạo kế hoạch theo ngân sách, grocery list, budget status và phân tích chi phí Office |
| Gym/PT | Gym Goals, PT Review và các luồng Gym hiện có |
| Coach | kết nối Coach |
| AI | AI Assistant, AI Coach và Nutrition Assistant |

Các API Free hiện có như meal log thủ công, kế hoạch ăn CRUD thủ công, dữ liệu sức khỏe/dị ứng, cân nặng, tra cứu món và scan calorie cơ bản vẫn dùng authorization người dùng thông thường.

Khi gói hết hạn, resolver tự loại quyền trả phí nhưng không xóa hoặc đổi role. Với dữ liệu Office, các API đọc/xóa cần thiết vẫn mở cho chủ sở hữu để người dùng có thể xem hoặc dọn dữ liệu cũ; thao tác tạo mới và tự động hóa trả về `403`.

Daily Starter background job cũng kiểm tra `casual_features` trước khi tiền xử lý, tránh chạy tác vụ trả phí cho Free.

## 4. Micro-learning Free

Đã bổ sung API thư viện chung:

```http
GET /api/MicroLearning/cards/library?category=<optional>
```

API trả các card đang hoạt động theo danh mục và ghép trạng thái đã đọc/đã lưu của người dùng, không cá nhân hóa. Người dùng Free có thể đọc, lưu và xem danh sách đã lưu; phần đề xuất cá nhân hóa và quiz yêu cầu Casual.

Flutter tự chọn nguồn dữ liệu:

- Casual: danh sách đề xuất cá nhân hóa, progress và quiz;
- Free hoặc entitlement lỗi: thư viện chung, không progress game hóa và không quiz.

## 5. Flutter Home và fallback

Đã thêm model `FeatureAccess` và repository tải endpoint quyền tập trung. Bất kỳ lỗi mạng, response lỗi hoặc JSON không hợp lệ đều fallback về hằng `FeatureAccess.free`; frontend không suy đoán quyền trả phí từ mode UI hoặc AI profile.

Grid Home Free có đúng bảy shortcut theo thứ tự:

1. Tìm món
2. Ghi bữa ăn
3. Tra cứu calo
4. Cân nặng
5. Kế hoạch ăn
6. Ăn ngoài?
7. Yêu thích

Nút `Khác` mở danh sách chức năng nhưng tiếp tục lọc Daily Starter, Office và Gym theo entitlement. Grid đã có semantic label phục vụ khả năng truy cập.

Các thay đổi hiển thị khác:

- chỉ tải và hiển thị Daily Starter/gợi ý khi có Casual;
- chỉ hiển thị panel Office khi có Office;
- chỉ hiển thị card Gym khi có Gym;
- chỉ hiển thị nút AI nổi khi có `ai_features`;
- chuyển kiểm tra quyền ở Gym Hub và Gym Goals sang endpoint entitlement;
- tách card khám phá Casual, Office và Gym/PT ra khỏi grid Free, đồng thời khẳng định công cụ Free vẫn được giữ khi nâng cấp.

## 6. Kiểm thử và xác minh

### Backend

Lệnh:

```powershell
dotnet test MenuGreen.sln --no-restore
```

Kết quả: **8/8 test pass**.

- 5 unit test cho Free mặc định, subscription hết hạn/hủy, subscription tương lai, hợp nhất nhiều gói; nhánh test "tương thích gói Pro" đã được thay bằng test cho Casual active (vì nhánh Pro đã bị gỡ).
- 3 integration test HTTP cho chưa xác thực nhận `401`, Free tải entitlement nhận `200`, Free gọi Lucky Wheel nhận `403`.

Build hoàn tất không có lỗi. Các warning nullable/obsolete còn lại nằm ở code có sẵn trước workflow và không chặn build.

### Flutter

```powershell
flutter analyze
flutter test
```

Kết quả:

- `flutter analyze`: **No issues found**;
- `flutter test`: **33/33 test pass**;
- test mới xác minh fallback Free, parse/merge entitlement, grid Free ở màn 360 px, ẩn shortcut trả phí và mở được sheet ghi cân nặng.

### Diff

`git diff --check` hoàn tất với exit code `0`. Không commit hoặc push được tạo trong quá trình triển khai.

## 7. Các file chính

Backend:

- `MenuGreen.BusinessLogicLayer/Services/FeatureAccessResolver.cs`
- `MenuGreen.BusinessLogicLayer/Services/FeatureAccessService.cs`
- `MenuGreen.API/Authorization/EntitlementHandler.cs`
- `MenuGreen.API/Controllers/UserSubscriptionController.cs`
- `MenuGreen.API/Controllers/MicroLearningController.cs`
- `MenuGreen.API/Program.cs`
- `MenuGreen.BusinessLogicLayer.Tests/FeatureAccessResolverTests.cs`
- `MenuGreen.API.Tests/FreeAccessAuthorizationTests.cs`

Flutter:

- `frontend/lib/features/subscription/models/subscription_models.dart`
- `frontend/lib/features/subscription/repositories/user_subscription_repository.dart`
- `frontend/lib/features/home/views/home_view.dart`
- `frontend/lib/features/home/widgets/quick_action_grid.dart`
- `frontend/lib/features/main/views/main_screen.dart`
- `frontend/lib/features/micro_learning/views/micro_learning_screen.dart`
- `frontend/test/feature_access_test.dart`
- `frontend/test/free_quick_action_grid_test.dart`

## 8. Lưu ý vận hành

Integration test hiện chạy bằng test host và service quyền giả lập, không kết nối database production hoặc AI worker. Trước khi release nên smoke-test thêm trên môi trường staging với bốn tài khoản thực: Free, Casual, Office và Gym/PT; đặc biệt kiểm tra dữ liệu subscription cũ có `FeatureGroup` đúng với mapping ở mục 2.2.
