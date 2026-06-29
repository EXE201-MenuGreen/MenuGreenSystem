# MenuGreen System - Production Deployment Plan

## Mục tiêu

- Deploy backend .NET API lên server Ubuntu sử dụng Docker + Docker Compose.
- PostgreSQL **không chạy trong Docker** mà dùng AWS RDS.
- Redis chạy trong Docker container (Docker Redis với backup định kỳ).
- Mọi hướng dẫn deploy phải khớp với kiến trúc này.

## Kiến trúc Production

```
AWS Lightsail (Ubuntu 22.04)
├── Docker Compose
│   ├── api      → ASP.NET Core API (port 5000)
│   └── redis    → Redis 7 Alpine (container, 256MB RAM)
└── AWS RDS
    └── PostgreSQL 15 (menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com:5432)
```

## Services

| Service | Location | Port | Ghi chú |
|---------|----------|------|---------|
| API | Docker container | 5000 | Kết nối RDS + Redis |
| Redis | Docker container | 6379 | Container `menugreen_redis`, giới hạn 256MB RAM |
| PostgreSQL | AWS RDS | 5432 | Endpoint: `menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com` |

---

## PHASE 1: Chuẩn bị trước khi deploy

### Checklist

- [ ] Server Ubuntu đã có Docker + Docker Compose cài đặt
- [ ] RDS PostgreSQL đã tạo và đang chạy
- [ ] Đã có endpoint, port, username, password của RDS
- [ ] Security group RDS đã mở port 5432 cho IP server
- [ ] Database `MenuGreenDb` đã được tạo trên RDS
- [ ] Redis password đã được chuẩn bị
- [ ] JWT_SECRET_KEY đã được tạo (dùng `openssl rand -base64 48`)
- [ ] Thư mục backup đã tạo: `/home/ubuntu/backups/redis`
- [ ] Code đã push lên git (nhánh `main`)

### Thao tác

#### 1. Tạo database trên RDS (nếu chưa có)

```bash
psql -h menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com \
     -p 5432 \
     -U postgres \
     -d postgres
```

```sql
CREATE DATABASE "MenuGreenDb";
\q
```

#### 2. Tạo thư mục backup Redis

```bash
sudo mkdir -p /home/ubuntu/backups/redis
sudo mkdir -p /home/ubuntu/logs
sudo chown -R ubuntu:ubuntu /home/ubuntu/backups
sudo chown -R ubuntu:ubuntu /home/ubuntu/logs
```

#### 3. Tạo file `.env` trên server

```bash
cd /home/ubuntu/apps/MenuGreenSystem
cp .env.production.example .env
nano .env
```

Điền các giá trị:

```env
# RDS PostgreSQL
DB_HOST=menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com
DB_PORT=5432
DB_NAME=MenuGreenDb
DB_USER=postgres
DB_PASSWORD=<password RDS>
DB_SSL_MODE=Require
DB_TRUST_SERVER_CERTIFICATE=true

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=<password Redis (không dùng $, !, # trong password)>

# API
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_HTTP_PORTS=5000
JWT_SECRET_KEY=<random key dài ≥ 32 chars>
ALLOWED_ORIGINS=<domain hoặc * để test>
```

#### 4. Kiểm tra `.env` đã đúng

```bash
# Không được có placeholder "CHANGE_THIS" còn sót lại
grep "CHANGE_THIS" .env || echo "OK: Không còn placeholder"

# Kiểm tra password Redis không có ký tự đặc biệt
grep "REDIS_PASSWORD" .env
```

---

## PHASE 2: Deploy lên server

### Checklist

- [ ] Đã SSH vào server
- [ ] Đã cd vào thư mục project
- [ ] File `.env` đã tồn tại và hợp lệ
- [ ] Có quyền sudo

### Thao tác

```bash
cd /home/ubuntu/apps/MenuGreenSystem
sudo ./scripts/deploy.sh
```

Script sẽ tự động:
1. Pull code mới từ git
2. Kiểm tra `.env`
3. Build Docker image
4. Start Redis (với resource limits)
5. Run EF migration vào RDS
6. Start API
7. Health check

### Thời gian dự kiến: 5-10 phút

---

## PHASE 3: Kiểm tra sau deploy

### Checklist

- [ ] Containers đang chạy đúng
- [ ] API health check passed
- [ ] Redis container healthy
- [ ] Không có lỗi trong logs

### Thao tác

```bash
# 1. Kiểm tra tất cả containers
docker compose -f docker-compose.prod.yml ps

# 2. Health check API
curl -f http://localhost:5000/health

# 3. Kiểm tra Redis
docker compose -f docker-compose.prod.yml ps redis

# 4. Xem logs nếu cần
docker compose -f docker-compose.prod.yml logs -f api
docker compose -f docker-compose.prod.yml logs -f redis
```

### Nếu API không healthy

| Triệu chứng | Nguyên nhân có thể | Cách fix |
|-------------|-------------------|----------|
| Connection timeout RDS | Security group chưa mở port 5432 | Mở port 5432 cho IP server trong AWS Console |
| Connection refused RDS | `DB_HOST` sai hoặc RDS chưa chạy | Kiểm tra endpoint, status RDS |
| 401/403 từ API | `JWT_SECRET_KEY` thiếu hoặc sai | Kiểm tra `.env` có `JWT_SECRET_KEY` không |
| Redis connection error | `REDIS_PASSWORD` sai | Kiểm tra password trong `.env` khớp với container |

### Nếu Redis gặp vấn đề

| Triệu chứng | Nguyên nhân có thể | Cách fix |
|-------------|-------------------|----------|
| Redis container thoát liên tục | Password có ký tự đặc biệt không escape | Dùng password đơn giản, tránh `$`, `!`, `#` |
| OOM (Out of Memory) | Redis vượt giới hạn 256MB | Kiểm tra `docker stats`, tăng limit nếu cần |
| API không connect Redis | Password sai hoặc container chưa start | Xem logs: `docker compose logs redis` |

### Kiểm tra Redis thủ công

```bash
# Test kết nối Redis từ bên trong container api
docker compose -f docker-compose.prod.yml exec api sh -c \
  "apk add --no-cache redis-tools 2>/dev/null; redis-cli -h redis -a \$REDIS_PASSWORD ping"
```

---

## PHASE 4: Xác nhận production hoạt động

### Checklist

- [ ] API trả về HTTP 200 tại `/health`
- [ ] API trả về HTTP 200/401 tại endpoint test (ví dụ `/api/auth/register`)
- [ ] Redis ping trả về PONG
- [ ] HTTPS đã cấu hình (nếu có domain)
- [ ] Cron job backup Redis đã được thiết lập

### Thao tác

```bash
# Test từ server
curl http://localhost:5000/health
curl http://localhost:5000/api/health

# Test từ bên ngoài (nếu đã mở firewall)
curl http://<server-ip>:5000/health

# Kiểm tra cron job backup
crontab -l | grep redis
```

---

## PHASE 5: Bảo trì định kỳ

### Hàng ngày
- Xem logs: `docker compose -f docker-compose.prod.yml logs -f api`

### Hàng tuần
- Kiểm tra disk space: `df -h`
- Kiểm tra Docker: `docker system df`
- Kiểm tra Redis memory: `docker exec menugreen_redis redis-cli -a $REDIS_PASSWORD INFO memory`
- Kiểm tra backup Redis: `ls -la /home/ubuntu/backups/redis/`

### Mỗi khi deploy
- Backup RDS trước khi chạy migration lớn
- Giữ lại 3-5 commit gần nhất để rollback

### Redis Backup (tự động qua cron)

Backup script `scripts/backup-redis.sh` sẽ:
1. Trigger Redis `BGSAVE`
2. Copy file `dump.rdb` sang thư mục backup
3. Xóa backup cũ hơn 7 ngày

Kiểm tra backup:
```bash
ls -la /home/ubuntu/backups/redis/
```

---

## QUICK REFERENCE

### Deploy lại (code thay đổi)
```bash
cd /home/ubuntu/apps/MenuGreenSystem
sudo ./scripts/deploy.sh
```

### Rollback (deploy lỗi)
```bash
cd /home/ubuntu/apps/MenuGreenSystem
git log --oneline -5
git reset --hard <commit-hash>
sudo ./scripts/deploy.sh
```

### Xem logs real-time
```bash
docker compose -f docker-compose.prod.yml logs -f api
docker compose -f docker-compose.prod.yml logs -f redis
```

### Restart services
```bash
docker compose -f docker-compose.prod.yml restart api
docker compose -f docker-compose.prod.yml restart redis
```

### Stop tất cả
```bash
docker compose -f docker-compose.prod.yml down
```

### Manual Redis backup
```bash
sudo /home/ubuntu/apps/MenuGreenSystem/scripts/backup-redis.sh
```

### Check Redis status
```bash
docker exec menugreen_redis redis-cli -a $REDIS_PASSWORD INFO
```

### Check Redis memory usage
```bash
docker exec menugreen_redis redis-cli -a $REDIS_PASSWORD INFO memory
```

---

## Redis Production Configuration

### Resource Limits

Redis được giới hạn trong `docker-compose.prod.yml`:

```yaml
redis:
  image: redis:7-alpine
  container_name: menugreen_redis
  volumes:
    - redis_data:/data
  networks:
    - menugreen-net
  restart: unless-stopped
  command: >
    redis-server
    --appendonly yes
    --requirepass ${REDIS_PASSWORD}
    --maxmemory 200mb
    --maxmemory-policy allkeys-lru
  healthcheck:
    test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
    interval: 30s
    timeout: 10s
    retries: 3
  deploy:
    resources:
      limits:
        memory: 256M
        cpus: '0.5'
```

### Backup Strategy

| Thông số | Giá trị |
|----------|---------|
| Tần suất | Hàng ngày lúc 2:00 AM |
| Thời gian giữ | 7 ngày |
| Backup path | `/home/ubuntu/backups/redis/` |
| Log path | `/home/ubuntu/logs/redis-backup.log` |

### Khi nào nên nâng cấp lên Lightsail Managed Redis?

| Signal | Ngưỡng |
|--------|--------|
| Traffic | > 1000 requests/giờ |
| Redis memory | Thường xuyên > 150MB |
| Redis là SPOF | Ứng dụng không hoạt động nếu Redis chết |
| Budget | Có thể chi trả ~$15-30/tháng |

**Cách migrate lên Managed Redis:**
1. Tạo Lightsail Managed Database Redis
2. Đổi `.env`: `REDIS_HOST=<endpoint>`, `REDIS_PORT=<port>`
3. Redeploy: `sudo ./scripts/deploy.sh`

---

## Lưu ý quan trọng

- **Không** chạy PostgreSQL container trên production (đã có RDS).
- `.env` **không được commit** vào git.
- EF migration chạy trong container `api` kết nối trực tiếp RDS.
- Redis dùng Docker với resource limits và backup định kỳ (đủ cho production vừa và lớn).
- Password Redis nên dùng ký tự đơn giản, tránh `$`, `!`, `#`.
- File này đã bao gồm đầy đủ các bước từ chuẩn bị → deploy → kiểm tra → bảo trì.
