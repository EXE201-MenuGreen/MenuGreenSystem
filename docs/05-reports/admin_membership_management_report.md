# Báo cáo triển khai quản lý gói thành viên bởi Admin

Ngày thực hiện: 15/08/2026

## Kết quả

Đã bổ sung luồng để Admin xem, cấp, gia hạn và thu hồi gói tính năng cho từng tài khoản. Role và gói thành viên được hiển thị, quản lý độc lập:

- `Role` tiếp tục lấy từ role hiện tại của tài khoản.
- `Gói thành viên` được tính từ các subscription còn hiệu lực.
- Cấp gói không tự đổi role của tài khoản.
- Tài khoản không có subscription hợp lệ tiếp tục dùng tier `free` và các `free_features` mặc định.

Không tạo migration, không đổi schema và không chỉnh sửa file trong `backend/database`.

## Backend

Đã tạo nhóm API chỉ cho role `Admin`:

| Method | Endpoint | Chức năng |
|---|---|---|
| `GET` | `/api/admin/users/{userId}/memberships` | Xem tier, entitlement và lịch sử subscription |
| `POST` | `/api/admin/users/{userId}/memberships` | Cấp một gói đang hoạt động |
| `POST` | `/api/admin/users/{userId}/memberships/{subscriptionId}/extend` | Gia hạn subscription |
| `POST` | `/api/admin/users/{userId}/memberships/{subscriptionId}/revoke` | Thu hồi subscription |

Các quy tắc đã áp dụng:

- Chỉ Admin đã xác thực mới gọi được API.
- Không cấp gói cho tài khoản đang khóa.
- Không cấp trực tiếp gói Free/Basic vì đây là quyền mặc định.
- Không tạo trùng cùng một gói khi subscription đang active hoặc chờ thanh toán.
- Thời hạn cấp/gia hạn nằm trong khoảng 1–3650 ngày.
- Subscription bị thu hồi chuyển sang `Cancelled`; payment SePay đang chờ liên quan được chuyển sang `CANCELLED`.
- Sau thay đổi, cache quyền subscription bị xóa và người dùng nhận notification.

## Audit

Mỗi thao tác quản trị tạo đồng thời:

- Một `SubscriptionTransaction` có loại `AdminGrant`, `AdminExtend` hoặc `AdminRevoke`, số tiền bằng 0.
- Một `ActivityLog` ghi Admin thực hiện, tài khoản đích, subscription, plan, thời hạn và ghi chú/lý do liên quan.

Nhờ đó việc cấp quyền thủ công không bị nhầm với giao dịch thanh toán của người dùng và có thể truy vết.

## Giao diện Admin

Trang quản lý người dùng đã được tách rõ:

- Cột `Role`: hiển thị role tài khoản.
- Cột `Gói thành viên`: hiển thị tier hiện tại và thời điểm hết hạn.
- Nút `Quản lý gói`: mở hộp thoại xem lịch sử, cấp gói mới, gia hạn hoặc thu hồi.
- Danh sách chọn chỉ hiển thị subscription plan đang hoạt động và loại bỏ Free/Basic.

API danh sách người dùng cũng trả thêm `membershipTier`, `membershipStatus`, `entitlements` và `membershipExpiresAt` để giao diện không dùng lẫn tier như role.

## Các file chính

- `backend/MenuGreen.API/Controllers/AdminMembershipController.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/AdminMembershipService.cs`
- `backend/MenuGreen.BusinessLogicLayer/Interfaces/IAdminMembershipService.cs`
- `backend/MenuGreen.BusinessLogicLayer/DTOs/Requests/AdminMembershipRequests.cs`
- `backend/MenuGreen.BusinessLogicLayer/DTOs/Responses/AdminMembershipResponses.cs`
- `backend/MenuGreen.BusinessLogicLayer/DTOs/Responses/UserAdminResponse.cs`
- `backend/MenuGreen.BusinessLogicLayer/Services/UserService.cs`
- `frontend-web/features/users/components/manage-membership-dialog.tsx`
- `frontend-web/features/users/components/user-management.tsx`
- `frontend-web/features/users/api/admin-user-api.ts`

## Kiểm tra

- `dotnet build MenuGreen.sln --no-restore --verbosity minimal`: thành công, 0 error. Có 5 warning đã tồn tại tại các module khác.
- `pnpm exec tsc --noEmit`: thành công.
- ESLint trên toàn bộ file frontend đã thay đổi: thành công.
- `pnpm build`: production build thành công, trang `/dashboard/users` được sinh thành công.
- `git diff -- backend/database`: không có thay đổi.

## Lưu ý vận hành

Luồng mua Office hiện hữu của hệ thống vẫn có thể thay đổi role sang Office; phần triển khai này không sửa hành vi thanh toán cũ. Riêng thao tác cấp gói bằng Admin chỉ tạo entitlement qua subscription và không thay đổi role. Đây là ranh giới cần giữ khi tiếp tục chuẩn hóa toàn bộ role trong một đợt refactor riêng.
