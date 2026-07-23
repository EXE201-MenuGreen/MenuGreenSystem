# Báo cáo triển khai Office Workflow

> Cập nhật ngày 20/07/2026
> Tài liệu đối chiếu: `docs/workflow/office_workflow.md`

## 1. Tổng quan

Luồng Office hiện đã có thể sử dụng từ lúc người dùng mở gói Office đến khi tạo kế hoạch cơm hộp, đổi món, xem công thức, xem danh sách đi chợ, quét nguyên liệu và lưu món vào kế hoạch hoặc mẫu bữa ăn.

Phạm vi hiện tại chủ động **bỏ qua thanh toán**. Gói Office là gói miễn phí thử nghiệm trong 1 ngày; đăng ký tại một thời điểm ngày 20/07 sẽ hết hạn đúng cùng thời điểm ngày 21/07. Không gian Office được bật theo `UserAiProfile.EatingPattern = "office"` và subscription Office đang hoạt động.

## 2. Trạng thái theo `office_workflow.md`

| Mục | Trạng thái | Kết quả hiện tại |
| --- | --- | --- |
| 1. Đăng ký và Onboarding | Một phần | Dùng luồng đăng ký/onboarding chung. Có thể mở gói Office miễn phí từ Gói dịch vụ; chưa dùng SePay cho Office. |
| 2. Adaptive Reminders | Đã nối UI và API | Có màn Nhắc nhở văn phòng, cấu hình profile, tạo/sửa/xóa lịch, recalculate và snooze. |
| 3. Budget-Aware Meal Planning | Đã triển khai luồng chính | Thiết lập ngân sách và thời gian nấu, sinh 21 bữa/7 ngày, roadmap, đổi món, công thức, budget status và danh sách đi chợ theo lượt mua. |
| 4. Micro-Learning Office | Backend còn, đã gỡ khỏi Office UI | Seed và service vẫn hỗ trợ category Office, nhưng mục Kiến thức đã được gỡ khỏi Không gian Office theo yêu cầu mới. |
| 5. Meal Templates | Đã triển khai | CRUD, duplicate, tạo từ meal log, ghi nhật ký nhanh và lưu món từ kết quả scan theo sáng/trưa/tối. |
| Quét nguyên liệu Office | Đã bổ sung | Chụp/tải ảnh, chờ AI, xem món, xem nguyên liệu/chỉ số, đưa vào kế hoạch hoặc mẫu bữa ăn và đồng bộ nhật ký. |

## 3. Luồng hoạt động hiện tại

### 3.1. Mở gói Office

1. Người dùng đăng nhập bằng tài khoản thông thường.
2. Từ Hồ sơ, người dùng mở **Gói dịch vụ** và chọn **Mở tính năng Office**.
3. Flutter đăng ký subscription Office miễn phí và lưu `EatingPattern = "office"` qua User AI Profile API.
4. Ứng dụng quay lại Hồ sơ, tải lại subscription và hiển thị gói Office.
5. Home tải `EatingPattern` từ backend và hiển thị panel **Không gian Office**.

Gói Office hiện được cấu hình `DurationDays = 1`. Backend tính `EndDate = StartDate.AddDays(1)` thay vì fallback 36.500 ngày. Hồ sơ hiển thị ngày bắt đầu, ngày hết hạn và thời gian còn lại, tự cập nhật mỗi phút.

### 3.2. Không gian Office

Panel trên Home hiển thị một hàng ngang có thể scroll, chỉ gồm icon và tên:

- **Quét nguyên liệu**
- **Nhắc nhở**
- **Cơm hộp**
- **Mẫu bữa ăn**

Tiêu đề **Không gian Office** dùng màu xanh cùng hệ thống. Mục **Kiến thức** không còn xuất hiện trong panel hoặc màn danh sách Office.

### 3.3. Kế hoạch cơm hộp

1. Người dùng mở **Cơm hộp**.
2. Dùng icon ví tiền trên AppBar để nhập ngân sách cho 7 ngày và thời gian nấu tối đa.
3. Nhấn **Tạo kế hoạch cơm hộp**.
4. Backend tạo 21 slot cho 7 ngày, mỗi ngày gồm ba bữa theo thứ tự ưu tiên hiển thị **Trưa → Sáng → Tối**.
5. UI hiển thị roadmap ziczac kiểu Duolingo. Mỗi node ngày có tổng calories và ba món; bữa trưa mang nhãn **Ưu tiên Office**.
6. Chạm vào tên món để mở công thức, nguyên liệu và hướng dẫn nấu.
7. Chạm icon đổi món để nhận danh sách món cùng loại bữa, phù hợp thời gian nấu và được ưu tiên theo ngân sách/calories/mức độ lặp.
8. Sau khi đổi món, ứng dụng tải lại roadmap, budget status và grocery list.

Kế hoạch cũ do Budget-Aware tạo sẽ được chuyển inactive khi tạo kế hoạch mới. Khi thay đổi ngân sách hoặc thời gian nấu, UI xóa kết quả cũ khỏi state và yêu cầu tạo lại để tránh hiển thị sai dạng `700.000đ / 100.000đ`.

### 3.4. Danh sách đi chợ

Màn Kế hoạch cơm hộp có hai tab ngang:

- **Kế hoạch**
- **Danh sách đi chợ**

Danh sách đi chợ không còn nằm cuối roadmap. Backend trả ba lớp dữ liệu: tổng hợp cả tuần, theo ngày và `ShoppingTrips` theo lượt mua thực tế.

Quy tắc lượt mua:

- Lượt chuẩn bị trước tuần phục vụ bữa sáng và bữa trưa ngày đầu.
- Lượt mua sau giờ làm ngày `D` phục vụ bữa tối ngày `D`, bữa sáng và cơm hộp trưa ngày `D+1`.
- Nguyên liệu dùng lâu dài như gạo, yến mạch, dầu và gia vị được gom vào lượt đầu, gắn `IsWeeklyStock`.
- Mỗi lượt hiển thị ngày mua, các bữa được phục vụ, nguyên liệu, số lượng và chi phí ước tính.
- Tổng tiền của tab được tính từ các lượt mua để tránh cộng trùng nguyên liệu.

### 3.5. Quét nguyên liệu Office

1. Người dùng chụp ảnh hoặc tải ảnh từ thiết bị.
2. Ảnh được giữ đúng tỷ lệ trong khung 280×280 bằng `BoxFit.contain`, không còn tràn màn hình.
3. Trong lúc backend chờ AI worker, Flutter hiển thị overlay tiến trình với các trạng thái: chuẩn bị ảnh, tải ảnh, nhận diện nguyên liệu, xây dựng món và hoàn tất kết quả.
4. UI hiển thị số giây đã chờ và thông báo thời gian xử lý thường từ 20–60 giây, tránh khiến người dùng hiểu nhầm là lỗi.
5. Kết quả scan hiển thị danh sách món với hành động **Xem món**.
6. Chi tiết món hiển thị khẩu phần, calories/macros và nguyên liệu theo khối lượng.
7. Người dùng có thể:
   - dùng món cho bữa ăn hiện tại;
   - thêm vào kế hoạch cơm hộp và chọn ngày;
   - thay bữa trưa đã có sau khi xác nhận;
   - lưu vào Mẫu bữa ăn theo bữa sáng, trưa hoặc tối.

API `POST /api/MealPlan/{planId}/scan-meals` có thể lưu kết quả AI scan đồng thời vào `MealPlanItem` và `MealLog`. Item được đánh dấu `SourceType = "AiScan"`, lưu snapshot nguyên liệu và hiển thị trạng thái **AI Scan · Đã dùng** trên roadmap.

### 3.6. Nhắc nhở văn phòng

Màn Nhắc nhở sử dụng các API:

- `GET /api/Reminder/profile`
- `POST /api/Reminder/profile/recalculate`
- `PUT /api/Reminder/profile`
- `GET/POST/PATCH/DELETE /api/Reminder/scheduled`
- `POST /api/Reminder/scheduled/{id}/snooze`

Người dùng có thể cấu hình giờ ăn, uống nước, vận động/giãn cơ và tạm hoãn lịch. Việc hiển thị notification đúng giờ trên thiết bị vẫn phụ thuộc quyền thông báo, cấu hình nền và môi trường chạy ứng dụng.

### 3.7. Mẫu bữa ăn

Meal Templates hỗ trợ:

- tạo, sửa và xóa mẫu;
- duplicate mẫu;
- tạo mẫu từ meal log;
- ghi nhanh mẫu vào nhật ký;
- lưu món từ kết quả scan theo loại bữa sáng/trưa/tối.

Mẫu bữa ăn là tổ hợp có thể tái sử dụng, khác với kế hoạch Office theo tuần: template không tự phân bổ ngân sách, không tạo lịch 7 ngày và không tạo danh sách đi chợ.

## 4. Thay đổi backend

### Subscription Office

- Seed gói Office với `DurationDays = 1`, giá `0`, `FeatureGroup = "office"`.
- Đăng ký/gia hạn Office sử dụng thời hạn chính xác 1 ngày nếu dữ liệu cũ đang để `DurationDays = null`.
- Loại bỏ fallback 100 năm đối với Office trong subscribe, renew, SePay activation và reconciliation.
- `DaysRemaining` được làm tròn lên; gói vừa kích hoạt không còn hiển thị `0 ngày` do sai số mili-giây.

### Budget-Aware Meal Plan

- `MealPlanService.GenerateByBudgetAsync` nhận diện `EatingPattern` được lưu dưới dạng JSON string.
- Tạo 21 bữa cho 7 ngày và dùng title **Cơm hộp văn phòng** với Office user.
- Recipe được lọc theo loại bữa và giới hạn thời gian chuẩn bị/nấu.
- Chấm điểm theo calories, giá, thời gian, số lần đã dùng và một thành phần random nhỏ để tăng đa dạng.
- Không cho các recipe trong cùng ngày bị trùng khi còn lựa chọn phù hợp.
- Dự phòng chi phí tối thiểu cho các slot còn lại trước khi chọn món, không lưu kế hoạch nếu tổng tiền vượt ngân sách.
- Theo yêu cầu hiện tại, luồng sinh kế hoạch ngân sách không áp dụng lọc dị ứng.
- Calories/macros ưu tiên dữ liệu `Food`; nếu tính từ ingredient thì quy đổi gram/ml theo 100g và chia theo servings.
- Giá recipe được quy về một khẩu phần bằng `EstimatedPriceVnd / Servings`.

### Đổi món và công thức

- `GET /api/MealPlan/{planId}/alternatives/{itemId}` kiểm tra ownership.
- Loại món hiện tại và recipe đã dùng trong cùng ngày.
- Tôn trọng loại bữa và giới hạn thời gian nấu.
- Ưu tiên món không làm vượt ngân sách, món ít lặp và calories gần món cũ.
- Flutter vẫn cho phép người dùng xác nhận đổi nếu lựa chọn làm kế hoạch vượt ngân sách.

### Grocery list

- `GET /api/MealPlan/{id}/grocery-list` tổng hợp ingredient theo số lần recipe xuất hiện và servings.
- Tính khối lượng, chi phí theo đơn vị và trả `Items`, `Days`, `ShoppingTrips`.
- Phân loại nguyên liệu dự trữ tuần và gom vào lượt chuẩn bị đầu tiên.
- `GET /api/MealPlan/{id}/budget-status` kiểm tra ownership, trả chi phí kế hoạch, hạn mức và phần vượt.

### Micro-learning

- `MicroLearningService` vẫn nhận diện Office user và ưu tiên category `Office`.
- Seed vẫn có card về giãn cơ tại bàn, snack buổi chiều và cơm hộp cân bằng.
- Module được giữ cho luồng dùng chung nhưng không còn entry trong Không gian Office.

## 5. Thay đổi Flutter

- Card Office miễn phí trong `UpgradePlanScreen`; kích hoạt xong quay về Hồ sơ và reload dữ liệu.
- Hồ sơ hiển thị ngày bắt đầu, ngày hết hạn và thời gian còn lại realtime.
- Home chỉ hiển thị panel Office khi backend trả `EatingPattern = office`.
- Panel Office dạng horizontal scroll, icon ở trên và tên ở dưới.
- Màn Cơm hộp riêng, không có PT hoặc Coach.
- Ngân sách và kế hoạch nằm trên cùng màn hình; ngân sách mở qua icon AppBar.
- Roadmap tách thành các widget plan summary, roadmap, day node và grocery tab.
- Chạm món mở `RecipeDetailScreen`; hướng dẫn nấu được trình bày thành từng bước thay vì chuỗi JSON thô.
- Đổi món dùng bottom sheet, hiển thị calories, giá và cảnh báo ngân sách trước khi xác nhận.
- Tab Grocery hiển thị các lượt mua trước tuần/sau giờ làm và fallback tương thích response cũ.
- Scan có trạng thái chờ AI rõ ràng, ảnh vừa khung và các hành động Office có chủ đích.
- Micro-learning, Meal Templates và Adaptive Reminders đã được tách widget/file để giảm kích thước screen.

## 6. Quy tắc nghiệp vụ đang áp dụng

1. Gói Office hiện là trial miễn phí 1 ngày.
2. Không gian Office được nhận diện bằng `EatingPattern = office`.
3. Ngân sách là hạn mức của 7 ngày, không phải ngân sách mỗi ngày.
4. Một kế hoạch Office gồm 7 ngày × 3 bữa = 21 bữa.
5. Bữa trưa được ưu tiên trong cách trình bày, nhưng ngân sách áp dụng cho cả 21 bữa.
6. Đổi món phải cùng loại bữa, tôn trọng thời gian nấu và tránh trùng recipe trong ngày.
7. Người dùng được cảnh báo nhưng vẫn có quyền xác nhận món khiến kế hoạch vượt ngân sách.
8. Scan có thể tạo actual meal log và đồng bộ plan item trong cùng một lần lưu.
9. Danh sách đi chợ được chia theo thời điểm mua, không chỉ theo ngày ăn.
10. Dị ứng đang bị bỏ qua riêng trong thuật toán sinh kế hoạch ngân sách theo yêu cầu hiện tại.

## 7. Điểm chưa hoàn thiện hoặc khác workflow gốc

### Role và entitlement

Workflow gốc yêu cầu sau khi mua gói, role tài khoản chuyển thành `Office`. Source hiện tại dùng `EatingPattern` để mở giao diện Office, trong khi `UserSubscriptionService.SubscribeAsync` vẫn gán role `Free` cho subscription miễn phí. Các controller Office đang dùng policy `UserOnly` nên luồng chính vẫn hoạt động, nhưng mô hình role chưa đúng hoàn toàn với thiết kế `User → Office/Gym/Casual` đã đề xuất.

### Payment

SePay cho Office chưa nằm trong luồng hiện tại vì phạm vi được yêu cầu bỏ qua thanh toán. Office đang là gói miễn phí 1 ngày.

### Micro-learning Office

Backend và seed có dữ liệu Office nhưng entry Kiến thức đã được gỡ khỏi UI. Vì vậy mục 4 của workflow không còn là một bước trong hành trình Office hiện tại.

### Thay thế nguyên liệu

API ingredient substitutes tồn tại trong hệ thống, nhưng chưa được nhúng trực tiếp vào từng item của tab Danh sách đi chợ Office. Người dùng phải truy cập tính năng thay thế nguyên liệu dùng chung.

### Chất lượng kế hoạch

Độ đa dạng, giá và danh sách đi chợ phụ thuộc vào dữ liệu `recipes`, `recipe_ingredients`, servings, meal type, thời gian nấu và giá ingredient. Recipe thiếu liên kết hoặc giá bằng 0 sẽ không phải ứng viên tốt cho kế hoạch ngân sách.

### AI scan

Thời gian phản hồi phụ thuộc AI/CV worker và kết nối backend. UI đã có trạng thái chờ, nhưng chưa có cơ chế chạy job nền rồi gửi notification khi người dùng rời màn hình.

## 8. Kiểm tra đã thực hiện

- Backend build thành công với `dotnet build MenuGreen.API/MenuGreen.API.csproj --no-restore` qua output kiểm tra riêng.
- Flutter analyze cho Profile, Subscription và hiển thị thời hạn: không có lỗi.
- Các lần kiểm tra trước cho Home, Office Meal Plan, Grocery, Meal Templates, Reminder và Ingredient Scan không phát hiện lỗi analyzer.
- Database local đã được hiệu chỉnh gói Office từ thời hạn 36.500 ngày về đúng 1 ngày.
- Backend local hiện đã được dừng theo yêu cầu; cần khởi động lại trước khi test end-to-end trên thiết bị.

## 9. Việc cần làm khi triển khai môi trường

1. Khởi động/restart backend để nạp code subscription, meal plan, grocery và scan mới.
2. Đảm bảo database mục tiêu có plan Office: `DurationDays = 1`, `PriceVnd = 0`, `FeatureGroup = office`.
3. Chạy seed recipe, recipe ingredient và giá nguyên liệu đầy đủ trước khi đánh giá chất lượng random/budget.
4. Nếu bật lại Micro-learning Office, chạy `backend/database/49_micro_learning_cards.sql` và thêm lại entry UI.
5. Build/release Flutter mới để nhận panel Office, roadmap, grocery trips, scan loading và thời hạn realtime.
6. Kiểm thử thiết bị thật cho notification permission, background reminder, upload ảnh và thời gian chờ AI.
