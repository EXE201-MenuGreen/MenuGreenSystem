# CI/CD Pipeline - MenuGreen System

## Tổng quan

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Develop   │ ──► │  Pull Req   │ ──► │   Merge     │ ──► │   Deploy    │
│   Branch    │     │   (PR)      │     │   (Main)    │     │  Lightsail  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                           │                   │                   │
                           ▼                   ▼                   ▼
                    ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
                    │ Build &     │     │ Build &     │     │ Migrate DB  │
                    │ Test        │     │ Test        │     │ Rebuild     │
                    │ (auto)      │     │ (auto)      │     │ Restart    │
                    └─────────────┘     └─────────────┘     └─────────────┘
```

## Cấu trúc Pipeline

### Job 1: Build & Test
- Build .NET project
- Chạy unit tests với PostgreSQL test instance
- **Tự động** chạy khi có PR hoặc merge

### Job 2: Generate Migration Script
- Generate SQL script từ migrations
- Upload artifact để review
- Chỉ chạy khi merge vào main

### Job 3: Build Docker Image
- Build và push image lên GitHub Container Registry
- Cache layers để tăng tốc build

### Job 4: Deploy to Lightsail
- Pull code mới nhất
- Apply database migrations
- Rebuild và restart services
- Health check

## Setup GitHub Secrets

Cần thêm các secrets trong GitHub:

1. **GitHub Settings** → **Secrets and variables** → **Actions**

2. Thêm các secrets:

| Secret Name | Mô tả | Ví dụ |
|-------------|--------|--------|
| `LIGHTSAIL_HOST` | IP hoặc hostname Lightsail | `13.229.87.142` hoặc `api.menugreen.com` |
| `LIGHTSAIL_SSH_KEY` | Private SSH key để connect | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `DB_HOST` | RDS endpoint | `menugreen-db.xxxx.ap-southeast-1.rds.amazonaws.com` |
| `DB_PORT` | Port PostgreSQL | `5432` |
| `DB_NAME` | Tên database | `MenuGreenDb` |
| `DB_USER` | Username | `postgres` |
| `DB_PASSWORD` | Password | `YourPassword123!` |
| `REDIS_PASSWORD` | Redis password | `YourRedisPassword123!` |

## Tạo SSH Key cho GitHub Actions

Trên máy local (Windows):

```powershell
# Tạo SSH key mới
ssh-keygen -t ed25519 -C "github-actions@menugreen" -f ~/menugreen_actions

# Xem public key (thêm vào Lightsail)
cat ~/menugreen_actions.pub

# Xem private key (copy cho GitHub Secret)
cat ~/menugreen_actions
```

Trên Lightsail:

```bash
# Thêm public key vào authorized_keys
mkdir -p ~/.ssh
echo "ssh-ed25519 AAAA... github-actions@menugreen" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

## Workflow cho Development

### Khi thêm/chỉnh sửa model

```bash
# 1. Thêm migration mới
dotnet ef migrations add AddNewTable

# 2. Test migration local
dotnet ef database update

# 3. Commit và push
git add .
git commit -m "Add migration for new table"
git push

# 4. Tạo Pull Request
# CI/CD sẽ tự động:
# - Build & Test
# - Generate migration script
# - Deploy khi merge vào main
```

### Review Migration Script

Sau khi merge vào main:
1. GitHub Actions sẽ generate SQL script
2. Script được upload làm artifact
3. Download và review trước khi deploy

### Rollback Migration

Nếu cần rollback:

```bash
# Trên Lightsail
cd ~/apps/MenuGreenSystem
dotnet ef migrations remove

# Hoặc rollback về migration cụ thể
dotnet ef database update <MigrationName>
```

## Các cách Migration trong Production

### Cách 1: Auto-migrate trong deploy (Hiện tại)
```bash
# Trong deploy.sh
dotnet ef database update
```
- **Ưu điểm**: Đơn giản, tự động
- **Nhược điểm**: Khó control, khó review

### Cách 2: Manual review trước
```bash
# Generate script
dotnet ef migrations script -o migration.sql

# Review file
cat migration.sql

# Apply thủ công
psql "$DB_CONNECTION" < migration.sql
```

### Cách 3: Zero-downtime deployment
- Tạo migration không blocking
- Deploy code mới
- Chạy migration sau khi code deployed

## Troubleshooting

### Migration failed
```bash
# Xem log
cat ~/logs/migration.log

# Check database connection
psql "$DB_CONNECTION" -c "SELECT 1"

# Apply migration thủ công
dotnet ef database update --verbose
```

### API không start
```bash
# Xem logs
docker compose -f docker-compose.prod.yml logs api

# Check environment
docker compose -f docker-compose.prod.yml exec api env
```

### Health check failed
```bash
# Test thủ công
curl http://localhost:5000/health

# Check database connection từ container
docker compose -f docker-compose.prod.yml exec api dotnet ef database info
```

## Best Practices

1. **Luôn tạo migration mới** khi thay đổi model
2. **Test migration local** trước khi push
3. **Review SQL script** trước khi apply production
4. **Backup database** trước khi apply migration lớn
5. **Zero-downtime**: Thiết kế migration không lock table nếu có thể
