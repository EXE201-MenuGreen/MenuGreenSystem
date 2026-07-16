# Báo cáo triển khai Office Workflow

## Phạm vi

Hoàn thiện các mục 3–5 của `docs/workflow/office_workflow.md`, đồng thời nối trạng thái Office với UI để người dùng có thể bắt đầu luồng này từ Hồ sơ/Gói dịch vụ.

## Luồng đã triển khai

1. Người dùng chọn **Gói Office** trong màn Gói dịch vụ.
2. Ứng dụng lưu `UserAiProfile.EatingPattern = "office"` qua API hồ sơ AI, sau đó quay lại Hồ sơ và hiển thị gói Office.
3. Người dùng mở **Không gian Office** → tab **Ngân sách**.
4. Người dùng lưu ngân sách tuần và thời gian nấu tối đa.
5. Người dùng chọn **Tạo kế hoạch cơm hộp Office**.
6. Backend tạo meal plan theo calorie target, dị ứng, ngân sách và giới hạn thời gian nấu; sau đó UI hiển thị grocery list tổng hợp.
7. Người dùng sử dụng Meal Templates để ghi nhanh bữa trưa lặp lại và Micro-learning để học nội dung Office.

## Thay đổi backend

### Office meal planning

- `MealPlanService.GenerateByBudgetAsync` nhận diện đúng `EatingPattern` lưu theo JSON (`"office"`).
- Plan Office có tiêu đề **Cơm hộp văn phòng**.
- Recipe bị giới hạn bởi `BudgetRequest.TimeLimitMin`; vẫn áp dụng target calories và allergy filtering.
- `GET /api/MealPlan/{id}/grocery-list` tổng hợp nguyên liệu của recipe, số lượng, đơn vị và giá ước tính.

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
- Tab Ngân sách có nút tạo lunchbox plan và dialog grocery list.
- Reminder, Meal Templates và Micro-learning đã có màn hình có thể truy cập từ ứng dụng.

## Kiểm tra

- `dotnet build MenuGreen.API/MenuGreen.API.csproj --no-restore`: thành công.
- `flutter analyze` cho Profile, Upgrade Plan và Advanced Features: không có lỗi.

## Việc triển khai môi trường

- Deploy/restart backend để API production nhận thay đổi Reminder, `UserOnly`, meal plan và micro-learning.
- Chạy seed `backend/database/49_micro_learning_cards.sql` trên database mục tiêu để có card category `Office`.
- Build/release lại Flutter app để người dùng nhận giao diện và luồng Office mới.
