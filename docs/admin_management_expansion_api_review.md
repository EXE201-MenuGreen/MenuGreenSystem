# Rà Soát Kế Hoạch Mở Rộng Admin Theo MenuGreen.API

> **Ngày rà soát:** 27/07/2026  
> **Tài liệu gốc:** `docs/admin_management_expansion_plan.md`  
> **Phạm vi đối chiếu:** `backend/MenuGreen.API`, `backend/MenuGreen.BusinessLogicLayer`, `backend/MenuGreen.DataAccessLayer`  
> **Trạng thái:** Báo cáo rà soát, chưa triển khai thay đổi source code

## 1. Kết luận

Hướng mở rộng trong kế hoạch gốc là phù hợp, nhưng không nên triển khai nguyên trạng. Backend đã có một phần nền tảng liên quan đến Admin, bảo mật, thanh toán, analytics và background jobs. Cần tận dụng các thành phần hiện hữu, sửa các lỗi bảo mật/tính đúng đắn trước, sau đó mới mở rộng thành bảy phân hệ Admin hoàn chỉnh.

Các vấn đề cần ưu tiên cao nhất:

1. Người dùng có thể tự đăng ký và được nâng thẳng lên role `Coach`.
2. Admin chưa bị chặn tự khóa hoặc tự hạ quyền của chính mình.
3. API gán role có thể tự tạo một role mới từ chuỗi do client gửi.
4. Force logout chưa thể vô hiệu hóa access token đã cấp.
5. Background reconciliation SePay sử dụng trạng thái không khớp với state và constraint của payment.
6. ActivityLog có endpoint phân trang nhưng vẫn tải toàn bộ dữ liệu vào memory.

## 2. Hiện trạng backend đã có

| Hạng mục | Hiện trạng | Thành phần |
|---|---|---|
| Global exception handler | Đã có, trả response JSON ổn định và ghi log server | `MenuGreen.API/Middleware/GlobalExceptionHandler.cs` |
| Rate limiting | Đã có Global, AI, Auth và OTP policy | `MenuGreen.API/Program.cs` |
| Health check | Đã có `/health`, `/health/ready`, `/health/live`, PostgreSQL và Redis | `MenuGreen.API/Program.cs` |
| Activity log | Có entity, API Admin, lọc và endpoint phân trang | `ActivityLog`, `AnalyticsController`, `AnalyticsService` |
| Session và refresh token | Có tạo session, refresh token rotation, logout và xóa session khi reset password | `Session`, `AuthService` |
| SePay | Có tạo QR, webhook, pending order, chống webhook trùng và background reconciliation | `SepayController`, `SepayPaymentService`, `SepayReconciliationBackgroundService` |
| Food/Recipe soft-disable | API delete hiện chuyển `IsActive = false` | `FoodService`, `RecipeService` |
| Dashboard Admin | Có thống kê user, doanh thu và món ăn phổ biến | `DashboardController` |
| Analytics Admin | Có activity log, funnel, cohort, churn, export và nutrition analytics | `AnalyticsController` |
| Background jobs | Có nhiều hosted service và endpoint trigger thủ công | `JobTriggerController` |
| Subscription Plan Admin | Có CRUD, cập nhật trạng thái, giá và duration | `SubscriptionPlanController` |
| Micro-learning Admin | Có CRUD bài học | `AdminMicroLearningController` |
| AI Admin | Có health, overview, crawler, training sample và curation | `AiAdminController` |

Các phần trên không nên được tạo lại từ đầu. Cần mở rộng hoặc sửa để phù hợp với mô hình Admin mới.

## 3. Các vấn đề P0 cần xử lý trước

### 3.1. Người dùng có thể tự nâng quyền Coach

`CoachService.RegisterCoachAsync()` hiện thực hiện trực tiếp:

- Tìm hoặc tạo role `Coach`.
- Gán `RoleId` của người đăng ký sang role `Coach`.
- Tạo hoặc cập nhật `CoachProfile`.
- Đặt `CoachProfile.IsActive = true`.

Điều này bỏ qua hoàn toàn bước Admin xác minh hồ sơ và chứng chỉ.

Luồng cần thay đổi:

```text
User gửi đăng ký Coach
    -> CoachApplication = Pending
    -> Admin kiểm tra hồ sơ/chứng chỉ
    -> Approve
    -> Gán role Coach và kích hoạt CoachProfile
```

Khi bị từ chối, hồ sơ phải lưu trạng thái `Rejected`, lý do từ chối, Admin xử lý và thời gian xử lý. Không được cấp role `Coach`.

### 3.2. Thiếu self-action guard và kiểm soát role

`UserController` và `UserService` chưa truyền `currentAdminId` vào các thao tác:

- Khóa/mở khóa tài khoản.
- Toggle trạng thái.
- Thay đổi role.

Vì vậy Admin có thể tự khóa hoặc tự hạ role của mình.

`AssignRoleAsync()` còn tự tạo một role mới nếu tên role do client gửi chưa tồn tại. Đây là rủi ro làm sai dữ liệu RBAC.

Cần thực hiện:

- Chặn `targetUserId == currentAdminId` với thao tác khóa hoặc hạ quyền.
- Không tạo role động từ request gán quyền.
- Chỉ chấp nhận role từ allowlist đã seed trong database.
- Thêm policy `SuperAdminOnly` nếu cần quản lý tài khoản Admin khác.
- Ghi audit log cho mọi thay đổi role và trạng thái tài khoản.

### 3.3. Force logout chưa vô hiệu hóa access token

`Session` hiện quản lý refresh token. JWT access token:

- Có thời hạn mặc định 120 phút.
- Không chứa `SessionId`.
- Không chứa `TokenVersion`.
- Không kiểm tra session/user trong `JwtBearerEvents.OnTokenValidated`.

Do đó, việc xóa session chỉ ngăn refresh token. Access token cũ vẫn có thể gọi API cho tới khi hết hạn.

Cần bổ sung một trong hai cơ chế:

1. Gắn `SessionId` vào JWT và kiểm tra session còn hiệu lực trong `OnTokenValidated`.
2. Gắn `TokenVersion` vào User/JWT và tăng version khi force logout, khóa tài khoản hoặc đổi mật khẩu.

Refresh token nên lưu dạng hash thay vì plaintext. Session cần lưu và trả về thông tin thiết bị, IP, user agent, ngày tạo, ngày hết hạn và trạng thái thu hồi.

### 3.4. SePay reconciliation đang dùng sai payment state

`SepayPaymentService` sử dụng state:

```text
PENDING
PAID
FAILED
EXPIRED
REFUNDED
```

Database cũng giới hạn bằng `CK_payments_status` với các giá trị trên.

Tuy nhiên `SepayReconciliationBackgroundService` hiện:

- Tìm payment bằng `p.Status == "Pending"`.
- Chuyển payment thành `payment.Status = "Success"`.

Hậu quả:

- Không tìm thấy các payment thực tế đang có trạng thái `PENDING`.
- Giá trị `Success` vi phạm check constraint của bảng `payments`.
- Luồng webhook và reconciliation có hai cách kích hoạt subscription khác nhau.

Cần tạo một payment state machine và một service dùng chung:

```text
PaymentMatch
    -> kiểm tra idempotency
    -> xác minh số tiền/mã giao dịch
    -> PENDING -> PAID
    -> kích hoạt subscription/program
    -> ghi transaction
    -> invalidate cache
    -> gửi notification
```

Webhook và manual/background reconciliation phải gọi cùng service này.

### 3.5. ActivityLog phân trang trong memory

`AnalyticsService.GetActivityLogsPaginatedAsync()` hiện:

1. Lấy toàn bộ `ActivityLogs` từ database.
2. Chuyển thành `IEnumerable`.
3. Lọc, `Count`, `Skip`, `Take` trong memory.

Điều này không đáp ứng mục tiêu chống OOM khi dữ liệu đạt 100.000 bản ghi.

Cần chuyển sang query EF Core tại database:

- Dùng `IQueryable<ActivityLog>`.
- Áp dụng điều kiện lọc trước.
- Dùng `CountAsync()`.
- Dùng `OrderByDescending().Skip().Take().AsNoTracking().ToListAsync()`.
- Chuẩn hóa `page >= 1`.
- Giới hạn `pageSize` trong khoảng `1..100`.
- Bổ sung index theo `CreatedAt`, `UserId`, `Action`.

## 4. Điều chỉnh kiến trúc trong kế hoạch gốc

### 4.1. Không dùng ActivityLog thay thế hoàn toàn AdminAuditLog

`ActivityLog` hiện là analytics event và client có thể gửi event lên API. Dữ liệu này không đủ độ tin cậy để làm audit bảo mật.

`AdminAuditLog` nên là dữ liệu chỉ do server ghi, gồm:

- Actor/Admin ID.
- Action.
- Entity type và entity ID.
- Old/New values đã lọc dữ liệu nhạy cảm.
- IP, user agent, correlation ID.
- Kết quả thành công/thất bại.
- Thời điểm thực hiện.

Không lưu password, token, OTP, API key, raw payment payload hoặc dữ liệu cá nhân nhạy cảm vào audit JSON.

Với hành động quan trọng, audit log phải được ghi cùng database transaction với thay đổi nghiệp vụ.

### 4.2. Không cấp mật khẩu tạm trực tiếp cho Admin

Endpoint `reset-password-admin` không nên tạo rồi trả mật khẩu tạm.

Luồng an toàn hơn:

```text
Admin yêu cầu reset
    -> thu hồi session
    -> tạo one-time reset token
    -> gửi link/OTP tới email đã xác minh
    -> user bắt buộc đặt mật khẩu mới
```

### 4.3. Concurrency token phải phù hợp PostgreSQL

Thiết kế `byte[] RowVersion` phù hợp với SQL Server hơn PostgreSQL.

Nên dùng:

- PostgreSQL `xmin` làm concurrency token; hoặc
- Cột `long Version` tăng sau mỗi lần cập nhật.

Khi xảy ra `DbUpdateConcurrencyException`, API trả `409 Conflict`.

### 4.4. Maintenance mode dùng HTTP 503

Không nên dùng HTTP `539`. Response bảo trì nên là:

```text
503 Service Unavailable
Retry-After: <seconds>
```

Admin API, health check và SePay webhook cần được cân nhắc whitelist riêng để hệ thống vẫn vận hành an toàn.

### 4.5. Background job phải có trạng thái bền vững

`Channel<T>` chỉ nằm trong memory và sẽ mất job khi backend restart.

Bulk import, mass notification và reconciliation nên có bảng job:

- `JobId`.
- `Type`.
- `Status`.
- `Progress`.
- `PayloadLocation`.
- `Error`.
- `CreatedAt`, `StartedAt`, `CompletedAt`.

Hosted service có thể dùng `Channel<T>` để xử lý nhanh, nhưng database phải là nguồn trạng thái chính.

### 4.6. Retry phải xét tính idempotent

Không áp dụng retry ba lần một cách mặc định cho mọi thao tác tài chính.

- Có thể retry GET hoặc thao tác đã có idempotency key.
- Không tự retry mutation thanh toán nếu chưa có cơ chế chống xử lý trùng.
- Circuit breaker phù hợp cho CV, FCM, Gemini và API đọc SePay.

### 4.7. Global exception middleware không bảo vệ toàn bộ process

Middleware hiện tại chỉ bắt exception trong HTTP request pipeline. Nó không bắt:

- Lỗi startup.
- Lỗi EF migration trước khi app khởi động.
- Lỗi background service thoát ra ngoài `ExecuteAsync`.
- Out-of-memory hoặc lỗi process-level.

Kế hoạch nên mô tả đúng phạm vi và bổ sung exception handling cho từng hosted service.

## 5. Phạm vi cần bổ sung theo từng phân hệ

### 5.1. Audit và Security

Cần bổ sung:

- `AdminAuditLog` và migration.
- `IAdminAuditWriter`.
- API tra cứu audit có phân trang tại database.
- Login attempt/suspicious activity tracking.
- Redaction dữ liệu nhạy cảm.
- Retention policy cho audit.

Không cần tạo lại GlobalExceptionHandler hoặc rate limiter; chỉ cần mở rộng.

### 5.2. Coach Management

Cần bổ sung:

- `CoachApplication`.
- Trạng thái `Pending`, `Approved`, `Rejected`, `Suspended`.
- Người duyệt, thời gian duyệt và lý do.
- Verification document metadata.
- Admin approve/reject/suspend.
- Commission rate nếu nghiệp vụ thực sự có thanh toán Coach.
- Hệ thống report review trước khi xây moderation review.

`CoachProfile.CertificateUrl` đã tồn tại nhưng chưa đủ làm luồng xác minh.

### 5.3. User và Session Management

Cần bổ sung:

- Search/filter/phân trang tại database.
- Lock reason và lock expiry.
- Self-action guard.
- Role allowlist.
- Force logout thực sự.
- Active session list.
- Token/session revocation.
- Password reset bằng one-time token.

### 5.4. Financial và SePay

Cần bổ sung:

- Sửa state inconsistency trước.
- API danh sách payment toàn hệ thống.
- Manual reconciliation dùng chung payment processor.
- Manual subscription adjustment kèm audit.
- Refund workflow.
- Concurrency protection.
- Revenue report tái sử dụng `DashboardController` thay vì tạo lại toàn bộ.

SePay webhook hiện đã có chống duplicate thông qua transaction code unique và xử lý unique constraint. Phần này nên được giữ và mở rộng.

### 5.5. AI Quota và Safety

Đã có `AiPolicy` giới hạn 5 request/phút cho một số controller, nhưng chưa có:

- Quota theo ngày/gói.
- Theo dõi usage.
- Quota cấu hình động.
- Blacklisted keyword.
- AI provider error log.

Quota nên dựa trên entitlement/subscription hiện tại thay vì chỉ role, vì một user có thể có nhiều gói dịch vụ đồng thời.

### 5.6. Master Catalog Moderation

Food/Recipe đã soft-disable bằng `IsActive`, nhưng chưa có:

- `IsVerified`.
- Nguồn tạo dữ liệu.
- Người duyệt và thời gian duyệt.
- Duplicate detection.
- Merge transaction.
- Bulk import job.

Micro-learning hiện vẫn xóa vật lý và cần chuyển sang soft delete nếu áp dụng nguyên tắc bảo toàn dữ liệu master.

### 5.7. System Operations

Đã có health check PostgreSQL/Redis và metrics. Cần bổ sung:

- Maintenance configuration.
- Middleware bảo trì.
- Health check CV Service.
- Health check FCM.
- Health check SePay.
- Job status API.

## 6. Roadmap triển khai được đề xuất

### Giai đoạn P0 — Security và Correctness

1. Chặn tự cấp role Coach.
2. Thêm self-lock/self-demotion guard.
3. Loại bỏ việc tự tạo role từ request.
4. Thiết kế session revocation/token version.
5. Sửa payment state machine và SePay reconciliation.
6. Sửa ActivityLog pagination chạy tại database.

### Giai đoạn P1 — Audit Foundation

1. Tạo `AdminAuditLog`.
2. Tạo audit writer và redaction.
3. Gắn audit vào user, role, plan, coach và payment mutations.
4. Xây API tìm kiếm audit có page-size limit.
5. Bổ sung audit integration tests.

### Giai đoạn P1 — Admin User và Coach

1. User search/filter.
2. Lock reason/expiry.
3. Active sessions và force logout.
4. Coach application pending.
5. Approve/reject/suspend Coach.
6. Notification kết quả duyệt.

### Giai đoạn P2 — Financial Management

1. Payment query/revenue drill-down.
2. Manual reconciliation.
3. Subscription adjustment.
4. Refund workflow.
5. Idempotency và concurrency tests.

### Giai đoạn P2 — Catalog Moderation

1. Verification metadata.
2. Food/Recipe pending list.
3. Verify/reject.
4. Merge món ăn trong transaction.
5. Durable bulk import job.
6. Chuyển MicroLearning sang soft delete.

### Giai đoạn P3 — AI và System Operations

1. AI usage tracking.
2. Quota theo entitlement.
3. Keyword moderation và provider error log.
4. Maintenance mode.
5. External dependency health checks.
6. Resilience policy theo từng external service.

## 7. Tiêu chí hoàn thành

- User/Coach/Gymer không thể gọi API `/api/admin/*`.
- User không thể tự nhận role Coach.
- Admin không thể tự khóa hoặc tự hạ quyền.
- Force logout làm access token cũ mất hiệu lực.
- Tất cả Admin list API có phân trang tại database và `pageSize <= 100`.
- Payment state chỉ dùng giá trị chuẩn trong database constraint.
- Webhook/manual/background reconciliation không thể kích hoạt gói hai lần.
- Mọi Admin mutation quan trọng có audit log.
- Audit log không chứa secret hoặc dữ liệu nhạy cảm.
- Bulk job không mất trạng thái khi backend restart.
- Maintenance mode trả HTTP `503` và không chặn health/Admin cần thiết.
- Có unit test, integration test, concurrency test và authorization test cho từng phân hệ.

## 8. Các file hiện tại liên quan trực tiếp

- `backend/MenuGreen.API/Program.cs`
- `backend/MenuGreen.API/Middleware/GlobalExceptionHandler.cs`
- `backend/MenuGreen.API/Controllers/UserController.cs`
- `backend/MenuGreen.API/Controllers/CoachesController.cs`
- `backend/MenuGreen.API/Controllers/SepayController.cs`
- `backend/MenuGreen.API/Controllers/AnalyticsController.cs`
- `backend/MenuGreen.API/Controllers/DashboardController.cs`
- `backend/MenuGreen.API/Controllers/JobTriggerController.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/UserService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/CoachService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/AuthService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/SepayPaymentService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/AnalyticsService.cs`
- `backend/MenuGreen.BusinessLogicLayer/BackgroundJobs/SepayReconciliationBackgroundService.cs`
- `backend/MenuGreen.DataAccessLayer/Entities/Session.cs`
- `backend/MenuGreen.DataAccessLayer/Entities/Payment.cs`
- `backend/MenuGreen.DataAccessLayer/Entities/SepayTransaction.cs`
- `backend/MenuGreen.DataAccessLayer/Entities/ActivityLog.cs`
- `backend/MenuGreen.DataAccessLayer/Entities/CoachProfile.cs`

