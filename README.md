# MenuGreen System 🥗🔋

Ứng dụng dinh dưỡng cá nhân hóa dành cho thị trường Việt Nam, hỗ trợ theo dõi sức khỏe, quản lý nguyên liệu, gợi ý món ăn theo ngân sách và mục tiêu fitness, đồng thời hướng đến triển khai lên Google Play (CH Play).

---

## 📌 Tính năng nổi bật

- **Quản lý hồ sơ & onboarding:** Đăng ký/đăng nhập email hoặc Google, OTP xác thực, onboarding 5 bước (thông tin cơ bản, sức khỏe, mục tiêu, dị ứng, hồ sơ AI).
- **Khám phá & gợi ý an toàn:** Tìm món ăn/công thức/nguy liệu, lọc theo calo, đạm, giá, loại trừ dị ứng, gợi ý rule-based an toàn.
- **Theo dõi dinh dưỡng:** Ghi nhật ký bữa ăn, dashboard calo/macro ngày/tuần/tháng, cảnh báo lệch mục tiêu, theo dõi cân nặng.
- **Kế hoạch bữa ăn:** Tạo/sao chép/sửa thực đơn theo ngày, chuyển plan thành log, so sánh thực tế vs kế hoạch, streak.
- **Gói dịch vụ & thanh toán:** Xem gói, đăng ký/gia hạn/hủy, tích hợp thanh toán SePay.
- **Trợ lý AI & thông báo:** Chat AI tư vấn dinh dưỡng, nhắc nhở chuẩn bị nguyên liệu/bữa ăn, hộp thư thông báo.

---

## 🏗️ Kiến trúc hệ thống

Hệ thống gồm 2 phần chính:

### Backend — N-Tier (.NET 9)

- **API Layer (`MenuGreen.API`):** ASP.NET Core Web API, JWT Auth, Swagger, CORS.
- **Business Logic Layer (`MenuGreen.BusinessLogicLayer`):** Services, validators, DTOs, công thức dinh dưỡng, rule-based recommendation, AI assistant logic.
- **Data Access Layer (`MenuGreen.DataAccessLayer`):** EF Core 9 + PostgreSQL, Repository/UnitOfWork, Fluent Configurations.

Luồng xử lý:
1. Controller nhận HTTP request.
2. Gọi service ở Business Logic Layer.
3. Service dùng Repository/UnitOfWork truy cập DbContext.
4. Trả về DTO/response cho client.

### Frontend — Flutter

- Cross-platform mobile app (Android / iOS).
- Quản lý trạng thái: `provider`.
- UI theo feature folder structure, phân biệt rõ models / providers / repositories / views / widgets.
- Tích hợp Firebase: Auth, Storage, Messaging.
- Giao tiếp backend qua `ApiClient` + `ApiEndpoints`, hỗ trợ override base URL bằng `--dart-define=API_BASE_URL=...`.

---

## 🛠️ Công nghệ chính

| Vùng | Công nghệ |
|------|-----------|
| Backend | C# 13, .NET 9, ASP.NET Core Web API |
| Database | PostgreSQL, EF Core 9, Npgsql |
| Auth & Security | JWT Bearer, BCrypt.Net, Firebase Admin (Google sign-in) |
| Frontend | Flutter, Dart |
| State Management | Provider |
| Firebase | Auth, Storage, Messaging |
| Charts | fl_chart |
| Payment | SePay (QR + Webhook) |
| Cache | Redis (nếu có) / In-memory fallback |

---

## 📂 Cấu trúc thư mục

```
MenuGreenSystem/
├── backend/
│   ├── MenuGreen.API/                 # Entrypoint API, Controllers, Program.cs
│   ├── MenuGreen.BusinessLogicLayer/  # Services, DTOs, Interfaces
│   ├── MenuGreen.DataAccessLayer/     # DbContext, Entities, Repositories, Configurations
│   ├── database/                      # SQL seed data
│   ├── MenuGreen.sln
│   └── run_seed_data.ps1
├── docs/
│   ├── 01-deployment/                 # Tài liệu triển khai
│   ├── 02-ops/                        # Vận hành & CI/CD
│   ├── 03-backend/                    # Tài liệu backend
│   ├── lightsail-setup.md
│   ├── NUTRITION_CALCULATIONS_README.md
│   ├── README_AI_FEATURES_API.md
│   ├── README_BACKEND_OVERVIEW.md     # Tổng quan backend chi tiết
│   ├── README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md
│   ├── README_USER_WORKFLOW.md
│   └── README_WORKFLOW_API_STATUS.md
├── frontend/
│   ├── lib/
│   │   ├── core/                      # Network, theme, utils, i18n
│   │   ├── features/                  # Mỗi feature: auth, onboarding, discover, tracking, meal_plan, subscription, ai_assistant...
│   │   └── main.dart / app.dart
│   ├── android/, ios/, windows/, macos/, linux/
│   └── README.md                      # Hướng dẫn chạy Flutter
├── frontend-web/                      # Next.js web app
├── monitoring/                        # Prometheus, Grafana, Alertmanager
├── scripts/                           # Scripts triển khai, ops, utilities
├── firebase/                          # Firebase rules
├── docker-compose.yml           # Local dev (postgres + api + nginx) — backend/docker-compose.yml
├── docker-compose.prod.yml      # Production (api only) — SCP'd by CD workflow
├── Dockerfile
├── .env.example
├── .env.production.example
└── README.md                          # Tài liệu dự án này
```

---

## 🚀 Setup & chạy dự án

### 1. Prerequisites

- [.NET 9.0 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [PostgreSQL](https://www.postgresql.org/download/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (đã thêm platform: android/ios/windows)
- PowerShell 5.1+ (để chạy script seed data)
- Git

### 2. Clone repository

```bash
git clone https://github.com/your-org/MenuGreenSystem.git
cd MenuGreenSystem
```

### 3. Setup Backend

#### 3.1 Cấu hình connection string

Mở `backend/MenuGreen.API/appsettings.Development.json` và `backend/MenuGreen.API/appsettings.json`, cập nhật `ConnectionStrings:DefaultConnection` cho môi trường local.

#### 3.2 Chạy migration

```bash
cd backend
dotnet tool install --global dotnet-ef
dotnet ef database update --project MenuGreen.DataAccessLayer --startup-project MenuGreen.API
```

#### 3.3 Seed data (tuỳ chọn)

Script PowerShell sẽ tự động kiểm tra/ tạo database rồi import các file SQL seed:

```powershell
cd backend
PowerShell -ExecutionPolicy Bypass -File .\run_seed_data.ps1
```

Trong script, chọn:
- `1`: import vào Docker container `menugreen_db`
- `2`: import vào PostgreSQL local (tự tạo DB `MenuGreenDb` nếu chưa có)
- `3`: gộp 55 file SQL thành `combined_seed_data.sql` để import thủ công

#### 3.4 Chạy API

```bash
cd backend
dotnet run --project MenuGreen.API
```

Swagger UI: `http://localhost:5000/swagger`

### 4. Setup Flutter Frontend

#### 4.1 Cài dependencies

```bash
cd frontend
flutter pub get
```

#### 4.2 Chạy app

```bash
# Windows
flutter run -d windows

# Android emulator
flutter run -d emulator-5554

# iOS simulator
flutter run -d iPhone 15

# Chỉ build
flutter build apk   # Android
flutter build ios   # iOS
```

#### 4.3 Cấu hình base URL API

Frontend đọc `API_BASE_URL` từ build-time define. Nếu không set, sẽ dùng giá trị mặc định trong code.

```bash
# Ví dụ: trỏ về backend local (Android emulator dùng 10.0.2.2)
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5000/api

# iOS simulator / Windows
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5000/api
```

Production API hiện tại: `https://menugreensystem.onrender.com/api`

---

## 📚 Tài liệu liên quan

| File | Nội dung |
|------|----------|
| `docs/README_BACKEND_OVERVIEW.md` | Kiến trúc backend, entities, security, sample API |
| `docs/README_USER_WORKFLOW.md` | Chi tiết hành trình người dùng end-to-end |
| `docs/README_WORKFLOW_API_STATUS.md` | Trạng thái từng workflow: API + UI đã làm / còn thiếu |
| `docs/README_SYSTEM_WORKFLOWS_AND_FEATURE_IDEAS.md` | Ý tưởng hệ thống và roadmap tính năng |
| `frontend/README.md` | Hướng dẫn build/run Flutter |

---

## 🗺️ Trạng thái triển khai

Dự án đang trong giai đoạn phát triển chức năng cốt lõi và chuẩn bị cho CH Play. Các luồng chính hiện đã có backend API và phần lớn đã có UI Flutter tương ứng.

| Nhóm | Trạng thái |
|------|-----------|
| Auth, Onboarding, Profile, Health, Allergy | ✅ API + UI |
| Khám phá món ăn / công thức / nguyên liệu | ✅ API + UI |
| Gợi ý an toàn & Recommendation | 🟡 API sẵn, UI đang bổ sung |
| Nutrition Tracking + Weight Tracking | ✅ API + UI |
| Meal Plan | ✅ API + UI |
| Subscription & SePay | ✅ API + UI |
| Notification | ✅ API + UI |
| AI Assistant | 🟡 API sẵn, chat UI đang kết nối |
| Safety / Compliance / Vietnam-first nutrition | 🟡 API có, UI chưa phủ |

---

## 🧪 Test

```bash
# Backend
cd backend
dotnet test

# Flutter
cd frontend
flutter analyze
flutter test
```

---

## 📝 Convention nhanh

- Backend: comment/biến/log viết **tiếng Anh**; message trả về client cũng dùng **tiếng Anh**.
- Flutter UI: nút, label, empty state, dialog viết **tiếng Việt**; dịch message API qua `ApiMessageTranslator` / `localizeAuthMessage`.
- Flutter: tuân thủ `const` constructor, `ListView.builder` + `ValueKey`, dispose controllers, dùng `mounted` trước dùng `context` sau async.
- Commit message: nên có tiền tố rõ ràng (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).

---

## ⚠️ Lưu ý vận hành

- CORS đang mở AllowAll cho môi trường phát triển; cần siết chặt khi lên production.
- JWT secret, Firebase credential, database URL phải để trong environment variables / user secrets, **không commit**.
- Redis không bắt buộc; hệ thống tự fallback về in-memory cache nếu không cấu hình.

---

## 🤝 Đóng góp

1. Fork repository.
2. Tạo branch feature (`git checkout -b feature/ten-tinh-nang`).
3. Commit thay đổi (`git commit -m "feat: mo ta ngan gon"`).
4. Push và tạo Pull Request.

---

## 📄 License

MIT
