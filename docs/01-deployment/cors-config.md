# CORS & Nginx Configuration Guide

> **Last updated:** 2026-07-11 — Phản ánh config hiện tại trên server.

---

## Tổng quan

MenuGreen API dùng **Nginx chạy trên host** (không Docker) để:
- **SSL termination** (Let's Encrypt)
- **Reverse proxy** → port 5000 (API trong Docker)
- **CORS handling** (whitelist origins qua dynamic map)

Có 2 cách CORS được xử lý song song:

1. **Nginx** (chính, whitelist qua `cors-map.conf`)
2. **.NET API** (fallback, qua `Program.cs` đọc `ALLOWEDORIGINS` env)

---

## Kiến trúc Nginx (hiện tại)

```
Internet (HTTPS:443)
       ↓
[Nginx trên host]
   ├─ SSL terminate (Let's Encrypt)
   ├─ CORS check (map $http_origin $cors_origin)
   ├─ Rate limiting
   └─ proxy_pass → http://localhost:5000
            ↓
   [Docker container: menugreen_api]
   └─ .NET API + CORS middleware (fallback)
```

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
├── nginx.conf              # Source nginx.conf (copy về /etc/nginx/)
├── conf.d/
│   └── cors-map.conf       # Source CORS map (copy về /etc/nginx/conf.d/)
└── deploy/
    ├── deploy-nginx.sh     # Script apply config
    ├── setup-server.sh     # Script setup lần đầu
    └── README.md           # Hướng dẫn chi tiết
```

---

## CORS Map — Hiện tại

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

### Bước 3: Apply lên server

```bash
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100

cd ~/apps/MenuGreenSystem    # hoặc ~/apps/menugreen nếu có clone
git pull origin main

sudo ./backend/nginx/deploy/deploy-nginx.sh
```

Script `deploy-nginx.sh` sẽ tự động:
1. Backup config cũ (timestamp)
2. Copy file mới vào `/etc/nginx/`
3. Test syntax (`nginx -t`) — fail → rollback tự động
4. Reload nginx (zero downtime)

### Bước 4: Verify

```bash
# Test preflight
curl -I -X OPTIONS https://api.menugreen.food/api/Auth/login \
  -H "Origin: https://staging.menugreen.food" \
  -H "Access-Control-Request-Method: POST"

# Response phải có:
# Access-Control-Allow-Origin: https://staging.menugreen.food
```

---

## Thay đổi trong Program.cs (CORS fallback)

`Program.cs` cũng có CORS middleware đọc từ config `AllowedOrigins`:

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowSpecificOrigins", policy =>
    {
        policy.WithOrigins(
                builder.Configuration["AllowedOrigins"]
                    ?.Split(',', StringSplitOptions.RemoveEmptyEntries) ?? Array.Empty<string>())
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});
```

### Config qua env `ALLOWED_ORIGINS`

Set trong Doppler config `prd`:

```
ALLOWEDORIGINS=https://www.menugreen.food,https://menugreen.food,https://admin.menugreen.food
```

CD workflow sẽ tự convert thành `ALLOWED_ORIGINS=...` trong file `.env` trên server.

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

- [DEPLOY.md](./DEPLOY.md) — Tổng quan deployment
- [CI_CD.md](./CI_CD.md) — CI/CD pipeline
- `backend/nginx/deploy/README.md` — Hướng dẫn chi tiết nginx deployment

---

*Last updated: 2026-07-11*
