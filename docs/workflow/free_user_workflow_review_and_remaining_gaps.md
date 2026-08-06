# Review Free User Workflow, gói Cơ bản và các khoảng hở còn lại

> Ngày review: 22/07/2026  
> Nhánh: `free-user-workflow`  
> Mốc trước triển khai: `ae8842e` (`develop`)  
> Mốc workflow đã triển khai: `6b52353`  
> Phạm vi: backend .NET và các điểm Flutter gọi backend

## 1. Kết luận ngắn

Gói **Cơ bản/Free là quyền mặc định của mọi tài khoản User**. Người dùng không cần nhấn đăng ký, không cần có một subscription giả kéo dài 100 năm và không được thấy các nội dung như:

```text
Còn 36500 ngày
Hết hạn: 28/06/2126
```

Trạng thái đúng trên UI là:

```text
Gói đang dùng: Cơ bản
Trạng thái: Active • Không giới hạn
```

Workflow hiện dùng `free_features` làm quyền account-level. Vì vậy thay đổi gói Cơ bản trong lần này **không cần migration**: tài khoản không có subscription vẫn sử dụng đầy đủ Free. Các record Basic 100 năm đã tồn tại chỉ được xem là dữ liệu legacy và không còn lộ ngày hết hạn giả trên UI.

## 2. Snapshot review read-only trước khi triển khai

Tại commit `ae8842e`, lần review đầu tiên không sửa code và ghi nhận:

- backend có 48 controller, 425 route, 58 service và 57 entity;
- rebuild thành công với 0 error, 5 warning;
- chưa có project test .NET nên `dotnet test` không chạy test backend thực tế;
- nhánh `free-user-workflow` lúc đó cùng commit với `develop`;
- đăng ký mới gán role `User`, không phải `Free`;
- seed role không có `Free`, trong khi một số luồng subscription cũ tìm hoặc gán role này;
- `UserOnly` mở rộng cho nhiều persona, còn nhiều API chuyên biệt chưa có premium gate;
- `CasualOnly` từng dựa vào role và cho phép `User` nhưng loại `Free`;
- `OfficeOnly` được khai báo nhưng chưa được dùng và chưa có policy `office_features` hoàn chỉnh;
- hủy/hết hạn một subscription từng hạ role về `Free` mà không xét các subscription active khác;
- role nằm trong JWT nên quyền sản phẩm có thể bị stale đến lần refresh token/đăng nhập tiếp theo;
- persona `gym/general/office` ở Flutter và `gymer/casual/office` trong payment không thống nhất;
- onboarding chưa atomic: Flutter lưu lần lượt profile, health, AI profile, allergy rồi mới complete;
- controller bắt `Exception` và trả `ex.Message` quá nhiều, làm status code thiếu nhất quán;
- một số repository/service tải tập dữ liệu lớn vào RAM;
- ba hệ AI `AiAssistant`, `AiCoach`, `NutritionAssistant` chưa có API canonical duy nhất.

Kết luận tại thời điểm đó là persona, role, subscription và entitlement đang bị trộn lẫn; nếu chỉ thêm UI Free sẽ có nguy cơ Free gọi được API trả phí hoặc mất nhầm tính năng cơ bản.

## 3. Những điểm workflow mới đã xử lý

| Vấn đề cũ | Trạng thái hiện tại |
| --- | --- |
| Không có nguồn quyền duy nhất | Đã có `GET /api/UserSubscription/me/entitlements` và `IFeatureAccessService`. |
| Free phụ thuộc subscription/role | Đã xử lý: user hợp lệ luôn có `free_features`. |
| Role bị đổi khi mua, hủy hoặc hết hạn gói | Đã gỡ khỏi subscribe, SePay, cancel và expiration job. |
| Casual/Office/Gym dựa vào persona hoặc role | Đã chuyển các luồng chính sang `casual_features`, `office_features`, `gym_features`. |
| Nhiều subscription active làm mất quyền nhau | Resolver hiện hợp nhất entitlement của mọi subscription active. |
| JWT stale làm sai quyền sản phẩm | Đã giảm rủi ro vì entitlement được đọc từ database theo request thay vì role trong token. |
| Không có backend test | Đã có project unit test và integration test. |
| Home Free trộn shortcut trả phí | Đã tách grid Free, panel trả phí và card upsell. |
| Entitlement API lỗi | Flutter fallback an toàn về `FeatureAccess.free`. |

Các điểm onboarding, exception mapping, truy vấn tải nhiều dữ liệu và việc hợp nhất ba hệ AI chưa được xử lý trong workflow này.

## 4. Nguyên nhân lỗi 36.500 ngày của gói Cơ bản

Seed của gói Cơ bản có `DurationDays = NULL` và `FeatureGroup = basic` tại `backend/database/06_subscription_plans.sql`.

Do `UserSubscription.EndDate` hiện không nullable, backend cũ quy đổi gói không thời hạn thành `36500` ngày tại `UserSubscriptionService.ResolveDurationDays`. Flutter sau đó luôn gọi `formatSubscriptionRemaining(endDate)` và luôn in `Hết hạn`, nên ngày 28/06/2026 bị biến thành 28/06/2126.

Ngoài ra, Free đã là account-level entitlement nhưng màn gói vẫn từng hiển thị gói Basic như một sản phẩm cần `Đăng ký miễn phí`, dẫn đến hai mô hình mâu thuẫn:

```text
Mô hình quyền: User đăng nhập => có Free ngay
Mô hình UI cũ: User phải tạo Basic subscription => Free
```

Mô hình đầu tiên là mô hình chuẩn được giữ lại.

## 5. Thay đổi gói Cơ bản trong working tree

### Backend

- Chặn tạo subscription Basic mới vì Basic đã bật mặc định.
- Chặn renew Basic vì quyền này không hết hạn.
- Giữ `free_features` cho user không có bất kỳ subscription nào.
- Giữ tương thích với record Basic 100 năm cũ nhưng resolver không coi đó là quyền trả phí và không trả `expiresAt` trả phí.

Điểm chính: `backend/MenuGreen.BusinessLogicLayer/Services/UserSubscriptionService.cs` tại `IsBaselineFreePlan` và hai guard ở `SubscribeAsync`/`RenewAsync`.

### Flutter

- Tài khoản chưa có subscription vẫn thấy card `Cơ bản` đang hoạt động.
- Basic legacy có `EndDate = 2126` vẫn hiển thị `Không giới hạn`.
- Không còn nút `Đăng ký miễn phí`, `Gia hạn gói hiện tại` hoặc `Hủy gói` cho Basic.
- Gói Basic được loại khỏi danh sách gói nâng cấp.
- Hồ sơ mặc định hiển thị `Cơ bản`, không hiển thị role `User` như tên gói.
- Hồ sơ ghi rõ `Quyền Free luôn hoạt động • Không giới hạn`.

Các điểm chính:

- `frontend/lib/features/subscription/models/subscription_models.dart`: nhận diện `isBaselineFree`;
- `frontend/lib/features/subscription/views/upgrade_plan_screen.dart`: card Basic mặc định và không có expiry;
- `frontend/lib/features/profile/views/profile_view.dart`: trạng thái Free mặc định.

## 6. Khoảng hở còn lại sau Free Workflow

### P0 — Có thể activate Premium Program khi chưa thanh toán

`PremiumProgramService.ActivateProgramAsync` hiện chấp nhận cả `Paid` và `PendingPayment`:

```csharp
if (userProgram.Status != "Paid" && userProgram.Status != "PendingPayment")
```

Một User có thể gọi checkout để tạo enrollment `PendingPayment`, sau đó gọi activate trước khi SePay xác nhận. Đây là bypass thanh toán thực sự và cần sửa trước release. Activation chỉ nên chấp nhận `Paid`; webhook/reconciliation phải là luồng duy nhất chuyển trạng thái thanh toán.

Tham chiếu: `backend/MenuGreen.BusinessLogicLayer/Services/PremiumProgramService.cs`, khoảng dòng 175–193.

### P1 — Office và Gym/PT đang có giá 0đ và có thể tự kích hoạt

Seed hiện đặt Office và Gym/PT là `PriceVnd = 0`. `UserSubscriptionService.SubscribeAsync` cho phép mọi gói 0đ active ngay, trong khi UI cũng ghi `Kích hoạt miễn phí`/`Mở tính năng Office`.

Policy entitlement bảo vệ API đúng về kỹ thuật, nhưng business boundary “gói trả phí” chưa đúng nếu Office/Gym thực sự phải bán. Cần chốt một trong hai:

- đây là trial miễn phí có thời hạn và phải lưu rõ loại trial;
- hoặc đây là gói trả phí và phải đi qua SePay;
- hoặc chỉ admin/test account được kích hoạt miễn phí.

### P1 — Màn quản lý gói vẫn chỉ dựa vào một `_current`

Backend cho phép và resolver hợp nhất nhiều subscription active, nhưng `UpgradePlanScreen` vẫn gọi `/me` và giữ một `_current` mới nhất. Hệ quả:

- đang có Gym nhưng Office tạo sau có thể làm UI nghĩ Gym chưa active;
- đang có Office nhưng subscription khác mới hơn có thể làm UI đăng ký Office lần nữa;
- một gói active khác bị hiển thị như chưa mua;
- card `expiresAt` chung không mô tả được ngày hết hạn riêng của từng feature group.

Nên dùng `/me/active` hoặc response entitlement có thêm trạng thái theo từng package, đồng thời đặt unique/idempotency rule cho `(UserId, SubscriptionPlanId, Active)`.

### P1 — Generic Meal Plan API có thể vòng qua gate Office/Gym

Các endpoint chuyên biệt như generate-by-budget, grocery-list và scan-meals đã có `OfficeFeatures`. Tuy nhiên generic endpoints `PUT plan`, `POST/PUT item`, `duplicate`, `distribute`, `alternatives` và substitute ingredient vẫn chỉ cần `UserOnly`.

Nếu user biết ID của kế hoạch Office/Gym cũ, họ có thể tiếp tục sửa qua generic route sau khi entitlement hết hạn. Service cần kiểm tra `GeneratedBy`/loại plan khi mutation, không chỉ gate theo tên endpoint.

### P1 — Một số feature trả phí vẫn chỉ có `UserOnly`

Các nhóm sau cần chốt lại ma trận entitlement:

- `EngagementController`: habit score, streak và notification engagement mang tính game hóa, phù hợp Casual;
- `GoalsController`: drift analysis, recalculate và create nudge là tự động hóa sâu;
- `PlannedVsActualController`: GET cơ bản có thể Free, nhưng drift analysis, recommendations, monthly report và recalibrate cần gate riêng;
- `PremiumProgramsController`: milestone, check-in, progress, graduate và wrap-up thuộc chương trình dài hạn/Gym;
- `UserDashboard/recommendation-summary`: có dấu hiệu là gợi ý cá nhân hóa;
- `MealPlan/streaks`, `adherence-scores`, `alternatives`: cần phân biệt phần Free cơ bản và phần tự động/game hóa.

### P1 — `grant-access` cho Coach chưa yêu cầu `coach_access`

Tạo kết nối Coach đã gate bằng `CoachAccessOnly`, nhưng `POST /api/Coaches/grant-access/{coachId}` vẫn chỉ dùng `UserOnly`. Sau khi Gym hết hạn, user nên được xem, revoke hoặc disconnect dữ liệu cũ, nhưng không nên cấp mới quyền dữ liệu cho Coach nếu không còn `coach_access`.

### P2 — Entitlement resolver còn phụ thuộc chuỗi tự do

Resolver dùng `FeatureGroup` và fallback bằng `PlanName.Contains(...)`. Một plan trả phí có group sai/chưa biết sẽ chỉ nhận Free; ngược lại tên chứa từ khóa có thể cấp nhầm quyền.

Nên dùng enum/catalog entitlement được validate khi admin tạo plan. Không nên suy luận quyền từ tên hiển thị.

### P2 — `FeatureAccessService` có N+1 query và chưa cache

Mỗi lần authorization có thể:

1. tải toàn bộ subscription của user;
2. gọi `GetByIdAsync` từng plan;
3. lặp lại ở request kế tiếp.

Khi traffic tăng, nên query join/projection một lần và cache ngắn theo user. Cache phải được invalidate sau subscribe, payment, cancel hoặc expiration.

### P2 — Safe fallback Free chưa có observability

Flutter bắt mọi exception của entitlement và âm thầm trả Free. Đây là fail-closed đúng về bảo mật, nhưng paid user có thể đột ngột mất UI trả phí mà không có log/telemetry hoặc thông báo thử lại.

Nên log lỗi có correlation ID và cho phép retry, vẫn tuyệt đối không tự mở paid feature.

### P2 — Test mới chưa phủ hết ma trận yêu cầu

Test hiện có kiểm tra resolver, `401`, Free entitlement `200`, Lucky Wheel `403`, fallback Flutter và grid Free. Chưa có integration test database thật cho:

- Free tạo meal log, kế hoạch thủ công và cân nặng thành công;
- Free bị `403` với Office, Gym, Coach và AI;
- subscription hết hạn nhưng dữ liệu Free vẫn còn;
- nhiều subscription active không tạo duplicate hoặc mất quyền;
- mutation generic không vòng qua gate của kế hoạch chuyên biệt;
- SePay/Premium Program không activate trước thanh toán.

## 7. Migration và dữ liệu legacy

### Phương án hiện tại — không cần migration

Free là entitlement mặc định. Basic không tạo subscription mới. Flutter nhận diện Basic legacy và ẩn ngày 2126. Đây là phương án đã áp dụng.

### Phương án mô hình dữ liệu chuẩn hơn — cần migration sau

Nếu muốn loại bỏ hoàn toàn mốc 100 năm khỏi database:

1. cho phép `UserSubscription.EndDate` nullable;
2. cập nhật mọi query active/expiration để hiểu `NULL = không giới hạn`;
3. chuyển các Basic record hiện có từ năm 2126 thành `EndDate = NULL`, hoặc archive chúng vì Free không cần subscription;
4. thêm migration và test boundary;
5. không áp dụng quy tắc lifetime này cho plan trả phí không cấu hình duration.

Migration này là cải tiến dữ liệu, không phải điều kiện để workflow Free hiện tại hoạt động đúng.

## 8. Thứ tự xử lý đề xuất

1. Khóa bypass `PendingPayment -> Active` của Premium Program.
2. Chốt Office/Gym là trial hay paid và sửa giá/activation flow tương ứng.
3. Chuyển màn quản lý gói sang danh sách package active thay vì một `_current`.
4. Gate mutation theo loại tài nguyên Meal Plan, không chỉ theo route.
5. Hoàn tất policy cho gamification, deep analytics, Premium Program và Coach grant.
6. Tối ưu entitlement query/cache và bổ sung observability.
7. Mở rộng integration test với database test độc lập.

## 9. Tiêu chí nghiệm thu riêng cho Basic/Free

- User mới đăng nhập có `free_features` ngay cả khi không có row trong `user_subscriptions`.
- Màn Gói dịch vụ luôn hiển thị `Cơ bản — Active — Không giới hạn` cho user không có gói chuyên biệt.
- Không có `Còn 36500 ngày`, năm `2126`, nút đăng ký, gia hạn hoặc hủy Basic.
- API subscribe/renew Basic không tạo thêm record.
- Legacy Basic 100 năm không làm phát sinh paid entitlement.
- Office/Gym/Casual hết hạn không làm mất dữ liệu hoặc quyền Free.

## 10. Kết quả xác minh sau thay đổi

```text
dotnet test MenuGreen.sln --no-restore: 9/9 pass
flutter analyze: No issues found
flutter test: 36/36 pass
```

Test mới phủ hai trường hợp UI quan trọng:

- user mới không có subscription vẫn thấy Basic active và không giới hạn;
- record Basic legacy có `36500` ngày/năm `2126` không còn lộ thời hạn giả.
