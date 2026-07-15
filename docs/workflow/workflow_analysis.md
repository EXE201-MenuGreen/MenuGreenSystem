# 🥗 Sơ đồ Quy trình Nghiệp vụ MenuGreen (Workflows Analysis)

Tài liệu này tổng hợp phân tích các luồng hoạt động chính trong hệ thống dinh dưỡng cá nhân hóa **MenuGreen** dựa trên tài liệu nghiệp vụ gốc trong dự án.

---

## 👥 Tổng quan 4 Vai trò & Quy trình chính

### 1. Luồng Người dùng (User / Student Workflow)
* **Đăng ký & OTP**: Sử dụng OTP gửi qua Email để xác thực tài khoản hoặc đăng nhập Google qua Firebase Auth.
* **Onboarding (5 bước)**: Thiết lập thông tin cá nhân -> Mục tiêu -> Tính toán Calo/Macros tự động theo TDEE -> Gắn thẻ dị ứng -> Chọn nhóm hành vi (A - Đơn giản, B - Theo dõi, C - Thể hình).
* **Nhật ký hàng ngày**: Ghi chép bữa ăn (thủ công, tìm kiếm hoặc chụp ảnh quét AI qua camera) và cân nặng.
* **Thực đơn đã lưu (Meal Templates)**: Lưu bữa ăn lặp lại quen thuộc (Sáng/Trưa/Tối/Phụ) gồm nhiều món để ghi nhanh vào nhật ký. Hỗ trợ nhân bản và ghi đè khối lượng.
* **Nhắc nhở thông minh thích ứng (Adaptive Reminders)**: Tự động tính toán giờ ăn tối ưu dựa trên meal log, chỉnh sửa thủ công và đặt lịch nhắc nhở scheduled/snooze.
* **Lên thực đơn (Premium)**: Lập thực đơn tự động tránh các món dị ứng, kiểm soát ngân sách, đề xuất nguyên liệu thay thế và quy đổi portion.
* **Chương trình Lộ trình tuần Premium (Premium Programs)**: Các chương trình rèn luyện dài hạn có lộ trình theo tuần, check-in weight/body fat định kỳ, milestones và tốt nghiệp nhận báo cáo tổng hợp.
* **Thanh toán Premium**: Tự động hóa qua SePay với mã QR Code động. Giao dịch khớp mã nội dung chuyển khoản qua Webhook để nâng cấp Premium ngay lập tức.

### 2. Luồng Huấn luyện viên (In-App Coach Workflow)
* **Đăng ký Coach**: Điền thông tin Chuyên môn (Specialty), Giá tư vấn hàng tháng và Bio kinh nghiệm để hệ thống cấp quyền.
* **Quản lý Học viên**: Xuất hiện trên danh mục công cộng, nhận và phê duyệt kết nối từ Học viên.
* **Coach Dashboard**: Xem nhật ký ăn uống 7 ngày, mục tiêu dinh dưỡng và cân nặng học viên (nếu học viên cấp quyền xem dữ liệu).
* **Hành động can thiệp**: Gửi phản hồi nhận xét dinh dưỡng, điều chỉnh thực đơn tuần của học viên, thay đổi chỉ tiêu calo hàng ngày.

### 3. Luồng PT bên ngoài (Guest PT Review Workflow)
* **Một lần duy nhất (Không cần đăng nhập)**: Học viên tạo liên kết chia sẻ bảo mật chứa Token hết hạn gửi cho PT qua chat.
* **Đánh giá trên Web**: PT truy cập link trên trình duyệt web, xem báo cáo 7 ngày và gửi nhận xét cùng chỉ số calo/macro đề xuất mới.
* **Học viên duyệt**: Học viên nhận push notification, xem nhận xét và chọn **Apply** (Mục tiêu sức khỏe tự động cập nhật) hoặc **Reject** (Hủy bỏ).

### 4. Luồng Quản trị viên (Admin Workflow)
* **Tài khoản**: Xem danh sách, Khóa/Mở khóa tài khoản, phân quyền Coach/Admin.
* **Dữ liệu master**: Phê duyệt món ăn đề xuất (`IsVerified = true`), gắn thẻ dị ứng, và cấu hình ma trận thay thế nguyên liệu.
* **Quản trị Micro-Learning**: CRUD các thẻ kiến thức dinh dưỡng cá nhân hóa, biên soạn quiz trắc nghiệm đính kèm và cấu hình điểm thưởng khi hoàn thành.
* **Tài chính**: Quản lý gói cước dịch vụ và đối soát thủ công các giao dịch SePay bị lỗi chuyển khoản sai cú pháp.
* **Trợ lý AI**: Làm sạch dữ liệu crawler thức ăn, kiểm duyệt lịch sử chat bị Dislike và curate dữ liệu huấn luyện tinh chỉnh AI.

---

## 🛠️ Công nghệ tích hợp
* **Backend**: ASP.NET Core API phục vụ nghiệp vụ chính + Python FastAPI xử lý nhận diện đĩa ăn (Food CV).
* **Frontend**: Flutter Mobile App đa nền tảng.
* **Cổng thanh toán**: SePay API + Bank Webhook.
* **Trợ lý AI**: Gemini API (LLM & Multimodal Vision) + Function Calling để tự động tạo log món ăn / plan qua hội thoại.
