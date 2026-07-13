# MenuGreen System — Quy trình & Luồng Nghiệp Vụ (Workflows)

Hệ thống **MenuGreen** là một nền tảng dinh dưỡng cá nhân hóa tích hợp AI và quản lý chế độ ăn uống cho thị trường Việt Nam. Tài liệu này cung cấp cái nhìn tổng quan về luồng nghiệp vụ tương tác giữa các vai trò (roles) trong hệ thống và đóng vai trò làm mục lục cho các tài liệu chi tiết.

---

## 👥 Các Vai Trò Trong Hệ Thống (Roles)

Hệ thống MenuGreen được phân quyền rõ ràng thành 3 nhóm vai trò chính:

1. **User (Người dùng)**
   * **Free User**: Sử dụng các tính năng cơ bản như đăng ký, thiết lập hồ sơ sức khỏe, ghi nhật ký ăn uống (meal log), theo dõi cân nặng, tìm kiếm món ăn/công thức và nhận các gợi ý cơ bản theo quy tắc (rule-based).
   * **Premium User**: Người dùng trả phí (nâng cấp qua cổng SePay), được tiếp cận các tính năng nâng cao như Lập kế hoạch bữa ăn cá nhân hóa theo ngân sách (Meal Plan), Chương trình Dinh dưỡng Đặc biệt (Premium Programs), sử dụng Trợ lý AI nâng cao (AI Assistant/AI Coach), nhận diện món ăn từ camera (Food Capture) và kết nối trực tiếp với huấn luyện viên (Coach/PT).

2. **Coach / PT (Huấn luyện viên)**
   * **In-app Coach**: Người dùng trong app thực hiện nâng cấp tài khoản lên Coach. Họ có hồ sơ chuyên môn (specialty, price, bio), xuất hiện trong danh mục tìm kiếm công khai, có thể kết nối lâu dài với học viên (student) để theo dõi chỉ số sức khỏe, gửi ý kiến đánh giá và trực tiếp điều chỉnh thực đơn/mục tiêu calo cho học viên.
   * **Guest PT (PT bên ngoài)**: Các PT hoặc chuyên gia dinh dưỡng không đăng ký tài khoản trên app. Họ nhận được liên kết chia sẻ báo cáo tuần (weekly report token-based link) từ người dùng để xem nhanh và đóng góp ý kiến đánh giá một lần mà không cần đăng nhập hệ thống.

3. **Admin (Quản trị viên)**
   * **System Admin**: Quản trị tài khoản người dùng (khóa, mở khóa, gán vai trò), quản lý gói dịch vụ Premium, đối soát giao dịch SePay.
   * **Content & AI Admin**: Quản trị danh mục thực phẩm, món ăn, công thức nấu ăn, định nghĩa dị ứng, quản lý dữ liệu crawler thực phẩm và kiểm duyệt/tối ưu dữ liệu huấn luyện cho trợ lý AI.

---

## 📊 Sơ Đồ Tương Tác Giữa Các Vai Trò (Interaction Diagram)

Dưới đây là sơ đồ Mermaid thể hiện cách các vai trò tương tác với nhau và với các phân hệ chính của MenuGreen:

```mermaid
graph TD
    %% Roles Definition
    User[User / Student]
    Coach[In-app Coach]
    GuestPT[Guest PT / External]
    Admin[Admin / Ops]

    %% Main Subsystems
    AuthDB[(Auth & Health DB)]
    NutritionTracker[Nutrition & Meal Planner]
    AIEngine[AI Coach & Recommend API]
    PaymentSystem[SePay Webhook & Plans]
    Catalog[(Food & Allergy Catalog)]

    %% User Interactions
    User -->|1. Setup Profile & Goals| AuthDB
    User -->|2. Log Meals & Weight| NutritionTracker
    User -->|3. Get Meal/Budgets Suggestions| AIEngine
    User -->|4. Pay Subscription QR| PaymentSystem

    %% Coach & User Connection
    User -->|5a. Request connection| Coach
    Coach -->|5b. Approve & Link student| User
    User -->|5c. Grant data access| Coach
    Coach -->|6. View metrics & Adjust Plans| NutritionTracker
    
    %% PT Review Interaction
    User -->|7a. Create shareable token| GuestPT
    GuestPT -->|7b. Submit review & target suggestions| User
    
    %% Admin Actions
    Admin -->|8. Manage accounts & Assign roles| AuthDB
    Admin -->|9. Manage plans & Audit payments| PaymentSystem
    Admin -->|10. Curate food & allergy list| Catalog
    Admin -->|11. Ingest crawler & Audit training samples| AIEngine
```

---

## 📂 Danh Sách Các Luồng Quy Trình Chi Tiết

Để tìm hiểu chi tiết luồng nghiệp vụ của từng vai trò, vui lòng truy cập các liên kết dưới đây:

* 🥗 **[Quy trình Người Dùng (User Workflow)](file:///e:/EXE201-MenuGreen/MenuGreenSystem/docs/workflow/user_workflow.md)**: Chi tiết hành trình từ đăng ký, onboarding, theo dõi calo, lên kế hoạch ăn uống, chat AI cho đến nâng cấp tài khoản Premium.
* 👟 **[Quy trình Huấn Luyện Viên (Coach Workflow)](file:///e:/EXE201-MenuGreen/MenuGreenSystem/docs/workflow/coach_workflow.md)**: Hướng dẫn luồng đăng ký làm Coach, kết nối học viên, xem dashboard chỉ số và thay đổi thực đơn học viên, cùng quy trình đánh giá qua token link dành cho PT ngoài.
* ⚙️ **[Quy trình Quản Trị Viên (Admin Workflow)](file:///e:/EXE201-MenuGreen/MenuGreenSystem/docs/workflow/admin_workflow.md)**: Quy trình vận hành hệ thống, khóa/mở khóa tài khoản, phê duyệt danh mục thực phẩm, cập nhật nguyên liệu thay thế và tinh chỉnh mô hình AI.
