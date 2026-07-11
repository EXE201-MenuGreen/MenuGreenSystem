# Doppler Setup — MenuGreen System

> **Last updated:** 2026-07-11 — Phản ánh workflow thật trong `backend-cd.yml`.

---

## Trạng thái hiện tại

| # | Hành động                                                   | Trạng thái |
|---|-------------------------------------------------------------|------------|
| 1 | Tạo project Doppler `menugreen`                              | ✅         |
| 2 | Thêm secrets vào config `prd` (Production)                   | ✅         |
| 3 | Thêm secrets vào config `dev` (Local development)            | ✅         |
| 4 | Tạo Service Token cho config `prd` (Read-only)               | ✅         |
| 5 | Thêm `DOPPLER_TOKEN` vào GitHub Secrets                      | ✅         |
| 6 | Cập nhật `.github/workflows/backend-cd.yml` để dùng Doppler | ✅         |
| 7 | Push code + workflow chạy thật                               | ✅         |
| 8 | Deploy thành công từ CI/CD                                   | ✅         |

---

## Cấu trúc Doppler Project

```
Project: menugreen
├── Config: prd   (Production)  — secrets cho CI/CD + server Lightsail
└── Config: dev   (Development) — secrets cho chạy local
```

---

## Secrets trong config `prd`

### Database (cho backup script + backup dùng)

| Secret         | Mục đích                  |
|----------------|---------------------------|
| `DB_HOST`      | Endpoint RDS PostgreSQL   |
| `DB_PORT`      | `5432`                    |
| `DB_NAME`      | `menugreendb`             |
| `DB_USER`      | `postgres`                |
| `DB_PASSWORD`  | Password RDS              |
| `DB_SSL_MODE`  | `Require`                 |

### Redis (sẽ ghép thành `REDIS_URL` cho Program.cs)

| Secret           | Mục đích                       |
|------------------|--------------------------------|
| `REDIS_HOST`     | Host Redis (managed)           |
| `REDIS_PORT`     | `6379`                         |
| `REDIS_PASSWORD` | Password Redis                 |

### JWT (cho JwtSettings__*)

| Secret          | Mục đích                |
|-----------------|-------------------------|
| `JWT_SECRET`    | Random key cho JWT      |
| `JWT_ISSUER`    | `MenuGreenAPI`          |
| `JWT_AUDIENCE`  | `MenuGreenApp`          |

### SSH (chỉ để backup, không inject vào app)

| Secret              | Mục đích               |
|---------------------|------------------------|
| `LIGHTSAIL_HOST`    | IP Lightsail server    |
| `LIGHTSAIL_USER`    | `ubuntu`               |
| `LIGHTSAIL_SSH_KEY` | Nội dung file `.pem`   |

### Connection strings (cho app)

| Secret                                   | Mục đích                          |
|------------------------------------------|-----------------------------------|
| `CONNECTIONSTRINGS__DEFAULTCONNECTION`   | Full PostgreSQL connection string |
| `REDIS__CONNECTIONSTRING`                | Redis connection (alternative)    |

### Email (Resend)

| Secret                 | Mục đích            |
|------------------------|---------------------|
| `RESEND__APIKEY`       | Resend API key      |
| `RESEND__FROMEMAIL`    | Sender email        |
| `RESEND__FROMNAME`     | Sender display name |

### SePay (Payment)

| Secret                                            | Mục đích                  |
|---------------------------------------------------|---------------------------|
| `SEPAY__WEBHOOKSECRET`                            | Webhook signature secret  |
| `SEPAY__WEBHOOKAUTHMODE`                          | Auth mode                 |
| `SEPAY__WEBHOOKTIMESTAMPTOLERANCESECONDS`         | Timestamp tolerance       |
| `SEPAY__PAYMENTCODEPREFIX`                        | Payment code prefix       |
| `SEPAY__PAYMENTCODESUFFIXLENGTH`                  | Suffix length             |
| `SEPAY__PAYMENTCODESUFFIXMINLENGTH`               | Min suffix length         |
| `SEPAY__PAYMENTCODESUFFIXMAXLENGTH`               | Max suffix length         |
| `SEPAY__ORDEREXPIRYMINUTES`                       | Order expiry              |
| `SEPAY__QRIMAGEBASEURL`                           | QR image base URL         |
| `SEPAY__BANKACCOUNT__ACCOUNTNUMBER`               | Bank account number       |
| `SEPAY__BANKACCOUNT__BANKNAME`                    | Bank name                 |
| `SEPAY__BANKACCOUNT__ACCOUNTHOLDERNAME`           | Account holder            |
| `SEPAY__BANKACCOUNT__TRANSFERDESCRIPTIONPREFIX`    | Transfer description prefix |

### Firebase (FCM)

| Secret                      | Mục đích                    |
|-----------------------------|-----------------------------|
| `FIREBASE__CREDENTIALPATH`  | Path tới Firebase cred file |

### Other services

| Secret                              | Mục đích                       |
|-------------------------------------|--------------------------------|
| `CVSERVICE__BASEURL`                | Computer Vision microservice   |
| `CVSERVICE__APISECRETKEY`           | CV service API key             |
| `NUTRITIONASSISTANT__WORKERURL`     | Nutrition AI worker URL        |
| `ALLOWEDORIGINS`                    | CORS whitelist origins         |
| `JWTSETTINGS__SECRETKEY`            | Alternative JWT secret key     |
| `JWTSETTINGS__ISSUER`               | Alternative issuer             |
| `JWTSETTINGS__AUDIENCE`             | Alternative audience           |
| `JWTSETTINGS__EXPIRYMINUTES`        | Token expiry                   |

> **Luồng CI/CD + chi tiết script build `.env`:** xem [CI_CD.md](./CI_CD.md#workflow-files-chi-tiết).

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
cd MenuGreenSystem/backend
doppler login
doppler setup
# Chọn project: menugreen
# Chọn config: dev
```

### Chạy API với Doppler

```bash
cd MenuGreenSystem/backend
doppler run -- dotnet run --project MenuGreen.API
```

### Chạy docker-compose với Doppler

```bash
# Cách 1: inject env vào .env rồi docker compose up
doppler secrets download --no-file --format env > .env
docker compose up -d

# Cách 2: dùng doppler run với env_file
# (cần custom script vì env_file đọc từ file, không nhận trực tiếp env vars)
```

### Kiểm tra secrets đã inject

```bash
doppler run -- printenv | grep DB_
```

---

## File đã sửa (chỉ để tham khảo)

| File                                       | Thay đổi                                                       |
|--------------------------------------------|----------------------------------------------------------------|
| `.github/workflows/backend-cd.yml`         | Dùng Doppler CLI để download secrets → build `.env` trên server |
| `.github/workflows/backend-ci.yml`         | Build + push Docker image, không cần Doppler                    |

---

## Lưu ý bảo mật

- **Không commit file `.env`** vào Git (đã có `.gitignore`).
- **GitHub Secrets chỉ chứa `DOPPLER_TOKEN`**, `LIGHTSAIL_*` (SSH), `DOCKERHUB_*`.
- **Doppler dashboard** là nơi quản lý tất cả secrets ứng dụng (single source of truth).
- Service Token Doppler chỉ có quyền **Read** config `prd` (least privilege).
- Khi rotate secret: chỉ cần update trong Doppler, CD workflow pull secret mới ở deploy kế tiếp.

---

## Troubleshooting

| Lỗi                          | Nguyên nhân                              | Cách fix                                       |
|------------------------------|------------------------------------------|------------------------------------------------|
| Doppler token expired/invalid| Secret `DOPPLER_TOKEN` sai/expired       | Tạo lại Service Token trong Doppler dashboard  |
| Missing Doppler secret       | Config `prd` thiếu key                   | Thêm key còn thiếu vào Doppler config `prd`    |
| SSH fail                     | `LIGHTSAIL_*` secrets sai                | Kiểm tra lại GitHub Secrets                    |
| RDS SSL error                | `DB_SSL_MODE` sai                        | Đảm bảo config `prd` có `DB_SSL_MODE=Require`  |
| JWT không nhận diện          | `JWT_SECRET` thiếu hoặc sai key          | Kiểm tra secret trong Doppler config `prd`     |
| `REDIS_URL` format sai       | Thiếu `REDIS_HOST`/`REDIS_PORT`/`REDIS_PASSWORD` | Verify cả 3 secrets có trong Doppler   |

### Test Doppler CLI thủ công

```bash
# Test download secrets
DOPPLER_TOKEN=dp.prd.xxx \
  doppler secrets download \
    --no-file \
    --project menugreen \
    --config prd \
    --format env
```

---

## Tiến độ tiếp theo

- [✅] Push code và chạy GitHub Actions workflow thật
- [✅] Health endpoint OK sau deploy
- [x] (Tùy chọn) Xóa GitHub Secrets cũ `DB_*`, `JWT_SECRET` (đã làm — chỉ giữ `DOPPLER_TOKEN`)
- [ ] (Tương lai) Thêm Doppler config `stg` cho staging environment

---

## Log công việc đã làm

### 2026-06-30: Import secrets vào Doppler config `prd`

- Tạo file `.env` tổng hợp tất cả secrets Production ✅
- Import vào Doppler config `prd` qua Web UI ✅
- Verify các keys: JWT, Resend, SePay, Firebase, Redis, DB, CVService, NutritionAssistant ✅

**Format key đã chuẩn hóa:**
- Dùng `__` thay `:` cho nested keys (tương thích .NET + Doppler)
- Tất cả keys uppercase snake_case

### 2026-07-01: CI/CD fix — Doppler secrets flow đúng

- **Fix 1:** Trước đó `.env` server thiếu `JwtSettings__SecretKey`, `Issuer`, `Audience` → fix bằng cách explicit build từ Doppler secrets ✅
- **Fix 2:** Trước đó `ConnectionStrings__Redis` sai format → đổi sang `REDIS_URL` env (đúng format Program.cs đọc) ✅
- **Fix 3:** Đổi từ `ci-cd.yml` (cũ, chạy efbundle) sang `backend-ci.yml` + `backend-cd.yml` (tách CI/CD) ✅

### 2026-07-11: Workflow tự động hoạt động ổn định

- Backup DB tự động trước khi deploy ✅
- Auto-rollback nếu health check fail ✅
- Doppler secrets tự động inject đúng format ✅
