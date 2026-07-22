# Báo cáo implementation Casual Workflow

Ngày kiểm tra: **22/07/2026**

Tài liệu nghiệp vụ: [`workflow/casual_workflow.md`](workflow/casual_workflow.md)

## 1. Kết luận điều hành

Casual Workflow đã có phần lớn cấu trúc frontend, API và service cho ba công cụ chính. Tuy nhiên trạng thái hiện tại **chưa đủ điều kiện xác nhận hoàn thành hoặc phát hành** vì có hai blocker:

1. Backend build thất bại trong `DailyStarterService`.
2. Subscription plan Casual dùng trùng UUID với Gym/PT trong seed database.

Mức **95% hoàn thành** của báo cáo cũ không còn phản ánh đúng source hiện tại. Báo cáo này không dùng phần trăm tổng hợp vì một lỗi build có thể chặn toàn bộ backend dù số lượng file đã triển khai cao.

Trạng thái tổng thể: **Implemented but release-blocked**.

## 2. Ma trận triển khai

| # | Hạng mục | Trạng thái | Bằng chứng/ghi chú |
|---:|---|---|---|
| 1 | Email + OTP | Hoàn thành theo source | `AuthController`, `AuthService` |
| 2 | Google Sign-In | Hoàn thành theo source | `AuthService.LoginWithGoogleAsync` |
| 3 | Onboarding thông tin sức khỏe | Hoàn thành theo source | Các bước onboarding Flutter và health profile |
| 4 | Chọn eating pattern `casual` | Hoàn thành theo source | `user_type_step.dart` |
| 5 | Tách profile mode khỏi entitlement | Hoàn thành | Frontend/backend kiểm tra subscription riêng |
| 6 | Policy `CasualOnly` | Hoàn thành | `casual_features` trong `Program.cs` và `EntitlementHandler` |
| 7 | Flutter kiểm tra subscription active | Hoàn thành | `hasCasualSubscriptionAccess` |
| 8 | Casual Hub và paywall | Hoàn thành | `CasualHubScreen` kiểm tra lại quyền trước khi mở feature |
| 9 | Casual card trên Home | Hoàn thành | Chỉ render khi `_hasCasualAccess` |
| 10 | Seed gói Casual | Không đạt | Trùng ID `...0005` với Gym/PT |
| 11 | Kích hoạt gói Casual 0đ | Hoàn thành một phần | Service hỗ trợ gói miễn phí; phụ thuộc seed plan đúng |
| 12 | Thanh toán Casual trả phí | Chưa kiểm chứng | Seed đang để `0đ`; chưa có E2E SePay Casual |
| 13 | Lucky Wheel tối đa 10 món | Hoàn thành theo source | Top 30, xáo trộn, `Take(10)` |
| 14 | Lọc dị ứng và chấm điểm cá nhân hóa | Hoàn thành theo source | Allergen, ngân sách, vùng, liked keywords |
| 15 | UI quay và hiển thị món | Hoàn thành theo source | `lucky_wheel_screen.dart` |
| 16 | Apply món vào DAILY plan | Hoàn thành theo source | Backend kiểm tra lại và dùng ngày UTC+7 |
| 17 | Daily Starter today | Bị chặn build | Controller/UI có, nhưng BLL không compile |
| 18 | Daily Starter featured meals | Bị chặn build | Có xếp hạng và tối đa ba món; lỗi nằm trong cùng service |
| 19 | Select meal | Bị chặn build | Có API và service nhưng chưa chạy được từ build hiện tại |
| 20 | Start-log một chạm | Bị chặn build | Có tạo MealLog theo khung giờ nhưng chưa chạy được từ build hiện tại |
| 21 | Daily Starter personalization | Bị chặn build | Endpoint/UI có nhưng assembly BLL không build |
| 22 | Mood selector và rescue foods | Hoàn thành một phần | Hoạt động local; chưa cá nhân hóa từ backend |
| 23 | Micro-Learning recommendations | Hoàn thành theo source | Phân tích ba ngày, profile và dị ứng; tối đa ba card |
| 24 | Đọc/lưu/dismiss card | Hoàn thành theo source | API action, saved list và UI |
| 25 | Quiz và điểm thưởng | Hoàn thành theo source | API submit và response feedback/points |
| 26 | Backend automated tests Casual | Chưa có | `MenuGreen.API.Tests` chỉ có `bin/obj` |
| 27 | Flutter entitlement/card tests | Hoàn thành một phần | Có test card và subscription access; thiếu test Lucky Wheel/Daily Starter/Micro-Learning E2E |

## 3. Blocker 1 — Backend không build

Lệnh đã chạy:

```text
dotnet build MenuGreen.sln --no-restore --verbosity minimal
```

Kết quả:

```text
Build FAILED.
1 Error(s)
3 Warning(s)
```

Lỗi chặn build:

```text
DailyStarterService.cs(124,56): CS1061
'Food' does not contain a definition for 'Name'
```

Đoạn code hiện tại:

```csharp
.GroupBy(
    x => (x.Food.NameVi ?? x.Food.Name ?? "").Trim(),
    StringComparer.OrdinalIgnoreCase)
```

Entity `Food` có `NameVi` và `NameEn`, không có `Name`. Hướng sửa phù hợp:

```csharp
x.Food.NameVi ?? x.Food.NameEn ?? ""
```

Ba warning còn lại:

- `AiAssistantService.cs:612`: gọi `ToLower()` trên `Role` có thể null.
- `MealPlanService.cs:58`: truyền `request.Items` nullable vào `ValidateItems`.
- `MealPlanService.cs:1973`: gán null cho `MealLogResponse` non-nullable.

Ảnh hưởng: `MenuGreen.DataAccessLayer` build được, nhưng `MenuGreen.BusinessLogicLayer` thất bại nên API không có build hoàn chỉnh từ source hiện tại.

## 4. Blocker 2 — Trùng ID Casual và Gym/PT

Các file sau cùng sử dụng UUID:

```text
10000000-0000-0000-0000-000000000005
```

- `database/06_subscription_plans.sql`: Gym/PT dùng `...0005`.
- `database/06_subscription_plans.sql`: Casual cũng insert `...0005`.
- `database/57_gymer_subscription_plan.sql`: Gym/PT dùng `...0005`.
- `database/58_casual_subscription_plan.sql`: Casual dùng `...0005`.

Hậu quả:

- Trong full seed, Gym/PT được insert trước; Casual dùng `ON CONFLICT DO NOTHING` nên không được tạo.
- Chạy script 58 sau đó sẽ `DO UPDATE` cùng ID và biến bản ghi Gym/PT thành Casual.
- Chạy lại script 57 có thể đổi bản ghi đó ngược lại thành Gym/PT.
- Entitlement, tên gói và role mapping trở nên phụ thuộc thứ tự chạy script.

Yêu cầu sửa:

1. Cấp UUID riêng cho Casual, ví dụ `...0006` nếu chưa được sử dụng.
2. Cập nhật full seed, patch script và mọi fixture/tham chiếu.
3. Viết migration dữ liệu an toàn cho database đã chạy script 57/58.
4. Kiểm tra lại user subscription đang trỏ tới `...0005` trước khi migrate.

## 5. Sai lệch UI/nghiệp vụ

### 5.1 Công cụ thứ ba không còn là Micro-Learning thuần

- `CasualPackageCard` ghi **Cảm xúc**.
- Casual Hub ghi **Góc Cảm Xúc & Thèm Ăn**.
- Màn hình đích vẫn là `MicroLearningScreen`.
- Phần mood/rescue foods được khai báo cục bộ trong Flutter.
- Phần card/category/quiz lấy từ Micro-Learning API.

Tài liệu workflow đã được cập nhật để mô tả đây là một màn hình kết hợp.

### 5.2 Nội dung mood chưa được backend cá nhân hóa

Các món rescue, insight, calo và macro đang là dữ liệu tĩnh trong `FoodMoodItem.defaultMoods()`. Chọn món chỉ mở meal log sheet; hệ thống chưa xác minh món tồn tại trong catalog hoặc phù hợp dị ứng.

### 5.3 Daily Starter tải tuần tự

`DailyStarterProvider.loadAll()` chờ `/today` xong mới gọi `/featured-meals`. Có thể chuyển sang tải song song để giảm thời gian chờ, nhưng đây không phải blocker.

## 6. Quyền truy cập

### Backend

- `LuckyWheelController`: `CasualOnly`.
- `DailyStarterController`: `Authorize` + `CasualOnly`.
- `MicroLearningController`: `CasualOnly`.
- Entitlement chấp nhận feature group `casual` hoặc `pro` còn hạn.

### Frontend

- `HomeView` lấy mọi subscription active và tính `_hasCasualAccess`.
- Casual card chỉ hiển thị khi có quyền.
- Casual Hub kiểm tra lại quyền trước khi điều hướng.
- Không có quyền thì chuyển tới `UpgradePlanScreen`.
- Fallback theo tên plan vẫn tồn tại để tương thích backend cũ.

## 7. Database và dữ liệu nội dung

- Micro-Learning runtime không tự tạo card khi catalog trống.
- Nội dung phải đến từ SQL seed hoặc Admin CRUD.
- Script 58 vừa patch plan Casual vừa upsert card Fiber; hai trách nhiệm này nên được tách trong lần chỉnh database tiếp theo.
- User subscription miễn phí vẫn có `StartDate`/`EndDate`; entitlement handler yêu cầu active và chưa hết hạn.

## 8. Kết quả kiểm tra gần nhất

| Kiểm tra | Kết quả |
|---|---|
| `dotnet build MenuGreen.sln --no-restore` | Thất bại: 1 error, 3 warnings |
| `flutter analyze --no-pub` | Thành công: `No issues found` |
| Toàn bộ `flutter test --no-pub` | Thành công: 20 tests passed |
| Backend Casual unit/integration tests | Không chạy được: không có test project source |
| Casual SePay E2E trên staging | Chưa có bằng chứng kiểm chứng |

Không tiếp tục ghi nhận “backend build và local integration chạy tốt” như báo cáo cũ vì điều đó trái với kết quả build hiện tại.

## 9. Kế hoạch khắc phục ưu tiên

### P0 — Chặn phát hành

1. Sửa `Food.Name` thành thuộc tính tồn tại và build lại solution.
2. Xử lý ba warning nullable để giữ build sạch.
3. Cấp ID riêng cho Casual và viết migration dữ liệu.
4. Xác minh `CasualOnly` bằng database sau migration.

### P1 — Xác minh luồng Casual

1. Thêm backend unit/integration test cho Lucky Wheel.
2. Thêm test cho Daily Starter today/featured/select/start-log/personalization.
3. Thêm test Micro-Learning recommendation/action/quiz.
4. Chạy E2E Flutter → API → PostgreSQL cho cả ba công cụ.
5. Kiểm tra kích hoạt gói Casual 0đ trên database mới và database migrate.

### P2 — Làm rõ sản phẩm

1. Chốt tên công cụ thứ ba: “Cảm xúc & Thèm ăn” hay “Góc dinh dưỡng”.
2. Chuyển mood/rescue foods sang catalog/backend nếu cần cá nhân hóa và lọc dị ứng.
3. Tải Daily Starter today/featured song song.
4. Tách seed plan Casual khỏi seed card Fiber.

## 10. Tiêu chí để chuyển sang trạng thái hoàn thành

- Backend build `0 error`; mục tiêu `0 warning`.
- Casual và Gym/PT có UUID riêng, không đổi nhau theo thứ tự script.
- Fresh database và migrated database đều có đúng plan.
- Ba Casual controller trả `403` cho user không có quyền và `200` cho Casual active trong test tích hợp.
- Lucky Wheel lọc dị ứng và apply đúng DAILY plan.
- Daily Starter chạy đủ today, featured, select, start-log và personalization.
- Mood rescue không đề xuất món vi phạm dị ứng nếu được coi là cá nhân hóa.
- Micro-Learning recommendation/action/quiz có automated test.
- Flutter analyzer và toàn bộ test tiếp tục pass.

## 11. Tệp đã đối chiếu

### Workflow và Flutter

- `docs/workflow/casual_workflow.md`
- `frontend/lib/features/casual/views/casual_hub_screen.dart`
- `frontend/lib/features/home/widgets/casual_package_card.dart`
- `frontend/lib/features/subscription/utils/subscription_access.dart`
- `frontend/lib/features/vietnam_local/providers/daily_starter_provider.dart`
- `frontend/lib/features/micro_learning/views/micro_learning_screen.dart`
- `frontend/lib/features/micro_learning/models/micro_learning_models.dart`

### Backend và database

- `backend/MenuGreen.API/Program.cs`
- `backend/MenuGreen.API/Authorization/EntitlementHandler.cs`
- `backend/MenuGreen.API/Controllers/LuckyWheelController.cs`
- `backend/MenuGreen.API/Controllers/DailyStarterController.cs`
- `backend/MenuGreen.API/Controllers/MicroLearningController.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/LuckyWheelService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/DailyStarterService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/MicroLearningService.cs`
- `backend/database/06_subscription_plans.sql`
- `backend/database/57_gymer_subscription_plan.sql`
- `backend/database/58_casual_subscription_plan.sql`
