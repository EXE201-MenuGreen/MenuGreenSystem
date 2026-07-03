# MenuGreen Deployment - Review & Gap Analysis

## Tổng quan
Mình đã review toàn bộ codebase so với plan deploy. Kết quả: **plan có hướng đúng, nhưng có một số điểm đã được implement sẵn, và có bug thực tế cần fix ngay**.

---

## 1. Current State Analysis (Code thực tế)

### 1.1 CI/CD (`.github/workflows/ci-cd.yml`)
**Đã có sẵn:**
- Doppler secrets download + .env build logic ✅
- Upload .env to server ✅
- docker compose down/up flow ✅
- Container cleanup before deploy ✅
- Health check after deploy ✅

**Vấn đề thực tế:**
```yaml
# Line 294 - MIGRATION CHẠY TRONG CONTAINER API
docker compose -f docker-compose.prod.yml exec api dotnet ef database update \
  --project backend/MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj \
  --startup-project backend/MenuGreen.API/MenuGreen.API.csproj
```
- **Container API không có dotnet-ef tool** → lệnh này sẽ fail
- Đây có thể là **root cause** của deployment failure bạn đã gặp

### 1.2 `docker-compose.prod.yml`
**Đã có sẵn:**
- Redis với memory limit 256M ✅
- Redis maxmemory policy ✅
- Healthcheck cho Redis ✅
- Healthcheck cho API ✅
- External network menugreen-net ✅

**Thiếu:**
- Memory limit cho API container
- API mem_limit cần thêm ~600-800M cho 2GB RAM server

### 1.3 `Dockerfile`
**Đã tối ưu:**
- Multi-stage build (sdk → publish → aspnet) ✅
- Không có migration bundle trong image ✅
- curl được cài cho healthcheck ✅
- Chỉ ~200-300MB image size ✅

**Không cần thay đổi** theo plan.

### 1.4 `Program.cs`
**Vấn đề CRITICAL - Redis config mismatch:**

```csharp
// Line 45-47 - Program.cs ĐANG ĐỌC:
var redisConnection =
    builder.Configuration["Redis:ConnectionString"]
    ?? Environment.GetEnvironmentVariable("REDIS_URL");

// Nhưng CI đang TẠO .env với key:
ConnectionStrings__Redis=menugreen_redis:6379

// KẾT QUẢ: Redis connection = null → fallback to DistributedMemoryCache
// KHÔNG dùng Redis thật! Cache không hoạt động!
```

**Health checks đã đúng:**
- `/health` - tất cả checks ✅
- `/health/ready` - chỉ ready tags ✅  
- `/health/live` - always healthy ✅

**Lưu ý khác:**
- Line 143: JWT có fallback secret key hardcoded - **security risk**, nên fix
- Line 270-278: HTTPS redirect + RateLimiter chỉ chạy non-development

### 1.5 `scripts/deploy.sh`
**Có điểm tốt hơn CI hiện tại:**
- Database backup trước khi migrate ✅
- Migration chạy bằng SDK container tạm (đúng best practice) ✅
- Health check đầy đủ ✅

**Nhưng có vấn đề:**
- Dùng `docker run` thay vì `docker compose` → không dùng compose file
- Không giống CI flow → gây confusion
- Monitoring stack chỉ có trong deploy.sh, không trong CI

---

## 2. So sánh Plan vs Reality

| Điểm | Plan đề xuất | Code hiện tại | Trạng thái |
|------|-------------|---------------|------------|
| Migration bundle | Build efbundle trong CI, chạy trên host | Chạy `dotnet ef` trong container API | ❌ Sai - cần fix |
| Dockerfile tối giản | Xóa stage migration | Đã tối giản | ✅ OK |
| Redis connection | `ConnectionStrings:Redis` | CI tạo `ConnectionStrings__Redis` | ❌ Mismatch |
| Health check | `/health/live` trước, `/health/ready` sau | Chỉ check `/health/ready` | ⚠️ Cần cải thiện |
| Memory limits | Redis 256M, API 800M | Redis 256M, API không có | ⚠️ Cần thêm API limit |
| Config validation | Verify .env sau upload | Có verify Doppler secrets | ✅ OK |
| Pre-flight check | Script kiểm tra server | Chưa có | ⏳ Cần thêm |

---

## 3. Critical Fixes Cần Làm Ngay

### Fix 1: Redis Connection String Mismatch (CRITICAL)
**Vấn đề:** CI tạo `ConnectionStrings__Redis` nhưng Program.cs đọc `Redis:ConnectionString`

**Giải pháp A (Khuyến nghị - sửa Program.cs):**
```csharp
// Thêm fallback cho ConnectionStrings:Redis
var redisConnection =
    builder.Configuration["Redis:ConnectionString"]
    ?? builder.Configuration["ConnectionStrings:Redis"]  // Thêm dòng này
    ?? Environment.GetEnvironmentVariable("REDIS_URL");
```

**Giải pháp B (Đổi CI):**
```bash
# Trong ci-cd.yml, thay:
echo "ConnectionStrings__Redis=${REDIS_URL}" >> .env

# Bằng:
echo "Redis__ConnectionString=${REDIS_URL}" >> .env
```

### Fix 2: Migration Strategy (CRITICAL)
**Vấn đề:** Migration chạy trong container không có SDK

**Giải pháp:** Dùng efbundle như plan đề xuất, hoặc ít nhất là SDK container tạm:
```bash
# Trong CI, thay:
docker compose exec api dotnet ef database update ...

# Bằng:
docker run --rm \
  --env-file "$APP_DIR/.env" \
  -v "$APP_DIR/backend:/src/backend" \
  -w /src/backend \
  mcr.microsoft.com/dotnet/sdk:9.0 \
  dotnet ef database update \
    --project MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj \
    --startup-project MenuGreen.API/MenuGreen.API.csproj
```

Hoặc tốt hơn: build efbundle trong CI như plan.

### Fix 3: Memory Limit cho API
**Cần thêm vào `docker-compose.prod.yml`:**
```yaml
  api:
    # ...
    deploy:
      resources:
        limits:
          memory: 800M
          cpus: '1.0'
```

### Fix 4: Health Check Strategy
**Cải thiện CI health check:**
```yaml
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

### Fix 5: JWT Secret Fallback (Security)
**Program.cs line 143:**
```csharp
// ❌ HIỆN TẠI - có fallback hardcoded
var secretKey = builder.Configuration["JwtSettings:SecretKey"] ?? "super_secret_key_menu_green_1234567890_super_long";

// ✅ NÊN THAY - fail nếu không có secret
var secretKey = builder.Configuration["JwtSettings:SecretKey"];
if (string.IsNullOrEmpty(secretKey))
{
    throw new InvalidOperationException("JWT SecretKey is not configured");
}
```

---

## 4. Plan Optimization Recommendations

### Những gì đã tốt, giữ nguyên:
- Dockerfile đã tối giản, không cần sửa
- Redis memory limit đã có
- Health check endpoints đã đúng cấu trúc
- Doppler integration đã tốt
- docker-compose structure đã tốt

### Những gì cần cập nhật trong plan:

1. **Bỏ phần Dockerfile** - đã tối ưu sẵn
2. **Cập nhật Program.cs** - thêm Redis fallback
3. **Thay đổi migration strategy** - dùng efbundle hoặc SDK container
4. **Thêm memory limit cho API** trong compose
5. **Cải thiện health check** trong CI
6. **Thêm pre-flight script** vào repo
7. **Fix JWT secret** - bỏ fallback

---

## 5. Execution Order (Revised)

```
IMMEDIATE FIXES (Trước khi deploy)
├── 1. Fix Redis connection trong Program.cs (thêm fallback)
├── 2. Thêm mem_limit cho API trong docker-compose.prod.yml
├── 3. Cải thiện health check trong ci-cd.yml
└── 4. Commit và push

SERVER PREPARATION
├── 5. Provision Lightsail $12/tháng
├── 6. Chạy server_preflight_check.sh
├── 7. Cài Docker + Compose (nếu cần)
├── 8. Tạo network menugreen-net
├── 9. Config Firewall
└── 10. Tạo .env ban đầu

CI/CD UPDATE
├── 11. Cập nhật migration strategy trong ci-cd.yml
├── 12. Thêm verify config trên server step
└── 13. Push lại

FIRST DEPLOY
├── 14. CI tự deploy
├── 15. Verify containers + logs
├── 16. Test health endpoints
└── 17. Test API thực tế
```

---

## 6. Conclusion

**Plan hiện tại có hướng đúng** nhưng cần điều chỉnh:
- **Đã tốt:** Dockerfile, Redis config, Doppler integration
- **Cần fix ngay:** Redis connection mismatch, migration trong container
- **Cần thêm:** API memory limit, pre-flight script, health check improvement

**Ưu tiên hành động:**
1. Fix Redis config (bắt API thực sự dùng Redis)
2. Fix migration strategy (đừng chạy ef trong container)
3. Thêm memory limit cho API
4. Thêm pre-flight script

Sau khi fix 4 điểm trên, deploy sẽ ổn định hơn rất nhiều.
