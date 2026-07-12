# CORS & Nginx Configuration Guide

> **Last updated:** 2026-07-12 — Workflow tự động qua CI/CD (không cần SSH để apply nginx).
>
> **Đã sửa:** Mapping env `ALLOWEDORIGINS` → `AllowedOrigins` chính xác theo Program.cs. Bổ sung flow apply toàn bộ `nginx.conf` + `cors-map.conf` (không chỉ cors-map).

---

## Tổng quan

MenuGreen API dùng **Nginx chạy trên host** (không Docker) để:
- **SSL termination** (Let's Encrypt)
- **Reverse proxy** → port 5000 (API trong Docker)
- **CORS handling** (whitelist origins qua dynamic map)

Có 2 lớp CORS xử lý song song:

1. **Nginx** (chính, whitelist qua `cors-map.conf` với `map $http_origin $cors_origin`)
2. **.NET API** (fallback, qua `Program.cs` đọc `AllowedOrigins` config key)

---

## Kiến trúc Nginx

```
Internet (HTTPS:443)
       ↓
[Nginx trên host]   ← Cài qua apt install, chạy như systemd service
   ├─ SSL terminate (Let's Encrypt)
   ├─ CORS check (map $http_origin $cors_origin)
   ├─ Rate limiting
   └─ proxy_pass → http://localhost:5000
            ↓
   [Docker container: menugreen_api]
   └─ .NET API + CORS middleware (fallback)
```

### Vị trí Nginx trong hệ thống

| Thành phần                       | Vị trí                                       | Quản lý bởi        |
|----------------------------------|----------------------------------------------|---------------------|
| Nginx binary                     | `/usr/sbin/nginx` (apt install)              | System package      |
| Nginx service                    | `systemctl status nginx`                     | systemd             |
| Config source                    | `MenuGreenSystem/backend/nginx/`             | Git repository      |
| Config runtime                   | `/etc/nginx/nginx.conf` + `/etc/nginx/conf.d/` | CI/CD apply       |
| Docker image `menugreensystem:main` | ❌ KHÔNG chứa nginx                       | —                   |

> **Lưu ý:** Nginx là service ĐỘC LẬP trên host, tách biệt hoàn toàn khỏi Docker Image. Sửa nginx → chỉ cần push git → CI/CD apply (không build lại image).

---

## File cấu hình trên server

```
/etc/nginx/
├── nginx.conf                          # Main config
├── conf.d/
│   └── cors-map.conf                   # ⭐ WHITELIST origins (thường sửa file này)
├── snippets/                           # (placeholder, hiện chưa dùng)
├── sites-enabled/
└── ssl/                                # SSL certs (Let's Encrypt)
```

**Các file nguồn trong repo:** `MenuGreenSystem/backend/nginx/`

```
MenuGreenSystem/backend/nginx/
├── nginx.conf              # Source nginx.conf (CI/CD copy về /etc/nginx/)
├── conf.d/
│   └── cors-map.conf       # Source CORS map (CI/CD copy về /etc/nginx/conf.d/)
└── ssl/                    # Mount point cho SSL certs (file thực nằm trên server)
```

> **Apply flow:** Toàn bộ `nginx/` được CD workflow SCP lên `/tmp/nginx-deploy/` mỗi lần push, sau đó `deploy-server.sh` copy vào `/etc/nginx/` và reload. Không cần chạy script thủ công trên server.

---

## CORS Map — hiện tại

File `/etc/nginx/conf.d/cors-map.conf` (source: `MenuGreenSystem/backend/nginx/conf.d/cors-map.conf`):

```nginx
map $http_origin $cors_origin {
    default "";

    # Production domains
    "https://www.menugreen.food"     "https://www.menugreen.food";
    "https://menugreen.food"         "https://menugreen.food";
    "https://admin.menugreen.food"   "https://admin.menugreen.food";

    # Vercel preview
    "https://menu-green-system-ldw5frytu-johnny-dangs-projects.vercel.app"
        "https://menu-green-system-ldw5frytu-johnny-dangs-projects.vercel.app";

    # Localhost dev
    "http://localhost:3000"          "http://localhost:3000";
    "http://localhost:3001"          "http://localhost:3001";
    "http://localhost:5173"          "http://localhost:5173";
    "http://127.0.0.1:3000"          "http://127.0.0.1:3000";
    "http://127.0.0.1:5173"          "http://127.0.0.1:5173";
}
```

> **Cơ chế:** Nginx map `Origin` header → `$cors_origin` variable. Nếu origin KHÔNG trong whitelist → `$cors_origin = ""` → KHÔNG gửi `Access-Control-Allow-Origin` → browser block request.

---

## Cách thêm domain mới vào CORS

### Bước 1: Sửa file trên local

Mở `MenuGreenSystem/backend/nginx/conf.d/cors-map.conf` bằng VS Code, thêm domain:

```nginx
map $http_origin $cors_origin {
    default "";

    "https://www.menugreen.food"     "https://www.menugreen.food";
    "https://menugreen.food"         "https://menugreen.food";
    "https://admin.menugreen.food"   "https://admin.menugreen.food";
    "https://staging.menugreen.food" "https://staging.menugreen.food";  ← MỚI THÊM
    ...
}
```

### Bước 2: Commit + push

```bash
git add backend/nginx/conf.d/cors-map.conf
git commit -m "feat(nginx): add staging.menugreen.food to CORS"
git push origin main
```

### Bước 3: CI/CD tự động apply lên server

**Không cần SSH vào server.** GitHub Actions runner tự động:

```
1. backend-ci.yml — Build & push Docker image (3-5 phút)
2. backend-cd.yml — Deploy:
   ├─ SCP files lên /tmp/nginx-deploy/:
   │   ├─ backend/nginx/nginx.conf
   │   └─ backend/nginx/conf.d/cors-map.conf
   └─ SSH vào server, chạy deploy-server.sh:
      ├─ Backup config hiện tại (.bak.YYYYMMDD_HHMMSS)
      ├─ Copy file mới → /etc/nginx/nginx.conf + /etc/nginx/conf.d/cors-map.conf
      ├─ nginx -t (syntax check)
      │    ├─ PASS → systemctl reload nginx (zero downtime)
      │    └─ FAIL → restore backup → exit 1 (abort toàn bộ deploy)
      └─ Pull image mới + restart container
```

> **Tổng thời gian:** 5-8 phút từ lúc push → nginx mới có hiệu lực.
> **Không cần build lại Docker image** khi chỉ sửa nginx (CD vẫn chạy nhưng image giữ nguyên — tag mới được push lên Hub nhưng server vẫn pull `:main` chứa image mới nhất).

### Bước 4: Verify

```bash
# Test preflight
curl -I -X OPTIONS https://api.menugreen.food/api/Auth/login \
  -H "Origin: https://staging.menugreen.food" \
  -H "Access-Control-Request-Method: POST"

# Response phải có:
# Access-Control-Allow-Origin: https://staging.menugreen.food
```

### 4 trường hợp cập nhật Nginx

| Trường hợp                                          | Cách làm                                            | Thời gian |
|------------------------------------------------------|-----------------------------------------------------|-----------|
| **Thêm domain CORS** (phổ biến nhất)                | Sửa `cors-map.conf` → push                          | 5-8 phút  |
| **Sửa upstream / rate limit / security header**     | Sửa `nginx.conf` → push                             | 5-8 phút  |
| **Sửa code API + Nginx cùng lúc**                   | Sửa cả `.cs` + nginx → push                        | 5-8 phút (cả 2 update) |
| **Chỉ sửa nginx, không sửa code**                   | Sửa nginx → push                                    | 5-8 phút (image vẫn được build nhưng giống cũ) |

> ⚠️ **Lưu ý:** Sửa `nginx.conf` (không phải `cors-map.conf`) cần cẩn thận — workflow có auto rollback nếu syntax fail, nhưng nên test kỹ trước khi push.

---

## CORS fallback trong .NET API (`Program.cs`)

`Program.cs` đọc `AllowedOrigins` từ configuration (key phẳng, không phải PascalCase nested) và **concat với `defaultOrigins` cứng trong code** (đảm bảo các domain production quan trọng luôn được phép). Doppler secret `ALLOWEDORIGINS` được giữ nguyên (không convert `:` → `__` vì không có `:`):

```csharp
// Default origins cứng trong code (luôn được phép)
var defaultOrigins = new[]
{
    "https://admin.menugreen.food",
    "https://www.menugreen.food",
    "https://menugreen.food",
    "https://menu-green-system-ldw5frytu-johnny-dangs-projects.vercel.app",
    "http://localhost:3000",
    "http://localhost:3001"
};

// Lấy thêm từ config/env (Doppler ALLOWEDORIGINS)
var configuredOrigins = (builder.Configuration["AllowedOrigins"]
    ?? Environment.GetEnvironmentVariable("ALLOWED_ORIGINS"))
    ?.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    ?? Array.Empty<string>();

// Merge + dedupe
var allowedOrigins = defaultOrigins.Concat(configuredOrigins).Distinct().ToArray();
var allowAnyOrigin = allowedOrigins.Contains("*");

builder.Services.AddCors(options =>
{
    options.AddPolicy(corsPolicyName, policy =>
    {
        if (isDevelopment || allowAnyOrigin)
        {
            // Dev mode hoặc wildcard → allow all
            policy.SetIsOriginAllowed(origin => true)
                  .AllowAnyMethod()
                  .AllowAnyHeader()
                  .AllowCredentials();
        }
        else
        {
            // Production → whitelist cứng
            policy.WithOrigins(allowedOrigins)
                  .AllowAnyMethod()
                  .AllowAnyHeader()
                  .AllowCredentials();
        }
    });
});
```

### Config qua Doppler

Set trong Doppler config `prd`:

```
ALLOWEDORIGINS=https://www.menugreen.food,https://menugreen.food,https://admin.menugreen.food
```

CD workflow ghi vào `.env` đúng key `ALLOWEDORIGINS=...` (giữ nguyên tên, không thêm underscore). `Program.cs` đọc qua `builder.Configuration["AllowedOrigins"]` (key flat, không phải PascalCase). Nếu không có, fallback `Environment.GetEnvironmentVariable("ALLOWED_ORIGINS")`.

> **Lưu ý:**
> - **Nginx CORS** (chính) xử lý phần lớn request trước khi tới .NET. .NET CORS là **fallback** cho trường hợp Nginx đã pass request nhưng .NET vẫn cần check (vd internal call, test với curl bỏ qua Nginx).
> - Wildcard `*` chỉ bật khi `ASPNETCORE_ENVIRONMENT=Development` hoặc Doppler `ALLOWEDORIGINS=*`. Production luôn dùng whitelist cứng.

---

## Rate Limiting (trong nginx.conf)

```nginx
# Rate limiting zones
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=auth:1r/m;
limit_conn_zone $binary_remote_addr zone=addr:10m;

# Apply
limit_req zone=api burst=20 nodelay;
limit_conn addr 10;
```

- API general: 10 req/s, burst 20
- Auth endpoints: 1 req/min (chống brute force)
- Max 10 connections/IP

---

## CORS Test Commands

### Test preflight (OPTIONS)

```bash
curl -I -X OPTIONS https://api.menugreen.food/api/Auth/login \
  -H "Origin: https://www.menugreen.food" \
  -H "Access-Control-Request-Method: POST"
```

**Response mong đợi:**
```
HTTP/2 204
access-control-allow-origin: https://www.menugreen.food
access-control-allow-methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
access-control-allow-credentials: true
access-control-allow-headers: ...
access-control-max-age: 86400
```

### Test actual request (GET)

```bash
curl -I https://api.menugreen.food/health/live \
  -H "Origin: https://www.menugreen.food"
```

### Test domain KHÔNG có trong whitelist (expect fail)

```bash
curl -I https://api.menugreen.food/api/Auth/login \
  -H "Origin: https://evil.com"
# → KHÔNG có access-control-allow-origin header
```

---

## Troubleshooting CORS

### "No 'Access-Control-Allow-Origin' header"

1. Check domain đã thêm vào `cors-map.conf` chưa
2. Verify exact match (kể cả `https://` vs `http://`)
3. Reload nginx: `sudo systemctl reload nginx`

### Preflight (OPTIONS) failing

1. `sudo nginx -t` để check syntax
2. Xem nginx logs: `sudo tail -20 /var/log/nginx/error.log`
3. Test bằng curl preflight (xem trên)

### Domain Vercel preview

Vercel preview URL thay đổi mỗi lần deploy. Có 2 options:

**Option A:** Thêm URL cụ thể vào `cors-map.conf` sau mỗi Vercel deploy.

**Option B:** Dùng `ALLOWEDORIGINS` env trong Doppler với pattern (không khuyến nghị vì CORS spec không support wildcard).

Hiện tại: dùng Option A cho domain Vercel chính (`menu-green-system-ldw5frytu-johnny-dangs-projects.vercel.app`).

---

## Security Notes

- **Không dùng `*` cho `Access-Control-Allow-Origin`** khi `AllowCredentials=true` (browser sẽ reject).
- **Whitelist chỉ những domain thật sự dùng**, xóa các domain dev cũ không dùng nữa.
- **CORS ở Nginx** (chính) + **CORS ở .NET** (fallback) = double protection.
- **Luôn dùng HTTPS** cho production origins (không `http://`).

---

## Liên quan

- [ARCHITECTURE.md](./ARCHITECTURE.md) — Tổng quan deployment (workflow Nginx CI/CD)
- [CI_CD.md](./CI_CD.md) — CI/CD pipeline chi tiết + rollback

---

*Last updated: 2026-07-12 — Workflow tự động qua CI/CD*
