# Kế hoạch triển khai: Phân trang cho MenuGreen Admin (Foods & Users)

## 1. Mục tiêu
Thực hiện chạy và tạo chức năng phân trang (Pagination) chuẩn hóa, hiện đại cho **MenuGreen Admin** tại hai màn hình:
1. **Quản lý Món ăn** (`/dashboard/foods`)
2. **Quản lý Người dùng** (`/dashboard/users`)

Thực hiện theo tiêu chuẩn **Strict Mode** (quy trình khép kín 8 phase theo `.agent/workflow_rules.md`) và tuân thủ tuyệt đối quy tắc **không thực hiện bất kỳ hành động nào liên quan đến GitHub / Git remote**.

---

## 2. Phân tích hiện trạng & Giải pháp kỹ thuật

### 2.1. Quản lý Món ăn (`/dashboard/foods`)
- **Backend**: Endpoint `GET /api/Food` (`FoodController.SearchAsync`) đã hỗ trợ `page` và `pageSize`, trả về `FoodSearchResponse` (bao gồm `Items`, `TotalCount`, `Page`, `PageSize`, `TotalPages`).
- **Frontend-Web**:
  - `FoodSearchParams` và `FoodSearchResult` trong `features/foods/types.ts`: bổ sung `page`, `pageSize`, `totalPages`.
  - `foodApi.search()` trong `features/foods/api/food-api.ts`: bổ sung truyền `page` và `pageSize`.
  - `useFoods` hook: quản lý state `page`, `pageSize`, `totalPages`. Reset về trang 1 khi lọc/tìm kiếm mới.
  - `FoodManagement` UI: tích hợp `<Pagination />` vào dưới bảng dữ liệu.

### 2.2. Quản lý Người dùng (`/dashboard/users`)
- **Backend**:
  - `IUserService` & `UserService`: Thêm phương thức `GetPagedUsersAsync(keyword, role, isActive, membershipStatus, page, pageSize)` trả về `PagedResult<UserAdminResponse>`.
  - `UserController`: Nâng cấp action `GetAllUsers` hỗ trợ các query params phân trang và bộ lọc (`keyword`, `role`, `isActive`, `membershipStatus`, `page`, `pageSize`).
- **Frontend-Web**:
  - `features/users/types.ts`: Bổ sung `UserSearchParams` và `UserSearchResult`.
  - `features/users/api/admin-user-api.ts`: Bổ sung `search(params)`.
  - `features/users/hooks/use-users.ts`: Quản lý state `filters`, `page`, `pageSize`, `totalPages`, `totalCount`.
  - `features/users/components/user-management.tsx`: Bổ sung thanh tìm kiếm & bộ lọc, tích hợp `<Pagination />`.

### 2.3. Shared UI Component
- Tạo component `Pagination` tại `frontend-web/components/ui/pagination.tsx`:
  - Hỗ trợ First (`<<`), Prev (`<`), Next (`>`), Last (`>>`) và các nút chọn trang kèm dấu chấm lửng (`...`).
  - Hỗ trợ đổi `pageSize` (10, 20, 50, 100).
  - Hiển thị tóm tắt: *"Hiển thị X - Y trên tổng số Z mục"*.
  - Tương thích Light / Dark Mode và disabled states.

---

## 3. Kế hoạch xác minh
- **Backend Build**: Chạy `dotnet build MenuGreen.sln` -> 0 lỗi.
- **Frontend Build**: Chạy `npm run build` trên `frontend-web` -> 0 lỗi TypeScript, static generation pass.
- **Kiểm thử giao diện**: Kiểm tra thao tác chuyển trang, đổi số lượng mục/trang, tìm kiếm/lọc trên cả 2 trang Foods và Users.
