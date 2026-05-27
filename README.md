# MenuGreen System 🥗🔋

Welcome to the **MenuGreen System** repository! This is a modern, enterprise-grade backend ecosystem designed to help users track nutrition, manage kitchen ingredients, and build custom meal plans optimized by budgets and fitness targets.

The backend is built using a robust **.NET 9 N-Tier Architecture** coupled with **Entity Framework Core (EF Core)** and **PostgreSQL**.

---

## 🏗️ Project Architecture

The solution `MenuGreen.sln` follows a clean, modular N-Tier layered architecture:

* **Presentation Layer (`MenuGreen.API`):** Handles client HTTP requests, API routing, and security.
* **Business Logic Layer (`MenuGreen.BusinessLogicLayer`):** Implements services, validators, DTO mappings, and calorie formulas.
* **Data Access Layer (`MenuGreen.DataAccessLayer`):** Manages DB connection states, entities, Fluent Configurations, and Repository/UnitOfWork patterns.

---

## 📋 Chức năng của hệ thống (System Features)

Hệ thống MenuGreen được phân chia rõ ràng thành các gói tính năng phục vụ các nhu cầu dinh dưỡng khác nhau của người dùng:

### 1. Tính năng cơ bản (Miễn phí)
* **Phân tích sức khỏe cá nhân:** Theo dõi sát sao tình trạng sức khỏe tổng quan của người dùng. Hệ thống sẽ tự động đưa ra các cảnh báo trực quan để người dùng tránh xa các món ăn có chứa các thành phần gây dị ứng đã thiết lập.
* **Gợi ý theo hàm lượng Calo:** Cho phép gợi ý các món ăn phù hợp dựa vào lượng calo mục tiêu mà người dùng nhập vào. Ngoài ra hệ thống hỗ trợ lọc phân loại thức ăn theo sở thích cụ thể (ví dụ: món canh, đồ khô).
* **Quản lý nguyên liệu:** Hỗ trợ người dùng quản lý tủ lạnh ảo bằng cách nhập các nguyên liệu hiện có sẵn tại nhà.
* **Lịch sử hoạt động:** Nhật ký lưu trữ lịch sử ăn uống hàng ngày và tổng hợp các hoạt động thể chất/nhật ký thói quen đã thực hiện.
* **Thông báo nhắc nhở:** Tích hợp hệ thống gửi thông báo nhắc nhở tự động từ ứng dụng di động để duy trì lối sống lành mạnh.

---

### 2. Tính năng tính phí (Premium)
> [!TIP]
> **Mức phí dự kiến:** 80.000 VNĐ / nhóm tính năng.

#### 🎡 Nhóm tính năng "Chưa biết ăn gì"
*Dành cho đối tượng người dùng muốn tối ưu hóa thời gian lựa chọn món ăn và quản lý tài chính cá nhân.*
* **Vòng quay thức ăn Eco-money:** Tự động đề xuất danh sách gồm 10 món ăn được chọn lọc kỹ lưỡng, đảm bảo đáp ứng tốt tiêu chí ngân sách (giá rẻ, tiết kiệm) và thời gian chuẩn bị/nấu nướng nhanh chóng.
* **Trò chuyện cùng AI:** Trợ lý ảo AI thông minh luôn sẵn sàng tư vấn thực đơn cá nhân, giải đáp các thắc mắc chi tiết về mặt dinh dưỡng và sức khỏe 24/7.

#### 💪 Nhóm tính năng dành cho Gymer
*Tập trung chuyên sâu vào cải thiện hình thể và tối ưu hiệu suất tập luyện.*
* **Phân tích dinh dưỡng chuyên sâu:** Tính toán chi tiết đến từng gram các chỉ số Calories tổng và tỷ lệ Macros (Đạm - Protein, Đường/Tinh bột - Carbs, Chất béo - Fat).
* **Lộ trình ăn uống cá nhân hóa:** Thiết lập kế hoạch ăn uống dài hạn dựa trên dữ liệu khảo sát thể trạng đầu vào của người dùng.
* **Gói đăng ký linh hoạt:** Hỗ trợ đăng ký linh động theo nhu cầu ngắn hạn hoặc dài hạn (gói 7 ngày theo tuần hoặc theo tháng).
* **Thực đơn tự động:** Dựa vào mục tiêu calo mỗi ngày để phân chia danh sách món ăn tối ưu cho từng bữa (Sáng, Trưa, Chiều, Tối). Người dùng có toàn quyền điều chỉnh tổng khối lượng calo và chủ động thay đổi món ăn linh hoạt theo khẩu vị.

#### 🏢 Nhóm tính năng dành cho Dân văn phòng
*Tối ưu hóa thời gian chuẩn bị và hỗ trợ duy trì năng lượng làm việc bền bỉ cho người làm việc trí óc.*
* **Kiểm soát dinh dưỡng đặc thù:** Theo dõi lượng Calo và Macros được đo đạc chuyên biệt, phù hợp với tính chất lối sống ít vận động hoặc làm việc văn phòng căng thẳng.
* **Lên lịch nấu nướng thông minh:** Hệ thống dựa vào quỹ thời gian rảnh thực tế của người dùng để gửi thông báo nhắc nhở chuẩn bị nguyên liệu và bắt đầu nấu nướng từ sớm.
* **Thực đơn gợi ý tiêu chuẩn:** Tập trung thiết kế thực đơn khoa học gồm **1 món sáng và 3 món trưa** (bao gồm 2 món chính đầy đủ dưỡng chất và 1 món tráng miệng nhẹ nhàng) để đảm bảo năng lượng dồi dào suốt ngày làm việc.

---

## 🛠️ Technology Stack

* **Language:** C# 13
* **Framework:** .NET 9.0 (ASP.NET Core Web API)
* **Database Provider:** EF Core with Npgsql (PostgreSQL provider)
* **Encryption & Security:** BCrypt.Net for password hashing, JWT for bearer tokens.

---

## 🚀 Setup & Execution

### 1. Prerequisites
* Install [.NET 9.0 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
* Install [PostgreSQL Database](https://www.postgresql.org/download/)

### 2. Database Migration Commands
Cập nhật hoặc khởi tạo cơ sở dữ liệu PostgreSQL từ Entity Model:
```bash
# Cài đặt EF CLI tool
dotnet tool install --global dotnet-ef

# Chuyển đến thư mục backend
cd backend

# Thực thi migration tạo database
dotnet ef database update --project MenuGreen.DataAccessLayer --startup-project MenuGreen.API
```

### 3. Running the Web API
Khởi chạy dự án API:
```bash
dotnet run --project MenuGreen.API
```
Sau khi chạy thành công, truy cập Swagger UI tại địa chỉ:
* `http://localhost:5000/swagger`