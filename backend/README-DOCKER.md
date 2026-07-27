# MenuGreen Docker Setup

## Cấu trúc thư mục

```
backend/
├── docker-compose.yml           # Main compose file (nginx + api + postgres)
├── Dockerfile                   # Multi-stage build cho .NET API
├── .env.example                 # Template biến môi trường
├── .dockerignore               # Ignore file cho Docker build
├── nginx/
│   ├── nginx.conf              # Main nginx config
│   ├── conf.d/
│   │   └── cors-map.conf       # CORS whitelist - THÊM DOMAIN MỚI Ở ĐÂY
│   └── ssl/
│       └── .gitkeep            # Placeholder cho SSL certificates
├── MenuGreen.API/              # ASP.NET Core Web API
├── MenuGreen.BusinessLogicLayer/
├── MenuGreen.DataAccessLayer/
├── database/
│   ├── seeddata.sql            # Seed data
│   └── MenuGreen_AI_SeedData/  # AI seed data (thư mục)
└── migrations/                  # EF Core migrations (tự động apply)
```

## Quick Start

### 1. Setup Environment

```bash
# Copy environment file
cp .env.example .env

# Edit .env với giá trị thực
nano .env
```

### 2. Build và Run

```bash
# Build images
docker-compose build

# Run tất cả services (nginx + api + postgres)
docker-compose up -d

# Xem logs
docker-compose logs -f

# Xem logs của một service cụ thể
docker-compose logs -f api
docker-compose logs -f nginx
docker-compose logs -f postgres
```

### 3. Verify

```bash
# Kiểm tra containers đang chạy
docker-compose ps

# Test CORS headers
curl -I -X OPTIONS http://localhost/api/Auth/login \
  -H "Origin: https://admin.menugreen.food" \
  -H "Access-Control-Request-Method: POST"

# Test health check
curl http://localhost/health/live
```

## Commands Cheatsheet

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Stop + xóa volumes (CLEAN RESET)
docker-compose down -v

# Rebuild sau khi sửa code
docker-compose up -d --build

# Rebuild không cache
docker-compose build --no-cache

# Restart một service cụ thể
docker-compose restart api
docker-compose restart nginx

# Shell vào container
docker exec -it menugreen-api /bin/sh
docker exec -it menugreen-postgres psql -U postgres -d MenuGreenDb

# Xem resource usage
docker stats

# Xem logs tất cả
docker-compose logs -f --tail=100
```

## Thêm Domain Mới vào CORS

Mở file `nginx/conf.d/cors-map.conf`:

```nginx
map $http_origin $cors_origin {
    default "";

    # === PRODUCTION ===
    "https://www.menugreen.food"     "https://www.menugreen.food";
    "https://menugreen.food"         "https://menugreen.food";
    "https://admin.menugreen.food"  "https://admin.menugreen.food";

    # === THÊM DOMAIN MỚI Ở ĐÂY ===
    "https://staging.menugreen.food" "https://staging.menugreen.food";

    # === LOCALHOST ===
    "http://localhost:3000"          "http://localhost:3000";
}
```

Sau đó restart nginx:
```bash
docker-compose restart nginx
```

## Deploy lên Production Server

### Trên server (Lightsail):

```bash
# 1. Clone/pull code
cd /opt/menugreen
git pull origin main

# 2. Copy và edit .env
cp .env.example .env
nano .env
# Điền: JWT_SECRET_KEY, Firebase credentials, Redis URL

# 3. Build và start
docker-compose build --no-cache
docker-compose up -d

# 4. Verify
curl -I http://localhost/api/Auth/login \
  -H "Origin: https://admin.menugreen.food" \
  -H "Access-Control-Request-Method: POST"
```

### Backup Database

```bash
# Backup
docker exec menugreen-postgres pg_dump -U postgres MenuGreenDb > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore
docker exec -i menugreen-postgres psql -U postgres MenuGreenDb < backup_file.sql
```

## Troubleshooting

### 1. Nginx không start được

```bash
# Check nginx logs
docker-compose logs nginx

# Test config trong container
docker exec menugreen-nginx nginx -t

# Xem full config
docker exec menugreen-nginx nginx -T
```

### 2. API không kết nối được database

```bash
# Kiểm tra postgres health
docker-compose ps postgres

# Test connection từ API
docker exec menugreen-api curl -f http://localhost:5000/health/ready

# Check connection string
docker exec menugreen-api env | grep ConnectionStrings
```

### 3. CORS vẫn lỗi sau khi thêm domain

1. Restart nginx: `docker-compose restart nginx`
2. Clear browser cache (DevTools → Network → Disable cache)
3. Verify config đã được mount đúng:
   ```bash
   docker exec menugreen-nginx cat /etc/nginx/conf.d/cors-map.conf
   ```

### 4. Clean Reset (xoá hết và bắt đầu lại)

```bash
# DANGER: Xóa toàn bộ data!
docker-compose down -v --rmi all
docker system prune -f

# Rebuild và chạy lại
docker-compose up -d --build
```

## Environment Variables

| Variable | Default | Mô tả |
|---|---|---|
| `POSTGRES_DB` | `MenuGreenDb` | Tên database |
| `POSTGRES_USER` | `postgres` | PostgreSQL username |
| `POSTGRES_PASSWORD` | *(required)* | PostgreSQL password; keep it in your local environment or secret manager |
| `POSTGRES_PORT` | `5432` | PostgreSQL port |
| `JWT_SECRET_KEY` | (required) | JWT secret key (min 32 chars) |
| `JWT_ISSUER` | `MenuGreenAPI` | JWT issuer |
| `JWT_AUDIENCE` | `MenuGreenApp` | JWT audience |
| `API_PORT` | `5000` | API internal port |
| `FIREBASE_CREDENTIAL_PATH` | (optional) | Path to Firebase JSON |
| `REDIS_CONNECTION_STRING` | (optional) | Redis connection string |
| `ALLOWED_ORIGINS` | (default domains) | Additional CORS origins |

## SSL/HTTPS Setup

1. Place certificates in `nginx/ssl/`:
   - `fullchain.pem` - Certificate + intermediates
   - `privkey.pem` - Private key

2. Uncomment SSL section in `nginx/nginx.conf`

3. Restart nginx:
   ```bash
   docker-compose restart nginx
   ```
