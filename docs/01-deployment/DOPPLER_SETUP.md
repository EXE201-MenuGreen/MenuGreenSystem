# Doppler Setup — MenuGreen System

Log tiến độ và hướng dẫn dùng Doppler trong dự án này.

---

## Trạng thái hiện tại

| # | Hành động | Trạng thái |
|---|-----------|------------|
| 1 | Tạo project Doppler `menugreen` | ✅ |
| 2 | Thêm secrets vào config `prd` (Production) | ✅ |
| 3 | Thêm secrets vào config `dev` (Local development) | ✅ |
| 4 | Tạo Service Token cho config `prd` (Read-only) | ✅ |
| 5 | Thêm `DOPPLER_TOKEN` vào GitHub Secrets | ✅ |
| 6 | Cập nhật `.github/workflows/ci-cd.yml` để dùng Doppler | ✅ |
| 7 | Push code lên GitHub để chạy workflow thật | ⬜ |
| 8 | Xác minh deploy thành công | ⬜ |

---

## Cấu trúc Doppler Project

```
Project: menugreen
├── Config: prd   (Production) — secrets dùng cho CI/CD + server Lightsail
└── Config: dev   (Development) — secrets dùng cho chạy local
```

### Secrets trong config `prd`

| Secret | Mục đích |
|--------|----------|
| `DB_HOST` | Endpoint RDS PostgreSQL |
| `DB_PORT` | `5432` |
| `DB_NAME` | `MenuGreenDb` |
| `DB_USER` | `postgres` |
| `DB_PASSWORD` | Password RDS |
| `DB_SSL_MODE` | `Require` |
| `REDIS_HOST` | Host Redis |
| `REDIS_PORT` | `6379` |
| `REDIS_PASSWORD` | Password Redis |
| `JWT_SECRET` | Random key cho JWT |
| `JWT_ISSUER` | `MenuGreenAPI` |
| `JWT_AUDIENCE` | `MenuGreenApp` |
| `LIGHTSAIL_HOST` | IP Lightsail server |
| `LIGHTSAIL_USER` | `ubuntu` |
| `LIGHTSAIL_SSH_KEY` | Nội dung file `.pem` |

### Secrets trong config `dev`

| Secret | Giá trị gợi ý |
|--------|---------------|
| `DB_HOST` | `localhost` |
| `DB_PORT` | `5432` |
| `DB_NAME` | `MenuGreenDb` |
| `DB_USER` | `postgres` |
| `DB_PASSWORD` | `12345` |
| `DB_SSL_MODE` | `Prefer` |
| `REDIS_HOST` | `localhost` |
| `REDIS_PORT` | `6379` |
| `REDIS_PASSWORD` | (để trống nếu Redis local không có password) |
| `JWT_SECRET` | (random key) |
| `JWT_ISSUER` | `MenuGreenAPI` |
| `JWT_AUDIENCE` | `MenuGreenApp` |
| `LIGHTSAIL_HOST` | `localhost` (placeholder) |
| `LIGHTSAIL_USER` | `ubuntu` (placeholder) |
| `LIGHTSAIL_SSH_KEY` | `dummy` (placeholder) |

---

## Luồng hoạt động CI/CD

```
GitHub Actions
       │
       ├─ Đọc DOPPLER_TOKEN từ GitHub Secrets
       │
       ▼
Doppler API (project menugreen, config prd)
       │
       └─ Trả về secrets: DB_HOST, JWT_SECRET, ...
       │
       ▼
appleboy/ssh-action inject env vars → Server Lightsail
       │
       └─ Script tạo .env từ Doppler secrets
          └─ docker run --env-file .env menugreen-api
```

---

## Dùng Doppler cho Local Development

### Cài Doppler CLI

```bash
# macOS
brew install dopplerhq/cli/doppler

# Windows (PowerShell)
scoop install doppler

# Linux
curl -Ls https://cli.doppler.com/install.sh | sh
```

### Liên kết project

```bash
cd d:\University\Term8\EXE201\MenuGreenSystem\backend
doppler login
doppler setup
# Chọn project: menugreen
# Chọn config: dev
```

### Chạy API với Doppler

```bash
doppler run -- dotnet run --project MenuGreen.API
```

### Kiểm tra secrets đã inject

```bash
doppler run -- printenv | grep DB_
```

---

## File đã sửa

| File | Thay đổi |
|------|----------|
| `.github/workflows/ci-cd.yml` | Thêm bước `Setup Doppler CLI`, cập nhật `.env` từ Doppler secrets |

### Thay đổi chính trong `ci-cd.yml`

- Thêm step `Setup Doppler CLI` trước khi deploy
- `envs:` giờ bao gồm tất cả secrets từ Doppler: `DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, DB_SSL_MODE, REDIS_HOST, REDIS_PORT, REDIS_PASSWORD, JWT_SECRET, JWT_ISSUER, JWT_AUDIENCE`
- Script SSH tạo `.env` với format `ConnectionStrings__DefaultConnection` và `JwtSettings__*` khớp với `appsettings.json`

---

## Lưu ý bảo mật

- **Không commit file `.env`** vào Git
- **GitHub Secrets** chỉ chứa `DOPPLER_TOKEN` và `LIGHTSAIL_*` (SSH)
- **Doppler dashboard** là nơi quản lý tất cả secrets ứng dụng
- Service Token chỉ có quyền **Read** config `prd` (least privilege)

---

## Troubleshooting

| Lỗi | Nguyên nhân | Cách fix |
|-----|-------------|----------|
| Doppler token expired/invalid | Secret `DOPPLER_TOKEN` sai | Tạo lại Service Token trong Doppler |
| Missing Doppler secret | Config `prd` thiếu key | Thêm key còn thiếu vào Doppler config `prd` |
| SSH fail | `LIGHTSAIL_*` secrets sai | Kiểm tra lại GitHub Secrets |
| RDS SSL error | `DB_SSL_MODE` sai | Đảm bảo config `prd` có `DB_SSL_MODE=Require` |
| JWT không nhận diện | `JWT_SECRET` thiếu hoặc sai key | Kiểm tra secret trong Doppler config `prd` |

---

## Tiến độ tiếp theo

- [ ] Push code và chạy GitHub Actions workflow
- [ ] Kiểm tra health endpoint sau deploy
- [ ] (Tuỳ chọn) Xóa các GitHub Secrets cũ: `DB_*`, `JWT_SECRET` sau khi Doppler chạy ổn

---

_Cập nhật lần cuối: 30/06/2026_

---

## Log công việc đã làm

### 2026-06-30: Import secrets vào Doppler config `prd`

| Hành động | Trạng thái |
|-----------|-----------|
| Tạo file `.env` tổng hợp tất cả secrets Production | ✅ |
| Import secrets vào Doppler config `prd` qua Web UI | ✅ |
| Kiểm tra keys đã import đúng (JWT, Resend, SePay, Firebase, Redis, DB, CVService, NutritionAssistant) | ✅ |

**Secrets đã import gồm:**
- `JWTSETTINGS__SECRETKEY`, `JWTSETTINGS__ISSUER`, `JWTSETTINGS__AUDIENCE`, `JWTSETTINGS__EXPIRYMINUTES`
- `RESEND__APIKEY`, `RESEND__FROMEMAIL`, `RESEND__FROMNAME`
- `SEPAY__WEBHOOKSECRET`, `SEPAY__WEBHOOKAUTHMODE`, `SEPAY__WEBHOOKTIMESTAMPTOLERANCESECONDS`, `SEPAY__PAYMENTCODEPREFIX`, `SEPAY__PAYMENTCODESUFFIXLENGTH`, `SEPAY__PAYMENTCODESUFFIXMINLENGTH`, `SEPAY__PAYMENTCODESUFFIXMAXLENGTH`, `SEPAY__ORDEREXPIRYMINUTES`, `SEPAY__QRIMAGEBASEURL`
- `SEPAY__BANKACCOUNT__ACCOUNTNUMBER`, `SEPAY__BANKACCOUNT__BANKNAME`, `SEPAY__BANKACCOUNT__ACCOUNTHOLDERNAME`, `SEPAY__BANKACCOUNT__TRANSFERDESCRIPTIONPREFIX`
- `FIREBASE__CREDENTIALPATH`
- `REDIS__CONNECTIONSTRING`
- `ALLOWEDORIGINS`
- `CONNECTIONSTRINGS__DEFAULTCONNECTION`
- `CVSERVICE__BASEURL`, `CVSERVICE__APISECRETKEY`
- `NUTRITIONASSISTANT__WORKERURL`

**Format key đã chuẩn hóa:**
- Dùng `__` thay `:` cho nested keys (tương thích .NET + Doppler)
- Tất cả keys đều uppercase snake_case
