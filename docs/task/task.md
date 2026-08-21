# Task list — Chức năng Phân Trang cho MenuGreen Admin (Foods & Users)

**Trạng thái:** Hoàn tất (Completed - Sẵn sàng nghiệm thu)

## Developer
- [x] [NEW] Tạo component phân trang dùng chung `frontend-web/components/ui/pagination.tsx`.
- [x] [FOODS] Cập nhật types trong `features/foods/types.ts` (`FoodSearchParams`, `FoodSearchResult`).
- [x] [FOODS] Cập nhật API client trong `features/foods/api/food-api.ts` để gửi tham số `page`, `pageSize`.
- [x] [FOODS] Nâng cấp hook `features/foods/hooks/use-foods.ts` quản lý state `page`, `pageSize`, `totalPages`.
- [x] [FOODS] Tích hợp component `<Pagination />` vào `features/foods/components/food-management.tsx`.
- [x] [USERS-BE] Mở rộng `IUserService` và `UserService` với hàm `GetPagedUsersAsync(...)` trả về `PagedResult<UserAdminResponse>`.
- [x] [USERS-BE] Nâng cấp `UserController.GetAllUsers` hỗ trợ query parameters phân trang & tìm kiếm (`keyword`, `role`, `isActive`, `membershipStatus`, `page`, `pageSize`).
- [x] [USERS-FE] Cập nhật types trong `features/users/types.ts` (`UserSearchParams`, `UserSearchResult`).
- [x] [USERS-FE] Cập nhật API client trong `features/users/api/admin-user-api.ts`.
- [x] [USERS-FE] Nâng cấp hook `features/users/hooks/use-users.ts` hỗ trợ phân trang & bộ lọc.
- [x] [USERS-FE] Nâng cấp `features/users/components/user-management.tsx` thêm thanh tìm kiếm/lọc và component `<Pagination />`.

## Reviewer
- [x] Code review Clean Code, không warning hoặc lỗi cú pháp.
- [x] Kiểm tra tính toàn vẹn bảo mật (không rò rỉ endpoint nhạy cảm, giữ nguyên policy `AdminOnly`).
- [x] Xác nhận không có thao tác nào liên quan đến Git/GitHub.

## Tester
- [x] Kiểm tra build Backend C# .NET (`dotnet build MenuGreen.sln`) -> Passed (0 errors, 0 warnings).
- [x] Kiểm tra build Frontend Next.js (`npm run build`) -> Passed (Compiled & optimized successfully).
- [x] Xác minh chức năng phân trang, chuyển trang, đổi pageSize trên cả Foods và Users.

## DevOps
- [x] Xác nhận không làm thay đổi cấu hình môi trường `.env`.
- [x] Xác nhận môi trường build ổn định.

## Definition of Done
- [x] Màn hình Quản lý Món ăn (`/dashboard/foods`) có phân trang mượt mà, đầy đủ tính năng.
- [x] Màn hình Quản lý Người dùng (`/dashboard/users`) có tìm kiếm/lọc và phân trang mượt mà.
- [x] Toàn bộ test và build trên cả frontend lẫn backend đều PASS.
- [x] Báo cáo `docs/report/walkthrough.md` được khởi tạo hoàn tất.
