# CI/CD Pipeline Guide - MenuGreen System

**Last updated:** 2026-07-09

---

## Overview

MenuGreen sử dụng GitHub Actions để tự động hóa CI/CD pipeline:
- Build & Test .NET
- Build Docker image
- Deploy lên AWS Lightsail

---

## Pipeline Flow

```
Git Push → GitHub Actions → Docker Hub → Server Deploy
                                              │
                                              ▼
                                    ┌─────────────────┐
                                    │ 1. SSH to Server│
                                    │ 2. Pull .env    │
                                    │    from Doppler │
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ 3. Backup DB    │ ← pg_dump
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ 4. Pull Image   │
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ 5. EF Migration │
                                    └────────┬────────┘
                                             │
                                             ▼
                                    ┌─────────────────┐
                                    │ 6. Health Check │
                                    └─────────────────┘
```

---

## GitHub Secrets

### Required

| Secret | Description | Example |
|--------|-------------|---------|
| `DOPPLER_TOKEN` | Doppler production config token | `dp.prd.xxx` |
| `LIGHTSAIL_HOST` | Server IP | `52.77.218.100` |
| `LIGHTSAIL_USER` | SSH user | `ubuntu` |
| `LIGHTSAIL_SSH_KEY` | SSH private key | `-----BEGIN...` |

### Optional

| Secret | Description |
|--------|-------------|
| `DOCKERHUB_USERNAME` | `anhtuan21112004` |
| `DOCKERHUB_TOKEN` | Docker Hub access token |

### Setup Guide

See: [GITHUB_SECRETS_SETUP.md](./GITHUB_SECRETS_SETUP.md)

---

## Server Information

| Property | Value |
|----------|-------|
| **SSH** | `ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100` |
| **App Location** | `~/apps/MenuGreenSystem` |
| **Docker Image** | `anhtuan21112004/menugreensystem:latest` |
| **API Port** | 5000 |
| **OS** | Ubuntu 22.04 LTS |

---

## Deployment Commands

```bash
# SSH to server
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100

# Check container status
docker ps

# View API logs
docker logs menugreen_api --tail 50 -f

# Restart API
docker restart menugreen_api

# Pull latest image manually
docker pull anhtuan21112004/menugreensystem:latest
docker compose -f docker-compose.prod.yml up -d api

# Database backup
pg_dump -h menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com \
  -U postgres -d menugreendb -F p -f backup.sql

# Navigate to app
cd ~/apps/MenuGreenSystem
```

---

## Database Migration

### Automatic (via CI/CD)

CI/CD pipeline tự động chạy migration khi deploy:
1. Backup database với `pg_dump`
2. Run `dotnet ef database update`
3. Nếu fail → rollback, không start API

### Manual

```bash
# SSH vào server
ssh -i ~/LightsailDefaultKeyPair.pem ubuntu@52.77.218.100

# Backup trước
pg_dump -h menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com \
  -U postgres -d menugreendb -F p -f backup_$(date +%Y%m%d_%H%M%S).sql

# Run migration
docker exec menugreen_api dotnet ef database update \
  --project backend/MenuGreen.DataAccessLayer/MenuGreen.DataAccessLayer.csproj \
  --startup-project backend/MenuGreen.API/MenuGreen.API.csproj
```

---

## Health Check

### Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Full health check (DB + Redis) |
| `GET /health/ready` | Readiness check |
| `GET /health/live` | Liveness check |

### Test

```bash
curl https://api.menugreen.food/health
```

---

## Rollback Plan

### If Migration Fail

1. SSH vào server
2. Restore từ backup:
   ```bash
   psql -h menugreen-db.cr4uo6sksium.ap-southeast-1.rds.amazonaws.com \
     -U postgres -d menugreendb < backup.sql
   ```
3. Pull image version cũ
4. Không start API cho đến khi fix xong

### If Deployment Fail

1. SSH vào server
2. Stop current: `docker compose -f docker-compose.prod.yml down`
3. Pull image cũ: `docker pull docker.io/anhtuan21112004/menugreensystem:<previous-tag>`
4. Start: `docker compose -f docker-compose.prod.yml up -d`
5. Verify health check

---

## Docker Compose Production

```bash
# Build & Start
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose -f docker-compose.prod.yml logs -f

# Stop
docker-compose -f docker-compose.prod.yml down
```

---

## Nginx Configuration (Snippets Approach)

Tách config thành các snippets để tái sử dụng và dễ maintain.

### Folder Structure

```
/etc/nginx/
├── snippets/
│   ├── proxy-params.conf      ← Proxy settings
│   └── cors-headers.conf      ← CORS headers
├── sites-available/
│   └── api.menugreen.food     ← API config
└── sites-enabled/
    └── api.menugreen.food     ← Symlink
```

### Step 1: Create snippets folder

```bash
sudo mkdir -p /etc/nginx/snippets
```

### Step 2: Create proxy-params.conf

```bash
sudo nano /etc/nginx/snippets/proxy-params.conf
```

```nginx
# Proxy parameters - tái sử dụng cho tất cả backend services

proxy_http_version 1.1;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header Connection "";

# Timeouts
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;

# Buffers
proxy_buffering on;
proxy_buffer_size 4k;
proxy_buffers 4 4k;
```

### Step 3: Create cors-headers.conf

```bash
sudo nano /etc/nginx/snippets/cors-headers.conf
```

```nginx
# CORS Headers - tái sử dụng

# Preflight OPTIONS
if ($request_method = 'OPTIONS') {
    add_header 'Access-Control-Allow-Origin' 'https://www.menugreen.food' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, Accept, Origin, X-Requested-With' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    add_header 'Access-Control-Max-Age' 86400 always;
    add_header 'Content-Type' 'text/plain; charset=utf-8';
    add_header 'Content-Length' 0;
    return 204;
}

# Normal responses
add_header 'Access-Control-Allow-Origin' 'https://www.menugreen.food' always;
add_header 'Access-Control-Allow-Credentials' 'true' always;
add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS, PATCH' always;
add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, Accept, Origin, X-Requested-With' always;
```

### Step 4: Update API config

```bash
sudo nano /etc/nginx/sites-available/api.menugreen.food
```

```nginx
server {
    listen 443 ssl http2;
    server_name api.menugreen.food;

    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/api.menugreen.food/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.menugreen.food/privkey.pem;

    # SSL optimization
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        # Include CORS headers
        include snippets/cors-headers.conf;

        # Proxy to backend
        proxy_pass http://localhost:5000;
        include snippets/proxy-params.conf;
    }
}
```

### Step 5: Reload Nginx

```bash
# Test config
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Verify
curl -I https://api.menugreen.food/health
```

### Verification Result

```
HTTP/2 200
access-control-allow-origin: https://www.menugreen.food
access-control-allow-credentials: true
access-control-allow-methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
access-control-allow-headers: Content-Type, Authorization, Accept, Origin, X-Requested-With
```

### Monitoring Logs

```bash
# Access log
sudo tail -20 /var/log/nginx/access.log

# Error log
sudo tail -20 /var/log/nginx/error.log

# Real-time monitoring
sudo tail -f /var/log/nginx/access.log
```

---

## Troubleshooting

### Build Failures

```bash
# Check network connectivity
curl -s https://api.nuget.org/v3/index.json | head

# Clear NuGet cache
dotnet nuget locals all --clear
```

### Deployment Failures

```bash
# Check logs
docker logs menugreen_api

# Check environment variables
docker exec menugreen_api env | sort

# Check port availability
netstat -tlnp | grep 5000
```

### CORS Issues

```bash
# Test preflight
curl -I -X OPTIONS https://api.menugreen.food/api/Auth/login \
  -H "Origin: https://www.menugreen.food" \
  -H "Access-Control-Request-Method: POST"

# Verify CORS headers
curl -I https://api.menugreen.food/health
```

---

## Monitoring Stack (Future)

See: [monitoring/uptimerobot-setup.md](./monitoring/uptimerobot-setup.md)

Planned:
- Prometheus metrics: `/metrics`
- Grafana dashboards
- UptimeRobot alerts

---

## Related Documents

| Document | Description |
|----------|-------------|
| [GITHUB_SECRETS_SETUP.md](./GITHUB_SECRETS_SETUP.md) | GitHub secrets setup guide |
| [lightsail-setup.md](./lightsail-setup.md) | Server setup guide |
| [issues.md](./issues.md) | Issue tracker |

---

*Last updated: 2026-07-05*
