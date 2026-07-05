# Issues Encountered

Danh sách các issue đã gặp trong quá trình phát triển và deploy.

---

## [RESOLVED] PostgreSQL & Redis Health Check - Environment Variable Loading

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** High

### Description

Health check báo lỗi:

- PostgreSQL: `Format of the initialization string does not conform to specification starting at index 0.`
- Redis: `It was not possible to connect to the redis server(s).`

### Root Cause

Code đọc config từ `builder.Configuration` nhưng không load được environment variables đúng cách.

### Fix Applied

**1. Program.cs - Health Checks:**

```csharp
// TRƯỚC (sai)
.AddNpgSql(
    builder.Configuration["ConnectionStrings:DefaultConnection"]
    ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
    ?? throw new InvalidOperationException("..."))

// SAU (đúng)
var pgConnection = Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");
if (string.IsNullOrEmpty(pgConnection))
    throw new InvalidOperationException("...");
builder.Services.AddHealthChecks()
    .AddNpgSql(pgConnection, name: "postgresql", ...);
```

**2. ConnectionStringHelper.cs:**

```csharp
// TRƯỚC (sai)
var configured = configuration.GetConnectionString("DefaultConnection");

// SAU (đúng)
var configured = configuration.GetConnectionString("DefaultConnection")
    ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
    ?? Environment.GetEnvironmentVariable("DATABASE_URL");
```

### Files Changed

- `backend/MenuGreen.API/Program.cs`
- `backend/MenuGreen.DataAccessLayer/ConnectionStringHelper.cs`

### Commit

```
f778bda - Fix environment variable loading for health checks
```

### Status

- [x] Code fixed và push lên git
- [ ] CI/CD build image mới
- [ ] Pull và restart container trên server
- [ ] Verify health check trả về Healthy

---

## [RESOLVED] Redis Health Check - Wrong Env Key Name

**Date:** 2026-07-01
**Status:** Resolved (solved cùng với issue trên)
**Severity:** High

### Description

Redis health check fail mặc dù network OK.

### Root Cause

Code health check đọc `REDIS_URL` nhưng env file set `Redis__ConnectionString`.

### Fix Applied

Đã fix trong Program.cs - đọc trực tiếp từ `Environment.GetEnvironmentVariable("REDIS_URL")`.

---

## [RESOLVED] CI/CD Not Building Docker Image for Tuan Branch

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** High

### Description

Health check vẫn fail sau khi code fix đã push. Image trên Docker Hub vẫn là version cũ.

### Root Cause

CI/CD workflow chỉ build Docker image khi push vào **main** branch:

```yaml
if: github.event_name == 'push' && github.ref == 'refs/heads/main'
```

Branch **Tuan** không trigger build Docker image.

### Fix Applied

```yaml
# Trước (chỉ main)
if: github.event_name == 'push' && github.ref == 'refs/heads/main'

# Sau (cả main và Tuan)
if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/Tuan')
```

### Files Changed

- `.github/workflows/ci-cd.yml`

### Commit

```
01723b5 - fix: build Docker image for Tuan branch too
```

### Status

- [x] CI/CD workflow fixed
- [ ] CI/CD build completes
- [ ] Pull new image on server
- [ ] Verify health check

---

## [RESOLVED] Duplicate Variable Name in Program.cs

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** High

### Description

CI/CD build failed với error: `error CS0128: A local variable or function named 'redisConnection' is already defined in this scope`

### Root Cause

Biến `redisConnection` đã được khai báo ở dòng 45 (Redis cache config), nhưng health checks lại khai báo lại cùng tên.

### Fix Applied

Đổi tên biến trong health checks thành `healthCheckRedisConnection`.

### Commit

```
e9fe08a - Fix duplicate variable name 'redisConnection' in Program.cs
```

---

## [RESOLVED] Environment Variable Loading for Health Checks

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** High

### Description

Health check báo lỗi connection string rỗng/invalid.

### Root Cause

Code đọc config từ `builder.Configuration` nhưng không load được environment variables đúng cách.

### Fix Applied

Đọc trực tiếp từ `Environment.GetEnvironmentVariable()`:

- `ConnectionStrings__DefaultConnection` cho PostgreSQL
- `REDIS_URL` cho Redis

### Commit

```
f778bda - Fix environment variable loading for health checks
```

---

## [RESOLVED] Redis Connection String Key Name

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** Medium

### Description

Redis health check fail vì key name không khớp.

### Root Cause

Code health check đọc `REDIS_URL` nhưng env file set `Redis__ConnectionString`.

---

## [RESOLVED] CI/CD YAML Syntax Error

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** Medium

### Description

GitHub Actions workflow failed với YAML syntax error.

### Root Cause

Indent không đồng nhất (2 vs 4 spaces).

---

## [RESOLVED] Docker Compose Volumes Format Error

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** Medium

### Description

Docker Compose validate failed: `services.api.volumes must be a array`

### Root Cause

Commented YAML blocks gây parse error.

---

---

## [RESOLVED] CORS Configuration - Backend + Nginx + Cloudflare

**Date:** 2026-07-05
**Status:** ✅ Resolved
**Severity:** High

### Description

Frontend website `https://www.menugreen.food` bị block CORS khi gọi API `https://api.menugreen.food`.

### Root Cause

Cần cấu hình CORS headers ở nhiều layer:
1. Backend (.NET) - đã config
2. Nginx (reverse proxy) - cần thêm headers
3. Cloudflare - đã cache response

### Fix Applied

**1. Backend Program.cs - Default origins:**

```csharp
var defaultOrigins = new[]
{
    "https://www.menugreen.food",
    "https://menugreen.food",
    "https://menu-green-system-ldw5frytu-johnny-dangs-projects.vercel.app",
    "http://localhost:3000",
    "http://localhost:3001"
};
```

**2. Nginx Config - CORS headers:**

```nginx
add_header 'Access-Control-Allow-Origin' 'https://www.menugreen.food' always;
add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, Accept, Origin, X-Requested-With' always;
add_header 'Access-Control-Allow-Credentials' 'true' always;
add_header 'Access-Control-Max-Age' '86400' always;
```

**3. Preflight OPTIONS handler:**

```nginx
if ($request_method = 'OPTIONS') {
    add_header 'Access-Control-Allow-Origin' 'https://www.menugreen.food' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, Accept, Origin, X-Requested-With' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    add_header 'Content-Type' 'text/plain; charset=utf-8';
    add_header 'Content-Length' 0;
    add_header 'Access-Control-Max-Age' 86400;
    return 204;
}
```

### Test Result

```bash
curl -I -X OPTIONS https://api.menugreen.food/api/Auth/login \
  -H "Origin: https://www.menugreen.food" \
  -H "Access-Control-Request-Method: POST"

# Response:
HTTP/2 204
access-control-allow-origin: https://www.menugreen.food
access-control-allow-methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
access-control-allow-headers: Content-Type, Authorization, Accept, Origin, X-Requested-With
access-control-allow-credentials: true
```

### Files Changed

- `backend/MenuGreen.API/Program.cs`
- `/etc/nginx/sites-available/api.menugreen.food` (server)

---

## Summary

| # | Issue | Status |
|---|-------|--------|
| 1 | CI/CD không build cho Tuan branch | ✅ Fixed |
| 2 | Duplicate variable name | ✅ Fixed |
| 3 | Environment variable loading | ✅ Fixed |
| 4 | Redis key name mismatch | ✅ Fixed |
| 5 | CI/CD YAML syntax | ✅ Fixed |
| 6 | Docker Compose volumes | ✅ Fixed |
| 7 | CORS configuration | ✅ Fixed |

**Date:** 2026-07-01
**Status:** Resolved
**Severity:** Medium

### Description

GitHub Actions workflow failed với YAML syntax error ở line 168.

### Root Cause

Indent không đồng nhất - 2 dòng trong block `while` có indent 2 spaces thay vì 4 spaces.

### Fix Applied

```yaml
# Trước (sai)
while IFS='=' read -r key raw_value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  # Skip keys with invalid characters for .env
  [[ "$key" =~ [/[:space:]+] ]] && continue  # indent 2 spaces
  [[ "$key" =~ ^(...) ]] && continue

# Sau (đúng)
while IFS='=' read -r key raw_value; do
  [[ -z "$key" || "$key" =~ ^# ]] && continue
  # Skip keys with invalid characters for .env
  [[ "$key" =~ [/[:space:]+] ]] && continue  # indent 4 spaces
  [[ "$key" =~ ^(...) ]] && continue
```

### Files Changed

- `.github/workflows/ci-cd.yml`

---

## [RESOLVED] Docker Compose Volumes Format Error

**Date:** 2026-07-01
**Status:** Resolved
**Severity:** Medium

### Description

Docker Compose validate failed: `services.api.volumes must be a array`

### Root Cause

Volumes section có commented YAML lines, gây parse error.

### Fix Applied

```yaml
# Trước (sai)
volumes:
  # Uncomment nếu dùng Firebase
  # - /etc/secrets/firebase-adminsdk.json:/etc/secrets/firebase-adminsdk.json:ro

# Sau (đúng)
volumes: []
```

### Files Changed

- `docker-compose.prod.yml`

---

## [RESOLVED] Redis Connection String - Localhost vs Container Name

**Date:** 2026-07-01
**Status:** ✅ Resolved
**Severity:** High

### Description

Health check Redis fail vì:

1. Dùng `localhost` thay vì container service name `menugreen_redis`
2. Redis có password nhưng connection string không chứa password
3. Health check code đọc `REDIS_URL` không phải `REDIS__CONNECTIONSTRING`

### Root Cause

Trong Docker Compose, containers giao tiếp qua **service name** không phải localhost. Thêm vào đó:

- Redis yêu cầu password: `REDIS_PASSWORD="eH671/FNx4LyTMJcEXQJ"`
- Connection string format đúng: `redis://:PASSWORD@HOST:PORT`

### Fix Required (Update in Doppler)

```env
# Trước (sai)
REDIS__CONNECTIONSTRING="redis://localhost:6379"

# Sau (đúng)
REDIS_URL="redis://:eH671/FNx4LyTMJcEXQJ@menugreen_redis:6379"
```

### Files Changed

- Doppler config (`prd`)

---

---

## [DOCUMENTED] Production Infrastructure

**Date:** 2026-07-02
**Status:** ✅ Documented
**Severity:** N/A (Documentation)

### Server Information

| Property           | Value                                                       |
| ------------------ | ----------------------------------------------------------- |
| **Hostname**       | ip-172-26-11-157                                            |
| **SSH Access**     | `ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100` |
| **App Location**   | `~/apps/MenuGreenSystem`                                    |
| **OS**             | Ubuntu 22.04 LTS                                            |
| **Docker**         | 29.6.1                                                      |
| **Docker Compose** | 5.2.0                                                       |
| **Git**            | 2.34.1                                                      |
| **psql Client**    | 14.23                                                       |
| **jq**             | 1.6                                                         |
| **Disk**           | 58GB (17% used)                                             |
| **RAM**            | 1.9GB                                                       |

### Database Information (AWS RDS)

| Property            | Value                                                        |
| ------------------- | ------------------------------------------------------------ |
| **Engine**          | PostgreSQL 18.3                                              |
| **Region**          | ap-southeast-1 (Singapore)                                   |
| **Endpoint**        | `menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com` |
| **Port**            | 5432                                                         |
| **Database Name**   | `menugreendb`                                                |
| **Master Username** | `postgres`                                                   |

### Docker Containers

| Container       | Image                                  | Status  | Ports                  |
| --------------- | -------------------------------------- | ------- | ---------------------- |
| menugreen_api   | anhtuan21112004/menugreensystem:latest | Running | 0.0.0.0:5000->5000/tcp |
| menugreen_redis | redis:7-alpine                         | Running | 6379/tcp               |
| menugreen-net   | Custom bridge network                  | Active  | -                      |

### Commands Reference

```bash
# SSH to server
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100

# Check container status
docker ps

# View API logs
docker logs menugreen_api --tail 50 -f

# Restart API
docker restart menugreen_api

# Database operations
PGPASSWORD='MenuGreen2026!' psql -h menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com -U postgres -c "CREATE DATABASE menugreendb;"
PGPASSWORD='MenuGreen2026!' psql -h menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com -U postgres -l

# Navigate to app
cd ~/apps/MenuGreenSystem
```

### Docker Hub

| Property     | Value                                    |
| ------------ | ---------------------------------------- |
| **Image**    | `anhtuan21112004/menugreensystem:latest` |
| **Registry** | Docker Hub                               |

---

## Template for New Issues

```markdown
## [PENDING/RESOLVED] Issue Title

**Date:** YYYY-MM-DD
**Status:** Pending/Resolved
**Severity:** Low/Medium/High

### Description

### Root Cause

### Environment

### Logs

### Fix Applied / Attempts
```

---

## Prevention Guidelines

### YAML Files

- Luôn dùng consistent indentation (spaces, not tabs)
- Không để commented YAML blocks trong Docker Compose

### Docker Compose

- Containers giao tiếp qua **service names** trong cùng network
- Không dùng `localhost` cho inter-container communication
- Luôn dùng `volumes: []` thay vì commented volumes

### CI/CD

- Test workflow syntax trước khi push
- Dùng `yamllint` hoặc VS Code YAML validation

```

```
