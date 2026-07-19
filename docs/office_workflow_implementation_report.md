# Báo cáo triển khai Office Workflow

## Phạm vi

Hoàn thiện các mục 3–5 của `docs/workflow/office_workflow.md`, đồng thời nối trạng thái Office với UI để người dùng có thể bắt đầu luồng này từ Hồ sơ/Gói dịch vụ.

## Luồng đã triển khai

1. Người dùng chọn **Gói Office** trong màn Gói dịch vụ.
2. Ứng dụng lưu `UserAiProfile.EatingPattern = "office"` qua API hồ sơ AI, sau đó quay lại Hồ sơ và hiển thị gói Office.
3. Người dùng mở **Không gian Office** → **Kế hoạch cơm hộp**.
4. Người dùng nhấn icon ví tiền trên AppBar để lưu ngân sách và thời gian nấu tối đa.
5. Người dùng chọn **Tạo kế hoạch cơm hộp** ngay trên cùng màn hình.
6. Backend tạo meal plan theo calorie target, ngân sách và giới hạn thời gian nấu; sau đó UI hiển thị grocery list tổng hợp.
7. Người dùng sử dụng Meal Templates để ghi nhanh bữa trưa lặp lại và Micro-learning để học nội dung Office.

## Thay đổi backend

### Office meal planning

- `MealPlanService.GenerateByBudgetAsync` nhận diện đúng `EatingPattern` lưu theo JSON (`"office"`).
- Plan Office có tiêu đề **Cơm hộp văn phòng**.
- Recipe bị giới hạn bởi `BudgetRequest.TimeLimitMin`, được chấm điểm theo độ gần calorie target, chi phí và thời gian chuẩn bị. Theo yêu cầu hiện tại, luồng tạo kế hoạch ngân sách không áp dụng lọc dị ứng.
- Thuật toán giữ `remainingBudget` cho 21 bữa, dự phòng chi phí tối thiểu của các bữa còn lại và chỉ lưu plan khi tổng dự kiến không vượt ngân sách tuần.
- Nếu ngân sách không khả thi, API trả mức ngân sách tối thiểu ước tính và không tạo plan rác/orphan.
- Giảm lặp recipe bằng cách tránh hai món gần nhất của cùng loại bữa khi còn lựa chọn khác.
- Sửa calories/macros của recipe: ưu tiên nutrition từ `Food` liên kết; ingredient theo gram/ml được quy đổi trên 100g và chia theo số khẩu phần của recipe.
- `GET /api/MealPlan/{id}/grocery-list` nhân nguyên liệu theo số lần recipe xuất hiện, chia theo số khẩu phần và tính giá theo tổng khối lượng.
- `GET /api/MealPlan/{id}/budget-status` kiểm tra ownership và trả chi phí dự kiến so với ngân sách hiện tại.

### Micro-learning Office

- `MicroLearningService` nhận diện Office user từ `EatingPattern` JSON.
- Category `Office` được đưa vào tập nội dung gợi ý và được ưu tiên trước các card thông thường.
- Bổ sung seed card cho: giãn cơ 3 phút tại bàn, snack buổi chiều và cơm hộp cân bằng.

### Meal templates

- Chức năng đã có đầy đủ: tạo/sửa/xóa, duplicate, tạo từ meal log và log nhanh template.
- Người dùng Office có thể dùng template như **Cơm trưa đi làm**; không còn phụ thuộc vào role hoặc payment.

## Thay đổi Flutter

- Card **Gói Office** miễn phí trong `UpgradePlanScreen`.
- Kích hoạt Office gọi `UserAiProfile` API trước khi quay về Hồ sơ.
- Hồ sơ hiển thị badge `OFFICE` trong phiên hiện tại và có entry **Không gian Office**.
- HomePage đọc `EatingPattern=office` từ backend và hiển thị panel **Không gian Office** với lối tắt đến cơm hộp/ngân sách, reminder, Meal Templates và Micro-learning.
- Bổ sung **Quét nguyên liệu** trong panel Office và sheet **Tất cả tính năng**. Luồng dùng Food CV hiện có và ưu tiên các hành động dành cho bữa trưa.
- Kết quả scan không còn ghi thẳng vào nhật ký. Mỗi card sử dụng nút **Xem món**, sau đó mở chi tiết gồm khẩu phần, calories/macros, cảnh báo dị ứng và nguyên liệu theo khối lượng.
- Ảnh chọn từ thiết bị được giới hạn trong khung scan và dùng `BoxFit.contain`, giữ nguyên tỷ lệ ảnh thay vì phóng phủ toàn màn hình.
- Chi tiết món Office cung cấp ba hành động có chủ đích: **Dùng cho bữa trưa hôm nay**, **Thêm vào kế hoạch cơm hộp** và **Lưu vào mẫu bữa ăn**.
- Khi lưu mẫu, người dùng chọn **Bữa sáng**, **Bữa trưa** hoặc **Bữa tối**; template được tạo qua API và xuất hiện trong màn **Mẫu bữa ăn**.
- Khi thêm món vào kế hoạch, người dùng chọn ngày; hệ thống tạo kế hoạch Office cho tuần nếu chưa có, hoặc hỏi xác nhận **Thay món** nếu ngày đó đã có bữa trưa.
- Gom **Quét nguyên liệu** và **Nhắc nhở văn phòng** vào màn **Không gian Office**; sheet **Tất cả tính năng** chỉ hiển thị một entry Office duy nhất.
- Luồng **Kế hoạch cơm hộp Office** dùng màn hình riêng, không còn hiển thị tab PT hoặc Coach.
- Thiết lập mục tiêu ngân sách được mở bằng icon ví tiền trên AppBar; tóm tắt ngân sách, kế hoạch món ăn và grocery list cùng nằm trên một giao diện.
- Card ngân sách hiển thị **Chi phí dự kiến / Ngân sách tuần**, progress và số tiền còn lại hoặc vượt mức từ `budget-status`.
- Khi ngân sách tuần hoặc thời gian nấu thay đổi, kế hoạch tự sinh theo ngân sách trước đó được chuyển sang inactive và UI yêu cầu tạo lại kế hoạch; không còn ghép chi phí cũ với hạn mức mới như `700.000đ / 100.000đ`.
- Dialog ngân sách tự quản lý vòng đời `TextEditingController`; thao tác gọi API và cập nhật màn hình chỉ bắt đầu sau khi dialog đóng hoàn toàn để tránh lỗi `_dependents.isEmpty` khi route đang teardown.
- Form ngân sách ghi rõ đây là hạn mức cho 7 ngày; khi không thể tạo đủ 21 bữa trong hạn mức, UI hiển thị thông báo khả thi từ backend.
- Kết quả tạo lunchbox plan được giữ và hiển thị trực tiếp trên màn hình thay vì chỉ xuất hiện trong dialog.
- Khi mở lại màn hình, ứng dụng tải kế hoạch cơm hộp gần nhất và grocery list từ backend thay vì mất kết quả theo state cục bộ.
- Kế hoạch tuần được trình bày thành roadmap ziczac kiểu Duolingo: mỗi node là một ngày, nối bằng đường tiến trình và chứa ba bữa chính theo thứ tự **Trưa → Sáng → Tối**. Bữa trưa có nhãn **Ưu tiên Office**.
- Refactor UI Office theo trách nhiệm: screen chỉ giữ state/API; Home panel, plan summary, roadmap, day node và grocery list được chuyển thành các widget riêng trong `features/office/widgets`.
- Tách các màn hình dùng trong Không gian Office đang chứa nhiều widget: Micro-learning thành main/saved/detail/widgets, Meal Templates thành list/editor/sections/picker và Adaptive Reminders thành screen/widgets. Các file dùng Dart `part` để giữ private scope và không thay đổi business logic.
- Màn **Kế hoạch cơm hộp** sử dụng hai tab **Kế hoạch** và **Danh sách đi chợ**. Grocery list không còn nằm dưới roadmap; tab riêng hiển thị tổng nguyên liệu, chi phí ước tính và trạng thái rỗng theo kế hoạch hiện tại.
- Gỡ mục **Kiến thức/Góc sức khỏe Office** khỏi Home panel và màn Không gian Office; module Micro-learning vẫn được giữ cho các luồng dùng chung khác.
- Reminder, Meal Templates và Micro-learning đã có màn hình có thể truy cập từ ứng dụng.

## Kiểm tra

- `dotnet build MenuGreen.API/MenuGreen.API.csproj --no-restore`: thành công.
- `flutter analyze` cho Profile, Upgrade Plan, Home và Office Meal Plan: không có lỗi.
- `flutter analyze` cho luồng Quét nguyên liệu, chi tiết món, Meal Plan request và các entry Office: không có lỗi.

## Việc triển khai môi trường

- Deploy/restart backend để API production nhận thay đổi Reminder, `UserOnly`, meal plan và micro-learning.
- Chạy seed `backend/database/49_micro_learning_cards.sql` trên database mục tiêu để có card category `Office`.
- Build/release lại Flutter app để người dùng nhận giao diện và luồng Office mới.
