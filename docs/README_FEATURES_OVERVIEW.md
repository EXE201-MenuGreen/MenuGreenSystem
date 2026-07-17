# MenuGreen System — Tổng quan tính năng

> Document này tổng hợp các tính năng chính của ứng dụng MenuGreen một cách khái quát.

---

## Mục lục

1. [Tài khoản & Xác thực](#1-tài-khoản--xác-thực)
2. [Onboarding & Thiết lập hồ sơ](#2-onboarding--thiết-lập-hồ-sơ)
3. [Khám phá & Gợi ý](#3-khám-phá--gợi-ý)
4. [Theo dõi Dinh dưỡng](#4-theo-dõi-dinh-dưỡng)
5. [Kế hoạch Bữa ăn](#5-kế-hoạch-bữa-ăn)
6. [Gói Dịch vụ & Thanh toán](#6-gói-dịch-vụ--thanh-toán)
7. [AI Assistant](#7-ai-assistant)
8. [Thông báo & Nhắc nhở](#8-thông-báo--nhắc-nhở)
9. [Cộng đồng & Học tập](#9-cộng-đồng--học-tập)
10. [Tính năng Nâng cao](#10-tính-năng-nâng-cao)

---

## 1. Tài khoản & Xác thực

Người dùng có thể đăng ký và đăng nhập vào ứng dụng thông qua nhiều phương thức:

- **Đăng nhập Email/Password** — Đăng ký tài khoản mới hoặc đăng nhập bằng email và mật khẩu
- **Đăng nhập Google** — Sử dụng tài khoản Google để đăng nhập nhanh qua Firebase Authentication
- **Xác thực OTP** — Bảo mật tài khoản bằng mã OTP gửi qua email
- **Quản lý Profile** — Cập nhật thông tin cá nhân, hình đại diện

---

## 2. Onboarding & Thiết lập hồ sơ

Quy trình thiết lập hồ sơ giúp cá nhân hóa trải nghiệm cho người dùng mới:

- **Thông tin cơ bản** — Nhập tuổi, giới tính, chiều cao, cân nặng
- **Tình trạng sức khỏe** — Khai báo các vấn đề sức khỏe (tiểu đường, tim mạch,...)
- **Mục tiêu dinh dưỡng** — Chọn mục tiêu: giảm cân, tăng cơ, duy trì cân nặng
- **Dị ứng & kiêng kỵ** — Khai báo thực phẩm dị ứng hoặc kiêng ăn
- **Tùy chỉnh Vietnam** — Lựa chọn sở thích món ăn Việt, mục tiêu gym

---

## 3. Khám phá & Gợi ý

Khám phá công thức nấu ăn và nguyên liệu phù hợp với nhu cầu:

- **Khám phá công thức** — Tìm kiếm và duyệt các công thức nấu ăn
- **Khám phá nguyên liệu** — Tìm kiếm thông tin dinh dưỡng của từng nguyên liệu
- **Bộ lọc thông minh** — Lọc theo calo, đạm, giá tiền, thời gian nấu
- **Loại trừ dị ứng** — Tự động ẩn món ăn chứa nguyên liệu gây dị ứng
- **Gợi ý theo ngân sách** — Đề xuất món ăn phù hợp với ngân sách
- **Weekly Plan** — Gợi ý thực đơn theo tuần
- **Gợi ý an toàn** — Đề xuất dựa trên hồ sơ sức khỏe và mục tiêu

---

## 4. Theo dõi Dinh dưỡng

Theo dõi lượng thức ăn tiêu thụ hàng ngày và so sánh với mục tiêu:

- **Nhật ký bữa ăn** — Ghi lại bữa sáng, trưa, chiều, tối và snack
- **Dashboard dinh dưỡng** — Xem tổng quan calo và chất dinh dưỡng (đạm, carb, fat)
- **Theo dõi theo thời gian** — Xem biểu đồ dinh dưỡng theo ngày, tuần, tháng
- **Cảnh báo mục tiêu** — Nhận thông báo khi lượng calo vượt hoặc thiếu mục tiêu
- **Theo dõi cân nặng** — Ghi nhận và theo dõi sự thay đổi cân nặng
- **Quét/Scan thực phẩm** — Nhận diện món ăn qua hình ảnh (Computer Vision)

---

## 5. Kế hoạch Bữa ăn

Lập kế hoạch ăn uống trước và theo dõi việc thực hiện:

- **Tạo thực đơn** — Lên kế hoạch bữa ăn cho từng ngày
- **Sao chép/Sửa thực đơn** — Nhanh chóng tạo thực đơn mới từ mẫu có sẵn
- **Chuyển thành nhật ký** — Tự động chuyển kế hoạch thành bản ghi ăn uống thực tế
- **So sánh thực tế vs Kế hoạch** — Đánh giá mức độ tuân thủ thực đơn
- **Streak theo dõi** — Đếm số ngày liên tiếp hoàn thành kế hoạch
- **Meal Templates** — Sử dụng các mẫu thực đơn có sẵn

---

## 6. Gói Dịch vụ & Thanh toán

Hệ thống đăng ký và thanh toán để truy cập tính năng cao cấp:

- **Xem các gói dịch vụ** — Danh sách gói Premium/Free với quyền lợi khác nhau
- **Đăng ký gói** — Chọn và đăng ký gói phù hợp
- **Gia hạn tự động** — Tự động gia hạn khi hết hạn
- **Hủy gói** — Quản lý việc hủy đăng ký
- **Thanh toán SePay** — Tích hợp thanh toán qua mã QR SePay
- **Webhook xử lý** — Tự động xác nhận thanh toán qua webhook

---

## 7. AI Assistant

Trợ lý ảo AI hỗ trợ người dùng trong các câu hỏi về dinh dưỡng:

- **Chat với AI** — Đặt câu hỏi về dinh dưỡng, công thức nấu ăn
- **Tư vấn cá nhân hóa** — AI phân tích hồ sơ để đưa ra lời khuyên phù hợp
- **Gợi ý thông minh** — Đề xuất món ăn dựa trên sở thích và mục tiêu
- **Giải đáp thắc mắc** — Trả lời các câu hỏi về calo, chất dinh dưỡng

---

## 8. Thông báo & Nhắc nhở

Hệ thống thông báo giúp người dùng duy trì thói quen ăn uống lành mạnh:

- **Nhắc nhở bữa ăn** — Thông báo đến giờ ăn sáng/trưa/chiều/tối
- **Nhắc chuẩn bị nguyên liệu** — Nhắc chuẩn bị trước khi nấu
- **Nhắc uống nước** — Theo dõi lượng nước uống hàng ngày
- **Hộp thư thông báo** — Tập trung tất cả thông báo từ hệ thống
- **Cài đặt thông báo** — Tùy chỉnh loại và thời gian thông báo
- **Nhắc nhở thích ứng** — AI điều chỉnh lịch nhắc dựa trên hành vi người dùng

---

## 9. Cộng đồng & Học tập

Các tính năng về cộng đồng và giáo dục dinh dưỡng:

- **Micro Learning** — Bài học ngắn về dinh dưỡng, kiến thức sức khỏe
- **Safety Hub** — Trung tâm thông tin an toàn thực phẩm
- **Báo cáo vấn đề** — Cho phép người dùng báo cáo lỗi hoặc vấn đề

---

## 10. Tính năng Nâng cao

Các tính năng bổ sung cho trải nghiệm toàn diện hơn:

- **Thay thế nguyên liệu** — Gợi ý nguyên liệu thay thế khi thiếu
- **Tùy chỉnh Daily Starter** — Gợi ý bữa ăn đầu tiên trong ngày cá nhân hóa
- **Lucky Wheel** — Yếu tố gamification, quay vòng may mắn
- **Lịch sử hoạt động** — Xem lại lịch sử nhật ký và thực đơn
- **Điều chỉnh mục tiêu** — Cập nhật mục tiêu dinh dưỡng theo thời gian

---

## Tóm tắt

| Nhóm tính năng | Mô tả                                                   |
| -------------- | ------------------------------------------------------- |
| **Tài khoản**  | Đăng ký, đăng nhập, bảo mật OTP, quản lý profile        |
| **Onboarding** | Thiết lập hồ sơ, sức khỏe, dị ứng, mục tiêu             |
| **Khám phá**   | Tìm kiếm công thức, nguyên liệu, gợi ý thông minh       |
| **Theo dõi**   | Nhật ký bữa ăn, dashboard dinh dưỡng, theo dõi cân nặng |
| **Kế hoạch**   | Lập thực đơn, so sánh thực tế, streak theo dõi          |
| **Thanh toán** | Gói Premium, thanh toán SePay                           |
| **AI**         | Trợ lý chat, tư vấn dinh dưỡng                          |
| **Thông báo**  | Nhắc bữa ăn, nhắc nước, hộp thư                         |
| **Học tập**    | Micro learning, Safety Hub                              |
| **Nâng cao**   | Thay thế nguyên liệu, gamification                      |

---

_Document được tạo: 2026-07-17_
