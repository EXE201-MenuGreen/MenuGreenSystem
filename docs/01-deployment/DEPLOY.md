# MenuGreen System - Production Deployment Plan

## Mục tiêu

- Deploy backend .NET API lên AWS Lightsail Ubuntu sử dụng **GitHub Actions CI/CD**.
- PostgreSQL dùng **AWS RDS** (không chạy trong Docker).
- Redis chạy trong **Docker container** trên server.
- **Tự động hóa hoàn toàn**: push code → CI/CD tự deploy.

---

## Kiến trúc Production

```
GitHub Repository
       │
       ▼
┌──────────────────────────────┐
│   GitHub Actions CI/CD       │
│   (GitHub Secrets)           │
└──────────────────────────────┘
       │
       │ SSH + Docker
       ▼
AWS Lightsail (Ubuntu 22.04)
├── Docker
│   ├── menugreen-api (port 5000)
│   └── menugreen-redis (port 6379)
└── AWS RDS
    └── PostgreSQL 15 (port 5432)
```

---

## Services

| Service | Location | Port | Notes |
|---------|----------|------|-------|
| API | Docker container | 5000 | Kết nối RDS + Redis |
| Redis | Docker container | 6379 | Giới hạn 256MB RAM |
| PostgreSQL | AWS RDS | 5432 | `<RDS_ENDPOINT>` |

---

## CI/CD Pipeline

### Jobs Flow

```
┌─────────────────┐
│  build-and-test │  (Unit Tests)
└────────┬────────┘
         │ pass
         ▼
┌─────────────────┐
│  build-docker    │  (Build & Push to GHCR)
└────────┬────────┘
         │ pass
         ▼
┌─────────────────┐
│  deploy          │  (SSH → Pull → Deploy)
│                  │  1. Create .env
│                  │  2. Pull Docker image
│                  │  3. Stop old container
│                  │  4. Start new container
│                  │  5. Health check
│                  │  6. Run EF Migration
└─────────────────┘
```

### Trigger Conditions

- Push lên nhánh `main` hoặc `Tuan`
- Pull Request vào nhánh `main`

---

## PHASE 1: Chuẩn bị (GitHub Secrets)

### Danh sách Secrets cần thêm

Vào **GitHub** → Repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret Name | Giá trị | Ghi chú |
|-------------|---------|---------|
| `LIGHTSAIL_HOST` | `<LIGHTSAIL_HOST>` | IP/DNS server |
| `LIGHTSAIL_USER` | `ubuntu` | SSH username |
| `LIGHTSAIL_SSH_KEY` | (paste file .pem) | Toàn bộ nội dung |
| `DB_HOST` | `<RDS_ENDPOINT>` | Ví dụ: <RDS_ENDPOINT> |
| `DB_PORT` | `5432` | |
| `DB_NAME` | `MenuGreenDb` | |
| `DB_USER` | `postgres` | |
| `DB_PASSWORD` | `<DB_PASSWORD>` | |
| `REDIS_PASSWORD` | `<REDIS_PASSWORD>` | |
| `JWT_SECRET` | `<JWT_SECRET>` | Tạo: `openssl rand -base64 48` |

### Cách tạo JWT_SECRET

```bash
# Trên terminal
openssl rand -base64 48
```

Copy kết quả và paste vào GitHub Secret `JWT_SECRET`.

---

## PHASE 2: Chuẩn bị Server

### Checklist

- [ ] Server Ubuntu đã cài Docker + Docker Compose
- [ ] Security group RDS đã mở port 5432 cho IP server
- [ ] Database `MenuGreenDb` đã tạo trên RDS
- [ ] File `.pem` SSH key đã tải về (để add vào GitHub Secret)

### Kiểm tra Docker trên server

```bash
ssh -i your-key.pem ubuntu@<LIGHTSAIL_HOST>

# Kiểm tra Docker
docker --version
docker compose version

# Kiểm tra Redis container (nếu chưa có, sẽ được tạo tự động)
docker ps -a | grep redis || echo "Redis chưa có, sẽ được tạo"
```

### Tạo database trên RDS (nếu chưa có)

```bash
psql -h <RDS_ENDPOINT> \
     -p 5432 -U postgres -d postgres

# Nhập password khi được hỏi

CREATE DATABASE "MenuGreenDb";
\q
```

---

## PHASE 3: Deploy tự động

### Cách deploy

**Chỉ cần push code lên nhánh `main` hoặc `Tuan`:**

```bash
# Trên local
git add .
git commit -m "feat: mô tả thay đổi"
git push origin main
# hoặc
git push origin Tuan
```

GitHub Actions sẽ tự động:
1. Chạy unit tests
2. Build Docker image
3. Push lên GHCR
4. SSH vào server
5. Pull image mới
6. Deploy container mới
7. Chạy EF Migration
8. Health check

### Theo dõi tiến trình

Vào **GitHub** → Repository → **Actions** tab → Click vào workflow đang chạy.

---

## PHASE 4: Kiểm tra sau deploy

### Checklist

- [ ] Workflow status: ✅ green
- [ ] API health check: `curl http://<LIGHTSAIL_HOST>:5000/health`
- [ ] Swagger UI: `http://<LIGHTSAIL_HOST>:5000/swagger/index.html`

### Thao tác kiểm tra

```bash
# SSH vào server
ssh -i your-key.pem ubuntu@<LIGHTSAIL_HOST>

# Kiểm tra container đang chạy
docker ps

# Kiểm tra logs API
docker logs menugreen-api --tail 50

# Kiểm tra health endpoint
curl http://localhost:5000/health

# Kiểm tra Redis
docker exec menugreen-redis redis-cli -a $REDIS_PASSWORD ping
```

---

## Xử lý lỗi thường gặp

### Lỗi Secrets

| Triệu chứng | Nguyên nhân | Cách fix |
|-------------|-------------|----------|
| SSH connection failed | `LIGHTSAIL_SSH_KEY` sai | Kiểm tra lại file .pem, đảm bảo copy đúng |
| Cannot connect to RDS | Security group chưa mở | Mở port 5432 cho IP server trong AWS Console |
| Redis connection failed | Password sai | Kiểm tra `REDIS_PASSWORD` secret |

### Lỗi Deployment

| Triệu chứng | Cách fix |
|-------------|----------|
| Workflow failed at deploy | Xem logs trong Actions tab |
| Container không start | `docker logs menugreen-api` |
| Migration lỗi | SSH vào server, chạy lại: `docker exec menugreen-api dotnet ef database update` |

### Re-run deployment

Vào **Actions** → Click workflow failed → **Re-run all jobs**

---

## QUICK REFERENCE

### Sau khi thêm secrets

Push code để trigger CI/CD:

```bash
git add .
git commit -m "ci: trigger deployment"
git push origin main
```

### Kiểm tra trạng thái

| Mục đích | Cách kiểm tra |
|----------|---------------|
| Xem workflow | GitHub → Actions tab |
| Logs CI/CD | GitHub → Actions → Click job → Xem logs |
| Logs API server | `docker logs menugreen-api -f` |
| Health API | `curl http://<LIGHTSAIL_HOST>:5000/health` |

### Restart container (nếu cần)

```bash
ssh -i your-key.pem ubuntu@<LIGHTSAIL_HOST>

# Restart API
docker restart menugreen-api

# Restart Redis
docker restart menugreen-redis
```

### Stop tất cả

```bash
docker stop menugreen-api menugreen-redis
docker rm menugreen-api menugreen-redis
```

---

## Redis Production Configuration

### Resource Limits

- Memory: 256MB
- Policy: allkeys-lru (xóa key cũ khi full)
- Persistence: AOF enabled

### Backup (nếu cần)

```bash
# Manual backup
docker exec menugreen-redis redis-cli -a $REDIS_PASSWORD BGSAVE
docker cp menugreen-redis:/data/dump.rdb ./backup-$(date +%Y%m%d).rdb
```

---

## Lưu ý quan trọng

- **Không commit** `.env` hoặc secrets vào git.
- PostgreSQL **không chạy trong Docker** (dùng RDS).
- CI/CD tự động deploy khi push lên `main` hoặc `Tuan`.
- SSH key (.pem) cần được paste **toàn bộ** vào GitHub Secret.
- Health endpoint có thể cần cấu hình thêm trong API.

---

## Liên hệ hỗ trợ

Nếu gặp lỗi không xử lý được:
1. Xem logs trong GitHub Actions
2. SSH vào server kiểm tra logs
3. Kiểm tra GitHub Secrets đã đúng chưa
