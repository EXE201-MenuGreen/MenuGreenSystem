# Doppler Setup — MenuGreen System

> **Last updated:** 2026-07-12 — Phản ánh workflow thật trong `backend-cd.yml`.
>
> **Đã sửa:** Bỏ `LIGHTSAIL_*` khỏi Doppler (chỉ ở GitHub Secrets), bổ sung ghi chú về format env (`Foo__Bar` vs `Foo:Bar`), chỉnh sửa mapping JWT key.

---

## Trạng thái hiện tại

| # | Hành động                                                   | Trạng thái |
|---|-------------------------------------------------------------|------------|
| 1 | Tạo project Doppler `menugreen`                              | ✅         |
| 2 | Thêm secrets vào config `prd` (Production)                   | ✅         |
| 3 | Thêm secrets vào config `dev` (Local development)            | ✅         |
| 4 | Tạo Service Token cho config `prd` (Read-only)               | ✅         |
| 5 | Thêm `DOPPLER_TOKEN` vào GitHub Secrets                      | ✅         |
| 6 | CD workflow dùng Doppler CLI để download secrets → build `.env` | ✅         |
| 7 | Deploy thành công từ CI/CD                                   | ✅         |

---

## Cấu trúc Doppler Project

```
Project: menugreen
├── Config: prd   (Production)  — secrets cho CI/CD + server Lightsail
└── Config: dev   (Development) — secrets cho chạy local
```

---

## Cách secrets được inject vào container

CD script (`backend/scripts/deploy-server.sh`) chạy trên server:

```bash
doppler secrets download --token "$DOPPLER_TOKEN" \
  --no-file --project menugreen --config prd --format env \
  > /tmp/doppler_raw.env
```

Rồi parse từng dòng `KEY=VALUE`, ghi vào `$APP_DIR/.env` theo format .NET:

| Doppler secret        | Trong `.env`              | Đọc bởi                                         |
|-----------------------|---------------------------|--------------------------------------------------|
| `CONNECTIONSTRINGS__DEFAULTCONNECTION` | `ConnectionStrings__DefaultConnection=...` | `ConnectionStringHelper.ResolvePostgresConnectionString` |
| `REDIS__CONNECTIONSTRING`             | `Redis__ConnectionString=...`              | `Program.cs` (`builder.Configuration["Redis:ConnectionString"]`) |
| `REDIS_HOST` / `REDIS_PORT` / `REDIS_PASSWORD` | Ghép thành `REDIS_URL=host:port,password=...` | `Program.cs` (fallback env)         |
| `JWT_SECRET`                          | `JwtSettings__SecretKey=...`               | `Program.cs` JWT config                            |
| `JWT_ISSUER`                          | `JwtSettings__Issuer=...`                  | JWT config                                         |
| `JWT_AUDIENCE`                        | `JwtSettings__Audience=...`                | JWT config                                         |
| `JWTSETTINGS__SECRETKEY` (alt)        | `JwtSettings__SecretKey=...`               | JWT config                                         |
| `ALLOWEDORIGINS`                      | `ALLOWEDORIGINS=...` (giữ nguyên)          | `Program.cs` (`builder.Configuration["AllowedOrigins"]`) |
| Bất kỳ `Foo__Bar=value`               | `Foo__Bar=value`                           | .NET config binding                                |
| Bất kỳ `Foo:Bar=value`                | `Foo__Bar=value` (script đổi `:` → `__`)   | .NET config binding                                |
| `LIGHTSAIL_SSH_KEY=...`               | **BỊ SKIP** — không inject vào `.env`      | (chỉ dùng cho SSH từ GH Actions runner)           |

> **Lưu ý về format:**
> - Doppler khuyến nghị dùng `:` cho nested key (`JWT:SecretKey`), nhưng .NET đọc cả `:` lẫn `__`. Script ưu tiên giữ `__` nếu key đã có sẵn, fallback convert `:` → `__` cho key dạng cũ.
> - Doppler sometimes wrap value trong quotes (`"value"` hoặc `""value""`); script strip hết layer quotes trước khi ghi `.env` (fix bug 5432 → "5432" gây `pg_dump` fail).

---

## Secrets trong config `prd`

### Database (cho backup script)

| Secret         | Mục đích                  |
|----------------|---------------------------|
| `DB_HOST`      | Endpoint RDS PostgreSQL   |
| `DB_PORT`      | `5432`                    |
| `DB_NAME`      | `menugreendb`             |
| `DB_USER`      | `postgres`                |
| `DB_PASSWORD`  | Password RDS              |
| `DB_SSL_MODE`  | `Require`                 |

### Redis (ghép thành `REDIS_URL`)

| Secret           | Mục đích                       |
|------------------|--------------------------------|
| `REDIS_HOST`     | Host Redis (managed)           |
| `REDIS_PORT`     | `6379`                         |
| `REDIS_PASSWORD` | Password Redis                 |

### JWT

| Secret                                  | Mục đích                                |
|-----------------------------------------|-----------------------------------------|
| `JWT_SECRET`                            | Random key cho JWT (ưu tiên)            |
| `JWT_ISSUER`                            | `MenuGreenAPI`                          |
| `JWT_AUDIENCE`                          | `MenuGreenApp`                          |
| `JWTSETTINGS__SECRETKEY` *(alternative)*| Secret key nếu không dùng `JWT_SECRET`  |
| `JWTSETTINGS__ISSUER` *(alt)*           | Issuer nếu không dùng `JWT_ISSUER`      |
| `JWTSETTINGS__AUDIENCE` *(alt)*         | Audience nếu không dùng `JWT_AUDIENCE`  |
| `JWTSETTINGS__EXPIRYMINUTES`            | Token expiry                            |

> **Note:** Script ưu tiên `JWT_SECRET`/`JWT_ISSUER`/`JWT_AUDIENCE` (dạng phẳng, dễ đọc), fallback `JWTSETTINGS__*` (dạng .NET nested). Có thể dùng 1 trong 2 nhóm, không cần cả hai.

### Connection strings

| Secret                                         | Mục đích                          |
|------------------------------------------------|-----------------------------------|
| `CONNECTIONSTRINGS__DEFAULTCONNECTION`         | Full PostgreSQL connection string |
| `REDIS__CONNECTIONSTRING` *(alternative)*      | Redis connection (alternative)    |

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
| `ALLOWEDORIGINS`                    | CORS whitelist origins (.NET fallback) |

---

## SSH secrets — KHÔNG đặt trong Doppler

`LIGHTSAIL_HOST`, `LIGHTSAIL_USER`, `LIGHTSAIL_SSH_KEY` chỉ tồn tại ở **GitHub Secrets**, KHÔNG đặt trong Doppler:

1. CD script skip key `LIGHTSAIL_SSH_KEY=` khi build `.env` (tránh inject private key vào container).
2. GitHub Actions runner dùng `LIGHTSAIL_SSH_KEY` để SSH vào server — Doppler không tham gia bước này.
3. Doppler chỉ chứa **application secrets** (DB, JWT, API keys...). **Infrastructure secrets** (SSH, Docker Hub) ở GitHub Secrets.

> **Lưu ý bảo mật:** Nếu Doppler config `prd` có `LIGHTSAIL_*` keys cũ (từ trước khi refactor) → xóa đi, vì chúng sẽ bị script skip và tạo cảm giác "có nhưng không dùng".

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

## Lưu ý bảo mật

- **Không commit file `.env`** vào Git (đã có `.gitignore`).
- **GitHub Secrets** chứa 2 nhóm:
  - **CI/CD infrastructure:** `DOPPLER_TOKEN`, `LIGHTSAIL_*` (SSH), `DOCKERHUB_*`.
  - **KHÔNG** lưu application secrets (DB password, JWT, ...) trong GitHub Secrets.
- **Doppler dashboard** là nơi quản lý tất cả **application secrets** (single source of truth).
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
| `.env` chứa `LIGHTSAIL_SSH_KEY=...` | Doppler config có key này (từ trước) | Xóa key khỏi Doppler — script skip key này     |

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

### 2026-07-12: Refactor rollback + cleanup Doppler keys

- Thêm EXIT trap fail-safe cho mọi lỗi không lường trước ✅
- Thêm 3-tier local rollback tag (không phụ thuộc Docker Hub) ✅
- Loại bỏ logic base64-embed docker-compose.prod.yml (file đã có trong repo) ✅
- Xóa ghi chú về việc Doppler chứa `LIGHTSAIL_*` (chỉ ở GitHub Secrets) ✅
