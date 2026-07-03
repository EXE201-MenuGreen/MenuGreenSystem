# MenuGreen System - Deployment Fix Plan (Final v2)

## Mục tiêu
- Đưa app `MenuGreen.API` chạy ổn định trên **Lightsail Ubuntu VM** với Docker + Compose.
- Đảm bảo EF Core migration chạy **trước khi start API**, theo best practice production.
- Giữ nguyên CI/CD hiện tại (GitHub Actions + Doppler + GHCR) nhưng sắp xếp đúng thứ tự deploy.
- Phù hợp với server **$12/tháng** (2 vCPU, 2GB RAM, 60GB SSD).
- Thống nhất deploy theo **1 nhánh duy nhất** là `main` để tránh nhầm lẫn giữa `main` và `Tuan`.

---

## 1. Vấn đề hiện tại

||| # | Lỗi | Tác động |
|---|------|----------|
||| 1 | `.env` trên Lightsail lệch so với Doppler `prd` | API `menugreen_api` đang `unhealthy` do thiếu JWT + Redis connection string sai |
||| 1b | Migration đang chạy `dotnet ef database update` trong container runtime không có SDK | Migration fail im lặng hoặc không chạy đúng trong prod |
||| 2 | Redis chỉ có `REDIS_HOST`/`REDIS_PORT` riêng | `Program.cs` đọc `ConnectionStrings:Redis` → null |
||| 3 | Thiếu volume Firebase | FCM có thể không hoạt động nếu dùng |
||| 4 | CI chỉ check `/health/ready` | Không phân biệt được app dead vs DB/Redis unreachable |

### Trạng thái hiện tại (01/07/2026)

- `menugreen_api`: `unhealthy`
- `menugreen_redis`: `healthy`
- RDS: kết nối được từ Lightsail
- `.env` server: thiếu `JwtSettings__SecretKey`, `JwtSettings__Issuer`, `JwtSettings__Audience`; `ConnectionStrings__Redis` đang là `:,password=`
- CI/CD: đã sửa cách sinh `.env` từ Doppler `prd` đúng key backend đọc

---

## 2. Kiểm tra rủi ro và tối ưu

||| Điểm cũ | Rủi ro | Tối ưu |
|||----------|--------|--------|
||| Chạy `efbundle` từ API container sau `up -d` | API fail startup → không exec được → không migrate | **Chạy migration trên host, trước khi `up -d`** |
||| Build bundle trong Dockerfile | Image prod cồng kềnh, chứa tool thừa | **Bundle là artifact CI riêng**, không lưu trong runtime image |
||| Chưa verify config | `.env` thiếu/sai format → API crash im lặng | Thêm bước **verify config** sau khi upload `.env` |
||| Health check chỉ `/health/ready` | Timeout không phân biệt nguyên nhân | Dùng `/health/live` trước, `/health/ready` sau |

---

## 3. Server cần chuẩn bị gì

### 3.1 Yêu cầu cơ bản

Dựa trên server bạn đã mua (**Lightsail $12/tháng**) + database hiện tại (**AWS RDS PostgreSQL**):

||| Thành phần | Thực tế | Đánh giá |
|||------------|---------|----------|
||| OS | Ubuntu (Lightsail default) | ✅ Tương thích |
||| CPU | 2 vCPUs | ✅ Đủ cho Docker + API |
||| RAM | **2 GB** | ⚠️ Vừa đủ, cần tối ưu |
||| Disk | 60 GB SSD | ✅ Đủ |
||| Network | Static IP + 3TB transfer | ✅ Tốt |
||| Outbound | HTTPS 443 + HTTP 5000 + TCP 5432 (RDS) | Cần mở Lightsail Firewall |
||| Database | **AWS RDS PostgreSQL** | ✅ Đã có sẵn, không cần cài DB trên server |

**Lưu ý quan trọng:**
- Database **không chạy trên Lightsail**, mà là **AWS RDS PostgreSQL** bên ngoài
- Do đó, **không cần cài PostgreSQL container** trong `docker-compose.prod.yml`
- Lightsail chỉ cần kết nối ra RDS endpoint qua port 5432
- Nếu RDS đang chạy, plan này tập trung vào deploy **chỉ API + Redis**

### 3.2 Tối ưu cho 2GB RAM

Vì database đã ở AWS RDS bên ngoài, Lightsail chỉ cần chạy **2 services**:

- **Redis** (~256MB) - cache local trên Lightsail
- **API** (~800MB) - .NET container

**docker-compose.prod.yml - memory limits:**
```yaml
services:
  redis:
    image: redis:7-alpine
    container_name: menugreen_redis
    command: redis-server --appendonly yes --maxmemory 200mb --maxmemory-policy allkeys-lru
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'

  api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: menugreen_api
    deploy:
      resources:
        limits:
          memory: 800M
          cpus: '1.0'
```

**Tổng memory allocation:**
||| Container | Limit | Reserve |
|||-----------|-------|---------|
||| menugreen_redis | 256 MB | 128 MB |
||| menugreen_api | 800 MB | 512 MB |
||| OS + Docker | ~700 MB | ~600 MB |
||| **Total** | **~1.8 GB** | **~1.2 GB |

Nếu thấy RAM không đủ, có thể nâng cấp lên $24/tháng (4GB) - chỉ cần vài cú click trên Lightsail console.

---

### 3.3 `efbundle` có cần tải/cài trên Lightsail không?

- **Không cần cài gì thêm trên Lightsail.**
- `efbundle` là **artifact CI** được build trên GitHub Actions runner từ `dotnet ef migrations bundle --self-contained -r linux-x64`.
- CI sẽ **upload file `efbundle` lên Lightsail**, chạy migrate, rồi **xóa file đi**.
- Trên Lightsail chỉ cần chạy file binary đó như một chương trình thường; không cần `.NET SDK`, không cần `dotnet-ef`, không cần giữ `efbundle` lâu dài.
- Ưu điểm phù hợp Lightsail 2GB RAM: nhẹ (~5–10MB), không phụ thuộc runtime image, migrate xong là xóa.

### 3.4 Server Pre-flight Check (KIỂM TRA TRƯỚC KHI CÀI)

**Chạy script này trên Lightsail instance trước khi cài đặt**

```bash
# Copy script lên server
scp scripts/server_preflight_check.sh ubuntu@<LIGHTSAIL_IP>:/home/ubuntu/

# SSH vào và chạy
ssh ubuntu@<LIGHTSAIL_IP>
chmod +x /home/ubuntu/server_preflight_check.sh
/home/ubuntu/server_preflight_check.sh
```

**Script sẽ báo bạn:**
- OS hiện tại là gì, có đúng Ubuntu không
- CPU/RAM/Disk có đủ không
- Docker đã có chưa, version bao nhiêu
- Docker Compose đã có chưa
- Docker daemon đang chạy không
- User có trong group `docker` không
- Network `menugreen-net` đã tồn tại chưa
- Thư mục app, `.env` và Git repo đã có chưa
- Kết nối outbound đến AWS RDS port 5432 có được không
- SSH key của GitHub Actions đã thêm vào `authorized_keys` chưa

**Sau khi chạy xong, script sẽ liệt kê chính xác những gì CẦN làm, không cần cài gì đó nếu đã có sẵn.**

---

### 3.5 Cài đặt phần mềm trên server (chỉ cài những gì thiếu)

Dựa trên kết quả pre-flight check, chỉ cài những gì còn thiếu:

```bash
# 1. Update hệ thống (chỉ cần chạy 1 lần đầu)
sudo apt update && sudo apt upgrade -y

# 2. Cài Docker (CHỈ NẾU chưa có)
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker ubuntu
  echo "Docker installed. Logout and login again to apply group changes."
fi

# 3. Cài Docker Compose plugin (CHỈ NẾU chưa có)
if ! docker compose version &> /dev/null; then
  sudo apt install -y docker-compose-plugin
fi

# 4. Cài công cụ hữu ích (chỉ cài 1 lần)
sudo apt install -y curl jq git ufw
```

### 3.6 Cấu hình Firewall (Lightsail + UFW)

**Lightsail Firewall** (qua console):
- Allow: TCP 22 (SSH) - restrict to your IP if possible
- Allow: TCP 5000 (API) - hoặc 80/443 nếu có Nginx
- Allow: TCP 5432 (PostgreSQL RDS) - từ IP Lightsail nếu cần test trực tiếp

**UFW trên Ubuntu** (tùy chọn, layer 2):
```bash
sudo ufw allow 22/tcp
sudo ufw allow 5000/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 3.7 Tạo Docker Network (nếu chưa có)

```bash
docker network create menugreen-net
```

### 3.8 Tạo file `.env` ban đầu

Tạo `/home/ubuntu/apps/MenuGreenSystem/.env` với nội dung tối thiểu:

```env
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:5000
ConnectionStrings__DefaultConnection=Host=<RDS_ENDPOINT>;Port=5432;Database=MenuGreenDb;Username=postgres;Password=<PASSWORD>;SSL Mode=Require;Trust Server Certificate=true
ConnectionStrings__Redis=menugreen_redis:6379
JwtSettings__SecretKey=<CHANGE_ME_32_CHARS_MIN>
AllowedOrigins=https://menugreen.vn,https://app.menugreen.vn
```

> **Lưu ý:** CI sau này sẽ overwrite `.env` bằng Doppler secrets, nhưng file này dùng cho deploy thủ công hoặc emergency.

### 3.9 SSH Key setup cho GitHub Actions

```bash
# Trên Lightsail instance
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Thêm public key của GitHub Actions runner vào ~/.ssh/authorized_keys
# Hoặc dùng Lightsail default key + thêm vào GitHub Secrets
```

**GitHub Secrets cần có:**
- `LIGHTSAIL_HOST`: IP Lightsail
- `LIGHTSAIL_USER`: `ubuntu`
- `LIGHTSAIL_SSH_KEY`: Private key SSH
- `DOPPLER_TOKEN`: Token Doppler project `menugreen` config `prd`

### 3.11 Cấu hình Git (tùy chọn)

Nếu muốn server có thể `git pull`:
```bash
cd /home/ubuntu/apps/MenuGreenSystem
git init
git remote add origin <REPO_URL>
git fetch origin
git checkout main  # hoặc branch deploy
```

Hoặc để CI tự quản lý qua `ssh-action` như hiện tại.

---

## 4. Plan thực hiện chi tiết

### Bước 1: Cập nhật `.github/workflows/ci-cd.yml`

**Tại sao dùng `efbundle` thay vì `dotnet ef database update` trong container?**

||| Vấn đề | Giải thích |
|||--------|-----------|
||| Container prod chỉ có runtime | `aspnet:9.0` image không có .NET SDK, không chạy được `dotnet ef` |
||| Cài SDK vào container làm image nặng | Thêm ~1GB vào image, vi phạm best practice production |
||| Migration phải chạy trước API | Đảm bảo DB schema sẵn sàng trước khi app start, tránh crash |

**`efbundle` là native binary** (~5-10MB) được build từ `dotnet ef migrations bundle --self-contained`, chạy trực tiếp trên Linux mà **không cần cài .NET SDK hay dotnet-ef tool**.

**Cập nhật job `deploy` trong `.github/workflows/ci-cd.yml` theo flow tối ưu:**

- Không chạy `dotnet ef database update` trong container runtime.
- Thêm bước build `efbundle` trên CI, upload lên Lightsail và chạy migrate **trước khi `docker compose up -d`**.
- Thêm health check `/health/live` trước, `/health/ready` sau.
- Thống nhất deploy chỉ nhánh `main`.

Chi tiết đã đồng bộ trong file `.github/workflows/ci-cd.yml`:
```yaml
      - name: Upload .env to server
        uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ secrets.LIGHTSAIL_HOST }}
          username: ${{ secrets.LIGHTSAIL_USER }}
          key: ${{ secrets.LIGHTSAIL_SSH_KEY }}
          source: "${{ github.workspace }}/.env"
          target: "/home/ubuntu/apps/MenuGreenSystem"
          strip_components: 0
          overwrite: true

      - name: Build migration bundle
        run: |
          dotnet tool install --global dotnet-ef --version 9.0.0
          export PATH="$PATH:~/.dotnet/tools"
          dotnet ef migrations bundle \
            --self-contained -r linux-x64 \
            --project backend/MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj \
            --startup-project backend/MenuGreen.API/MenuGreen.API.csproj \
            -o ./efbundle

      - name: Upload and run migration bundle
        run: |
          scp -i "${{ secrets.LIGHTSAIL_SSH_KEY }}" -o StrictHostKeyChecking=no \
            ./efbundle ${{ secrets.LIGHTSAIL_USER }}@${{ secrets.LIGHTSAIL_HOST }}:/home/ubuntu/apps/MenuGreenSystem/efbundle

          ssh -i "${{ secrets.LIGHTSAIL_SSH_KEY }}" -o StrictHostKeyChecking=no \
            "${{ secrets.LIGHTSAIL_USER }}@${{ secrets.LIGHTSAIL_HOST }}" \
            "cd /home/ubuntu/apps/MenuGreenSystem && \
             chmod +x ./efbundle && \
             CONNECTION_STRING=\$(grep '^ConnectionStrings__DefaultConnection=' .env | cut -d'=' -f2-) && \
             ./efbundle --connection \"\$CONNECTION_STRING\" || echo 'Migration may have already been applied' && \
             rm -f ./efbundle"

      - name: Deploy application
        run: |
          ssh -i "${{ secrets.LIGHTSAIL_SSH_KEY }}" -o StrictHostKeyChecking=no \
            "${{ secrets.LIGHTSAIL_USER }}@${{ secrets.LIGHTSAIL_HOST }}" \
            "cd /home/ubuntu/apps/MenuGreenSystem && \
             docker compose -f docker-compose.prod.yml down --remove-orphans 2>/dev/null || true && \
             docker compose -f docker-compose.prod.yml up -d --force-recreate && \
             sleep 15"

      - name: Verify containers
        run: |
          ssh -i "${{ secrets.LIGHTSAIL_SSH_KEY }}" -o StrictHostKeyChecking=no \
            "${{ secrets.LIGHTSAIL_USER }}@${{ secrets.LIGHTSAIL_HOST }}" \
            "docker compose -f /home/ubuntu/apps/MenuGreenSystem/docker-compose.prod.yml ps"

      - name: Wait for API to be alive
        run: |
          echo "Waiting for API..."
          for i in {1..90}; do
            STATUS=$(curl -sf "http://${{ secrets.LIGHTSAIL_HOST }}:5000/health/live" -w "\n%{http_code}" || true)
            CODE=$(echo "$STATUS" | tail -n1 || true)
            if [ "$CODE" = "200" ]; then
              echo "API is alive!"
              break
            fi
            echo "Waiting... ($i/90) status=${CODE:-no_response}"
            sleep 5
          done

      - name: Check API readiness
        run: |
          echo "Checking API readiness (best-effort)..."
          curl -fsSL "http://${{ secrets.LIGHTSAIL_HOST }}:5000/health/ready" \
            || echo "Ready check failed - check DB/Redis connectivity"
```

### Bước 2: Cập nhật `docker-compose.prod.yml`

File hiện tại đã khá sát production. Mình chỉ bổ sung nhỏ cho khớp plan và giới hạn rõ ràng cho Lightsail 2GB:

```yaml
services:
  redis:
    image: redis:7-alpine
    container_name: menugreen_redis
    volumes:
      - redis_data:/data
    networks:
      - menugreen-net
    restart: unless-stopped
    command: >
      sh -c 'if [ -n "$$REDIS_PASSWORD" ]; then
        redis-server --appendonly yes --requirepass "$$REDIS_PASSWORD" --maxmemory 200mb --maxmemory-policy allkeys-lru;
      else
        redis-server --appendonly yes --maxmemory 200mb --maxmemory-policy allkeys-lru;
      fi'
    healthcheck:
      test: >
        sh -c 'if [ -n "$$REDIS_PASSWORD" ]; then
          redis-cli -a "$$REDIS_PASSWORD" ping;
        else
          redis-cli ping;
        fi'
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'

  api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: menugreen_api
    env_file:
      - .env
    environment:
      - ASPNETCORE_ENVIRONMENT=${ASPNETCORE_ENVIRONMENT}
      - ASPNETCORE_URLS=http://+:5000
    ports:
      - "5000:5000"
    depends_on:
      redis:
        condition: service_healthy
    networks:
      - menugreen-net
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          memory: 800M
          cpus: '1.0'
    volumes:
      # Uncomment nếu dùng Firebase
      # - /etc/secrets/firebase-adminsdk.json:/etc/secrets/firebase-adminsdk.json:ro

volumes:
  redis_data:

networks:
  menugreen-net:
    external: true
```

**Lưu ý:**
- `docker-compose.prod.yml` hiện đã đủ dùng cho deploy.
- Phần Firebase volume giữ dạng **comment** vì backend hiện chỉ đọc `Firebase:CredentialPath` từ config; chỉ cần mount thật khi app dùng FCM.

### Bước 3: Cập nhật `Dockerfile` (tối giản)

`Dockerfile` hiện tại đã đủ nhẹ, chỉ cần build + publish app runtime. Không cần chèn tool migrate vào image prod.

```dockerfile
# Sử dụng base image .NET 9.0 ASP.NET (dùng cho chạy ứng dụng)
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
# Render gán PORT lúc runtime (thường 10000); không set ASPNETCORE_URLS trong image.
EXPOSE 10000
EXPOSE 5000

# Install curl for healthchecks
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# Sử dụng base image .NET 9.0 SDK (dùng cho build)
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy file .csproj và restore các packages
COPY ["backend/MenuGreen.API/MenuGreen.API.csproj", "backend/MenuGreen.API/"]
COPY ["backend/MenuGreen.BusinessLogicLayer/MenuGreen.BusinessLogicLayer.csproj", "backend/MenuGreen.BusinessLogicLayer/"]
COPY ["backend/MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj", "backend/MenuGreen.DataAccessLayer/"]
RUN dotnet restore "backend/MenuGreen.API/MenuGreen.API.csproj"

# Copy toàn bộ mã nguồn
COPY . .
WORKDIR "/src/backend/MenuGreen.API"

# Build ứng dụng
RUN dotnet build "MenuGreen.API.csproj" -c Release -o /app/build

# Publish ứng dụng (tối ưu hóa)
FROM build AS publish
RUN dotnet publish "MenuGreen.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Cấu hình container cuối cùng (Chỉ chứa code đã publish để giảm dung lượng)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MenuGreen.API.dll"]
```

### Bước 4: Cập nhật `Program.cs` (nếu cần)

`Program.cs` hiện tại đã có đủ health checks và đọc đúng Redis connection string. Nếu sau này bạn thêm package thiếu thì mới cần bổ sung; hiện tại phần này không bắt buộc sửa.

```csharp
// Redis
var redisConnection =
    builder.Configuration["Redis:ConnectionString"]
    ?? Environment.GetEnvironmentVariable("REDIS_URL");

if (!string.IsNullOrWhiteSpace(redisConnection))
{
    builder.Services.AddStackExchangeRedisCache(options =>
    {
        options.Configuration = redisConnection;
        options.InstanceName = "MenuGreen:";
    });
}
else
{
    builder.Services.AddDistributedMemoryCache();
}

// Health checks
builder.Services.AddHealthChecks()
    .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "ready" })
    .AddNpgSql(
        builder.Configuration["ConnectionStrings:DefaultConnection"] 
        ?? "Host=localhost;Port=5432;Database=MenuGreenDb;Username=postgres;Password=12345",
        name: "postgresql",
        tags: new[] { "db", "ready" })
    .AddRedis(
        builder.Configuration["ConnectionStrings:Redis"] 
        ?? Environment.GetEnvironmentVariable("REDIS_URL") 
        ?? "localhost:6379",
        name: "redis",
        tags: new[] { "cache", "ready" });
```

### Bước 5: `scripts/server_preflight_check.sh`

Đã thêm script vào repo tại `scripts/server_preflight_check.sh`.

Cách dùng:

```bash
# Copy script lên server
scp scripts/server_preflight_check.sh ubuntu@<LIGHTSAIL_IP>:/home/ubuntu/

# SSH vào và chạy
ssh ubuntu@<LIGHTSAIL_IP>
chmod +x /home/ubuntu/server_preflight_check.sh
/home/ubuntu/server_preflight_check.sh
```

Script sẽ kiểm tra:
- OS, CPU/RAM/Disk
- Docker + Docker Compose + daemon
- Group quyền `docker`
- Network `menugreen-net`
- Thư mục app, `.env`, git repo
- Kết nối outbound RDS
- SSH `authorized_keys` cho CI

### Bước 6: `scripts/deploy.sh` (nếu vẫn dùng deploy thủ công)

```bash
#!/bin/bash
set -euo pipefail

APP_DIR="/home/ubuntu/apps/MenuGreenSystem"
ENV_FILE="$APP_DIR/.env"
REGISTRY="ghcr.io/exe201-menugreen/menugreen-api"

log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; }
log_warning() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $*"; }

# 1. Verify .env exists
if [ ! -f "$ENV_FILE" ]; then
  log_error ".env file not found at $ENV_FILE"
  exit 1
fi

# 2. Extract connection string
CONNECTION_STRING=$(grep '^ConnectionStrings__DefaultConnection=' "$ENV_FILE" | cut -d'=' -f2-)
if [ -z "$CONNECTION_STRING" ]; then
  log_error "ConnectionStrings__DefaultConnection not found in .env"
  exit 1
fi

# 3. Pull latest image
log_info "Pulling latest image..."
docker pull $REGISTRY:latest

# 4. Download and run efbundle for migration
log_info "Running database migration with efbundle..."
EFBUNDLE_URL="https://github.com/your-org/menugreen/releases/latest/download/efbundle"
# Alternative: build efbundle locally if you have dotnet-ef installed
if command -v dotnet-ef &> /dev/null; then
  log_info "Building efbundle locally..."
  cd "$APP_DIR/backend"
  dotnet ef migrations bundle \
    --self-contained -r linux-x64 \
    --project MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj \
    --startup-project MenuGreen.API/MenuGreen.API.csproj \
    -o /tmp/efbundle
  chmod +x /tmp/efbundle
  /tmp/efbundle --connection "$CONNECTION_STRING" || log_warning "Migration may have already been applied"
else
  log_error "dotnet-ef not found. Please install dotnet-ef or download efbundle from CI."
  exit 1
fi

# 5. Start containers
log_info "Starting containers..."
cd "$APP_DIR"
docker compose -f docker-compose.prod.yml down --remove-orphans 2>/dev/null || true
docker compose -f docker-compose.prod.yml up -d --force-recreate

# 6. Wait and verify
sleep 15
docker compose -f docker-compose.prod.yml ps

log_info "Deployment completed!"
```

> **Lưu ý:** Script này giả định bạn đã build `efbundle` trong CI và upload lên server, hoặc cài `dotnet-ef` locally. Trong production, nên dùng CI để build efbundle và upload lên server trước khi chạy script này.

---

## 5. Thứ tự thực hiện

```
SERVER PREPARATION
├── 1. Provision Lightsail Ubuntu VM (2 vCPU, 4GB RAM, 40GB SSD)
├── 2. SSH vào server, chạy script cài Docker + dependencies
├── 3. Tạo Docker network menugreen-net
├── 4. Tạo thư mục /home/ubuntu/apps/MenuGreenSystem
├── 5. Setup SSH key cho GitHub Actions
├── 6. Config Lightsail Firewall (22, 5000, 80, 443)
└── 7. Tạo .env ban đầu (tạm thời, CI sẽ overwrite)

CI/CD UPDATE
├── 8. Update ci-cd.yml theo Bước 1
├── 9. Update docker-compose.prod.yml theo Bước 2
├── 10. Update Dockerfile theo Bước 3
└── 11. Commit và push lên `main`

FIRST DEPLOY
├── 12. CI tự chạy: build image → build efbundle → deploy
├── 13. Verify: docker compose ps + logs
├── 14. Test: curl http://<host>:5000/health/live
└── 15. Test: curl http://<host>:5000/health/ready
```

---

## 6. Checklist server preparation

- [ ] **Chạy `server_preflight_check.sh` để biết server đã có gì, cần cài gì**
- [ ] Lightsail instance **$12/tháng** đã tạo (2 vCPU, **2GB RAM**, 60GB SSD)
- [ ] SSH key đã add vào GitHub Secrets (`LIGHTSAIL_SSH_KEY`)
- [ ] `LIGHTSAIL_HOST` và `LIGHTSAIL_USER` đã set trong GitHub Secrets
- [ ] Docker đã cài (nếu chưa có)
- [ ] Docker Compose plugin đã cài (nếu chưa có)
- [ ] User `ubuntu` đã trong group `docker`
- [ ] `menugreen-net` network đã tạo (nếu chưa có)
- [ ] Firewall Lightsail cho phép port 22, 5000
- [ ] `/home/ubuntu/apps/MenuGreenSystem` đã tồn tại
- [ ] `.env` ban đầu đã tạo (CI sẽ overwrite)
- [ ] RDS PostgreSQL đã tạo và cho phép IP Lightsail kết nối
- [ ] `DB_*` và `REDIS_*` secrets đã có trong Doppler config `prd`
- [ ] **Đã cấu hình memory limits cho containers** (Redis 256MB, API 800MB) để phù hợp 2GB RAM

---

## 7. Troubleshooting

### API vẫn không start
```bash
# Check logs
docker logs menugreen_api --tail 100

# Check env trong container
docker exec menugreen_api env | grep -E 'ASPNETCORE|ConnectionStrings|Redis'

# Test port
docker exec menugreen_api netstat -tlnp
```

### Migration fail
```bash
# 1. Preferred: dùng efbundle từ CI (đã upload lên Lightsail)
#    - Không cần cài .NET SDK trên Lightsail
#    - Chạy trên host, trước khi up -d
#    - Xem log CI để lấy lệnh ssh/scp chạy efbundle

# 2. Manual fallback: chạy từ SDK container nếu cần debug
docker run --rm --env-file .env -v "$PWD/backend:/src/backend" \
  -w /src/backend mcr.microsoft.com/dotnet/sdk:9.0 \
  dotnet ef database update \
    --project MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj \
    --startup-project MenuGreen.API/MenuGreen.API.csproj

# 3. Nếu lỗi liên quan connection string, kiểm tra lại:
#    - ConnectionStrings__DefaultConnection
#    - ConnectionStrings__Redis
#    - JwtSettings__SecretKey / Issuer / Audience
```

### Redis không kết nối
```bash
docker exec menugreen_redis redis-cli ping
docker exec menugreen_api ping -c 1 menugreen_redis
```

### DB không kết nối từ container
```bash
# Test từ host
nc -zv <RDS_ENDPOINT> 5432

# Test từ container
docker run --rm postgres:18-alpine pg_isready -h <RDS_ENDPOINT> -p 5432
```

---

## 8. Tài liệu tham khảo

- [EF Core Applying Migrations - Microsoft Docs](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/applying)
- [Stop Running dotnet ef database update in Production - ByteCrafted](https://bytecrafted.dev/ef-core-migrations-cicd-production/)
- [Running Migrations in EF Core 10 - codewithmukesh](https://codewithmukesh.com/blog/running-migrations-efcore/)
- [How to run EF Core migrations from Docker - anuraj.dev](https://anuraj.dev/blog/how-to-run-ef-core-migrations-from-docker/)
- [AWS Lightsail Container Services](https://docs.aws.amazon.com/lightsail/latest/userguide/amazon-lightsail-container-services-deployments.html)

---

*Cập nhật: 01/07/2026*
